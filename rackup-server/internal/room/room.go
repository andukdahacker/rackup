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
	mu              sync.RWMutex
	code            string
	hostDeviceHash  string
	players         map[string]*PlayerConn
	disconnected    map[string]time.Time // per-player reconnection hold
	slotAssignments map[string]int // persistent slot assignments (survives disconnect)
	createdAt       time.Time
	actions         chan Action
	cancel          context.CancelFunc
	manager         *RoomManager // back-reference for self-cleanup
}

// NewRoom creates a new Room. The cancel func is used to stop the room goroutine.
func NewRoom(code, hostDeviceHash string, cancel context.CancelFunc, manager *RoomManager) *Room {
	return &Room{
		code:            code,
		hostDeviceHash:  hostDeviceHash,
		players:         make(map[string]*PlayerConn),
		disconnected:    make(map[string]time.Time),
		slotAssignments: make(map[string]int),
		createdAt:       time.Now(),
		actions:         make(chan Action, actionChannelSize),
		cancel:          cancel,
		manager:         manager,
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
			delete(r.slotAssignments, deviceHash)
			slog.Info("player reconnection window expired", "code", r.code, "device", deviceHash)
		}
	}
}

// AddPlayer adds a player connection to the room.
// Atomically sends room_state to the new player and broadcasts player_joined to others.
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
		r.sendRoomStateToPlayerLocked(conn)
		r.broadcastPlayerJoinedToOthersLocked(deviceIDHash, conn)
		return nil
	}

	// Check if player has a reconnection hold slot.
	if _, held := r.disconnected[deviceIDHash]; held {
		r.players[deviceIDHash] = conn
		delete(r.disconnected, deviceIDHash)
		slog.Info("player reconnected from hold", "code", r.code, "device", deviceIDHash)
		r.sendRoomStateToPlayerLocked(conn)
		r.broadcastPlayerJoinedToOthersLocked(deviceIDHash, conn)
		return nil
	}

	if len(r.players)+len(r.disconnected) >= MaxPlayers {
		return ErrRoomFull
	}

	// Assign slot — find lowest available (1-8).
	if _, hasSlot := r.slotAssignments[deviceIDHash]; !hasSlot {
		slot, err := r.findAvailableSlotLocked()
		if err != nil {
			return err
		}
		r.slotAssignments[deviceIDHash] = slot
	}

	r.players[deviceIDHash] = conn
	slog.Info("player joined", "code", r.code, "device", deviceIDHash, "count", len(r.players))

	// Send room state to the new player first (within lock, guarantees ordering).
	r.sendRoomStateToPlayerLocked(conn)
	// Then broadcast player_joined to other players only.
	r.broadcastPlayerJoinedToOthersLocked(deviceIDHash, conn)

	return nil
}

// findAvailableSlotLocked returns the lowest available slot (1-8).
// Must be called with r.mu held.
func (r *Room) findAvailableSlotLocked() (int, error) {
	used := make(map[int]bool, len(r.slotAssignments))
	for _, slot := range r.slotAssignments {
		used[slot] = true
	}
	for i := 1; i <= MaxPlayers; i++ {
		if !used[i] {
			return i, nil
		}
	}
	return 0, ErrRoomFull
}

// buildRoomStateLocked builds the room state message.
// Must be called with r.mu held.
func (r *Room) buildRoomStateLocked() (protocol.Message, error) {
	players := make([]protocol.LobbyPlayerPayload, 0, len(r.players))
	for deviceHash, conn := range r.players {
		slot := r.slotAssignments[deviceHash]
		isHost := deviceHash == r.hostDeviceHash
		players = append(players, protocol.LobbyPlayerPayload{
			DisplayName:  conn.DisplayName(),
			DeviceIDHash: deviceHash,
			Slot:         slot,
			IsHost:       isHost,
			Status:       "joining",
		})
	}

	payload, err := json.Marshal(protocol.LobbyRoomStatePayload{
		RoomCode:         r.code,
		HostDeviceIDHash: r.hostDeviceHash,
		Players:          players,
	})
	if err != nil {
		return protocol.Message{}, err
	}

	return protocol.Message{
		Action:  protocol.ActionLobbyRoomState,
		Payload: payload,
	}, nil
}

// sendRoomStateToPlayerLocked sends the current room state to a single player.
// Must be called with r.mu held.
func (r *Room) sendRoomStateToPlayerLocked(conn *PlayerConn) {
	msg, err := r.buildRoomStateLocked()
	if err != nil {
		slog.Error("failed to build room state", "code", r.code, "error", err)
		return
	}
	data, err := json.Marshal(msg)
	if err != nil {
		slog.Error("failed to marshal room state", "code", r.code, "error", err)
		return
	}
	if writeErr := conn.WriteMessage(data); writeErr != nil {
		slog.Warn("failed to send room state to player", "code", r.code, "error", writeErr)
	}
}

// broadcastPlayerJoinedToOthersLocked broadcasts lobby.player_joined to all
// connected players except the joining player.
// Must be called with r.mu held.
func (r *Room) broadcastPlayerJoinedToOthersLocked(deviceIDHash string, conn *PlayerConn) {
	slot := r.slotAssignments[deviceIDHash]
	isHost := deviceIDHash == r.hostDeviceHash

	payload, err := json.Marshal(protocol.LobbyPlayerPayload{
		DisplayName:  conn.DisplayName(),
		DeviceIDHash: conn.DeviceHash(),
		Slot:         slot,
		IsHost:       isHost,
		Status:       "joining",
	})
	if err != nil {
		slog.Error("failed to marshal player_joined payload", "code", r.code, "error", err)
		return
	}

	data, err := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPlayerJoined,
		Payload: payload,
	})
	if err != nil {
		slog.Error("failed to marshal player_joined message", "code", r.code, "error", err)
		return
	}

	for dh, pc := range r.players {
		if dh == deviceIDHash {
			continue
		}
		if writeErr := pc.WriteMessage(data); writeErr != nil {
			slog.Warn("failed to send player_joined", "code", r.code, "device", dh, "error", writeErr)
		}
	}
}

// RemovePlayer marks a player as disconnected with a reconnection hold window.
// The player slot is held for ReconnectWindow before being fully removed.
func (r *Room) RemovePlayer(deviceIDHash string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.players, deviceIDHash)
	r.disconnected[deviceIDHash] = time.Now()
	slog.Info("player disconnected, holding slot", "code", r.code, "device", deviceIDHash, "count", len(r.players))

	// Broadcast lobby.player_left to remaining connected players.
	payload, err := json.Marshal(map[string]string{
		"deviceIdHash": deviceIDHash,
	})
	if err == nil {
		r.broadcastLocked(protocol.Message{
			Action:  protocol.ActionLobbyPlayerLeft,
			Payload: payload,
		})
	}

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

// GetRoomState returns a lobby.room_state message with the full room snapshot.
func (r *Room) GetRoomState() (protocol.Message, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.buildRoomStateLocked()
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

// broadcastLocked sends a protocol message to all connected players.
// Must be called with r.mu already held (write or read lock).
func (r *Room) broadcastLocked(msg protocol.Message) {
	data, err := json.Marshal(msg)
	if err != nil {
		slog.Error("failed to marshal broadcast message", "code", r.code, "error", err)
		return
	}

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
