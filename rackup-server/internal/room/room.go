package room

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"sync"
	"time"

	"github.com/ducdo/rackup-server/internal/protocol"
)

const (
	// MaxPlayers is the maximum number of players per room (FR7).
	MaxPlayers = 8
	// ReconnectWindow is the per-player reconnection hold window.
	ReconnectWindow = 60 * time.Second
	// RoomTimeout is the room-level timeout when all players disconnect.
	RoomTimeout = 5 * time.Minute
	// actionChannelSize is the buffer size for the room action channel.
	actionChannelSize = 64
)

// Action represents a message sent to the room goroutine for processing.
type Action struct {
	Type    string
	Player  string
	Payload json.RawMessage
}

// Room represents an active game room.
type Room struct {
	mu             sync.RWMutex
	code           string
	hostDeviceHash string
	players        map[string]*PlayerConn
	disconnected   map[string]time.Time // per-player reconnection hold
	createdAt      time.Time
	actions        chan Action
	cancel         context.CancelFunc
	manager        *RoomManager // back-reference for self-cleanup
}

// NewRoom creates a new Room. The cancel func is used to stop the room goroutine.
func NewRoom(code, hostDeviceHash string, cancel context.CancelFunc, manager *RoomManager) *Room {
	return &Room{
		code:           code,
		hostDeviceHash: hostDeviceHash,
		players:        make(map[string]*PlayerConn),
		disconnected:   make(map[string]time.Time),
		createdAt:      time.Now(),
		actions:        make(chan Action, actionChannelSize),
		cancel:         cancel,
		manager:        manager,
	}
}

// Code returns the room's code.
func (r *Room) Code() string {
	return r.code
}

// Run is the room's main goroutine loop. It processes actions and handles
// context cancellation for cleanup.
func (r *Room) Run(ctx context.Context) {
	slog.Info("room goroutine started", "code", r.code)
	defer slog.Info("room goroutine stopped", "code", r.code)

	emptyTimer := time.NewTimer(RoomTimeout)
	emptyTimer.Stop()

	reconnectTicker := time.NewTicker(5 * time.Second)
	defer reconnectTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			r.disconnectAll()
			return
		case action := <-r.actions:
			slog.Debug("room action received", "code", r.code, "type", action.Type, "player", action.Player)
			// Future stories will handle game actions here.
			_ = action
		case <-emptyTimer.C:
			slog.Info("room timeout - all players disconnected", "code", r.code)
			// Self-cleanup: remove from manager registry.
			if r.manager != nil {
				r.manager.CleanupRoom(r.code)
			} else {
				r.cancel()
			}
			return
		case <-reconnectTicker.C:
			r.expireDisconnectedPlayers()
		}
	}
}

// expireDisconnectedPlayers removes players whose reconnection window has expired.
func (r *Room) expireDisconnectedPlayers() {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	for deviceHash, disconnectTime := range r.disconnected {
		if now.Sub(disconnectTime) >= ReconnectWindow {
			delete(r.disconnected, deviceHash)
			delete(r.players, deviceHash)
			slog.Info("player reconnection window expired", "code", r.code, "device", deviceHash)
		}
	}
}

// AddPlayer adds a player connection to the room.
// Returns an error if the room is full.
func (r *Room) AddPlayer(deviceIDHash string, conn *PlayerConn) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Allow reconnection — close old connection and replace.
	if old, exists := r.players[deviceIDHash]; exists {
		slog.Info("player reconnected", "code", r.code, "device", deviceIDHash)
		old.Close()
		r.players[deviceIDHash] = conn
		delete(r.disconnected, deviceIDHash)
		return nil
	}

	// Check if player has a reconnection hold slot.
	if _, held := r.disconnected[deviceIDHash]; held {
		r.players[deviceIDHash] = conn
		delete(r.disconnected, deviceIDHash)
		slog.Info("player reconnected from hold", "code", r.code, "device", deviceIDHash)
		return nil
	}

	if len(r.players) >= MaxPlayers {
		return ErrRoomFull
	}

	r.players[deviceIDHash] = conn
	slog.Info("player joined", "code", r.code, "device", deviceIDHash, "count", len(r.players))
	return nil
}

// RemovePlayer marks a player as disconnected with a reconnection hold window.
// The player slot is held for ReconnectWindow before being fully removed.
func (r *Room) RemovePlayer(deviceIDHash string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.players, deviceIDHash)
	r.disconnected[deviceIDHash] = time.Now()
	slog.Info("player disconnected, holding slot", "code", r.code, "device", deviceIDHash, "count", len(r.players))

	// If no connected players remain, start the empty-room timer via action channel.
	if len(r.players) == 0 {
		r.notifyEmpty()
	}
}

// notifyEmpty sends an internal action to trigger the empty-room timer.
// Must be called with r.mu held.
func (r *Room) notifyEmpty() {
	select {
	case r.actions <- Action{Type: "internal.check_empty"}:
	default:
	}
}

// PlayerCount returns the number of connected players.
func (r *Room) PlayerCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.players)
}

// BroadcastMessage sends a protocol message to all connected players.
// Routes through the outbound channel to avoid concurrent writes.
func (r *Room) BroadcastMessage(msg protocol.Message) {
	data, err := json.Marshal(msg)
	if err != nil {
		slog.Error("failed to marshal broadcast message", "code", r.code, "error", err)
		return
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for deviceHash, conn := range r.players {
		if err := conn.WriteMessage(data); err != nil {
			slog.Warn("failed to send message to player", "code", r.code, "device", deviceHash, "error", err)
		}
	}
}

// SendAction sends an action to the room's action channel for processing.
func (r *Room) SendAction(action Action) {
	select {
	case r.actions <- action:
	default:
		slog.Warn("room action channel full, dropping message", "code", r.code)
	}
}

func (r *Room) disconnectAll() {
	r.mu.Lock()
	defer r.mu.Unlock()

	for deviceHash, conn := range r.players {
		conn.Close()
		delete(r.players, deviceHash)
	}
}

// ErrRoomFull is returned when a room has reached MaxPlayers.
var ErrRoomFull = &RoomFullError{}

// RoomFullError indicates a room is at capacity.
type RoomFullError struct{}

func (e *RoomFullError) Error() string {
	return "room is full"
}

// ErrOutboundFull is returned when a player's outbound channel is full.
var ErrOutboundFull = errors.New("player outbound channel full")
