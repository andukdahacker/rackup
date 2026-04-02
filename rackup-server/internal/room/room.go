package room

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"strings"
	"sync"
	"time"

	"github.com/ducdo/rackup-server/internal/game"
	"github.com/ducdo/rackup-server/internal/protocol"
)

// validPlayerStatuses is the allowlist of accepted player status strings.
var validPlayerStatuses = map[string]bool{
	"joining": true,
	"writing": true,
	"ready":   true,
}

const (
	// MaxPlayers is the maximum number of players per room (FR7).
	MaxPlayers = 8
	// ReconnectWindow is the per-player reconnection hold window.
	ReconnectWindow = 60 * time.Second
	// RoomTimeout is the room-level timeout when all players disconnect.
	RoomTimeout = 5 * time.Minute
	// PunishmentTimeout is the duration after which the game can start even if
	// not all players have submitted punishments.
	PunishmentTimeout = 120 * time.Second
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
	mu                       sync.RWMutex
	code                     string
	hostDeviceHash           string
	players                  map[string]*PlayerConn
	disconnected             map[string]time.Time // per-player reconnection hold
	slotAssignments          map[string]int       // persistent slot assignments (survives disconnect)
	punishments              map[string]string     // deviceIdHash → punishment text
	playerStatuses           map[string]string     // deviceIdHash → status string (default "joining")
	punishmentPhaseStartedAt time.Time             // set when first player joins; used by Story 2.3
	roundCount               int                   // configured round count (5, 10, or 15)
	gameStarted              bool                  // prevents double-start
	gameState                *game.GameState       // active game session state
	timeoutBroadcast         bool                  // ensures timeout room_state broadcast fires once
	createdAt                time.Time
	actions                  chan Action
	cancel                   context.CancelFunc
	manager                  *RoomManager // back-reference for self-cleanup
}

// NewRoom creates a new Room. The cancel func is used to stop the room goroutine.
func NewRoom(code, hostDeviceHash string, cancel context.CancelFunc, manager *RoomManager) *Room {
	return &Room{
		code:                     code,
		hostDeviceHash:           hostDeviceHash,
		players:                  make(map[string]*PlayerConn),
		disconnected:             make(map[string]time.Time),
		slotAssignments:          make(map[string]int),
		punishments:              make(map[string]string),
		playerStatuses:           make(map[string]string),
		createdAt: time.Now(),
		actions:                  make(chan Action, actionChannelSize),
		cancel:                   cancel,
		manager:                  manager,
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
			switch action.Type {
			case "client_message":
				r.handleClientMessage(action.Player, action.Payload)
			case "internal.check_empty":
				// handled by emptyTimer logic below
			}
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
			r.checkPunishmentTimeout()
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
			delete(r.punishments, deviceHash)
			delete(r.playerStatuses, deviceHash)
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

	// Start punishment phase timer when the second player joins.
	if len(r.players) == 2 && r.punishmentPhaseStartedAt.IsZero() {
		r.punishmentPhaseStartedAt = time.Now()
	}

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
		status := r.playerStatuses[deviceHash]
		if status == "" {
			status = "joining"
		}
		players = append(players, protocol.LobbyPlayerPayload{
			DisplayName:  conn.DisplayName(),
			DeviceIDHash: deviceHash,
			Slot:         slot,
			IsHost:       isHost,
			Status:       status,
		})
	}

	allSubmitted := len(r.punishments) >= len(r.players) && len(r.players) > 0
	timedOut := !r.punishmentPhaseStartedAt.IsZero() && time.Since(r.punishmentPhaseStartedAt) >= PunishmentTimeout

	payload, err := json.Marshal(protocol.LobbyRoomStatePayload{
		RoomCode:           r.code,
		HostDeviceIDHash:   r.hostDeviceHash,
		Players:            players,
		AllReadyOrTimedOut: allSubmitted || timedOut,
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

	status := r.playerStatuses[deviceIDHash]
	if status == "" {
		status = "joining"
	}

	payload, err := json.Marshal(protocol.LobbyPlayerPayload{
		DisplayName:  conn.DisplayName(),
		DeviceIDHash: conn.DeviceHash(),
		Slot:         slot,
		IsHost:       isHost,
		Status:       status,
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

// handleClientMessage routes incoming client messages by action.
func (r *Room) handleClientMessage(deviceHash string, raw json.RawMessage) {
	var msg protocol.Message
	if err := json.Unmarshal(raw, &msg); err != nil {
		slog.Warn("failed to parse client message", "code", r.code, "device", deviceHash, "error", err)
		return
	}

	switch msg.Action {
	case protocol.ActionLobbyPunishmentSubmitted:
		var payload protocol.PunishmentSubmitPayload
		if err := json.Unmarshal(msg.Payload, &payload); err != nil {
			slog.Warn("failed to parse punishment payload", "code", r.code, "error", err)
			return
		}

		// Validate text is non-empty after trimming.
		trimmed := strings.TrimSpace(payload.Text)
		if trimmed == "" {
			r.sendErrorToPlayer(deviceHash, "PUNISHMENT_EMPTY", "Punishment text must not be empty")
			return
		}

		// Validate text length.
		if len([]rune(trimmed)) > 140 {
			r.sendErrorToPlayer(deviceHash, "PUNISHMENT_TOO_LONG", "Punishment text must be 140 characters or fewer")
			return
		}

		r.mu.Lock()
		r.punishments[deviceHash] = trimmed
		r.playerStatuses[deviceHash] = "ready"
		r.mu.Unlock()

		// Broadcast status change to all players.
		r.broadcastPlayerStatus(deviceHash, "ready")

	case protocol.ActionLobbyPlayerStatusChanged:
		var payload protocol.PlayerStatusChangedPayload
		if err := json.Unmarshal(msg.Payload, &payload); err != nil {
			slog.Warn("failed to parse status change payload", "code", r.code, "error", err)
			return
		}

		// Validate status against allowlist.
		if !validPlayerStatuses[payload.Status] {
			slog.Warn("rejected invalid player status", "code", r.code, "device", deviceHash, "status", payload.Status)
			return
		}

		r.mu.Lock()
		r.playerStatuses[deviceHash] = payload.Status
		r.mu.Unlock()

		r.broadcastPlayerStatus(deviceHash, payload.Status)

	case protocol.ActionLobbyStartGame:
		r.handleStartGame(deviceHash, msg.Payload)

	default:
		if strings.HasPrefix(msg.Action, "game.") || strings.HasPrefix(msg.Action, "referee.") {
			r.handleGameAction(deviceHash, msg.Action, msg.Payload)
			return
		}
		slog.Debug("unhandled client action", "code", r.code, "action", msg.Action)
	}
}

// checkPunishmentTimeout broadcasts a fresh room state when the punishment
// timeout elapses, so clients receive the updated allReadyOrTimedOut flag.
func (r *Room) checkPunishmentTimeout() {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.gameStarted || r.timeoutBroadcast || r.punishmentPhaseStartedAt.IsZero() {
		return
	}
	if time.Since(r.punishmentPhaseStartedAt) >= PunishmentTimeout {
		r.timeoutBroadcast = true
		msg, err := r.buildRoomStateLocked()
		if err != nil {
			slog.Error("failed to build room state for timeout broadcast", "code", r.code, "error", err)
			return
		}
		r.broadcastLocked(msg)
		slog.Info("punishment timeout elapsed, broadcast room state", "code", r.code)
	}
}

// handleStartGame processes the lobby.start_game action.
func (r *Room) handleStartGame(deviceHash string, raw json.RawMessage) {
	var payload protocol.StartGamePayload
	if err := json.Unmarshal(raw, &payload); err != nil {
		slog.Warn("failed to parse start game payload", "code", r.code, "error", err)
		return
	}

	r.mu.Lock()

	// Only host can start.
	if deviceHash != r.hostDeviceHash {
		r.mu.Unlock()
		r.sendErrorToPlayer(deviceHash, "NOT_HOST", "Only the host can start the game")
		return
	}

	// Minimum 2 players.
	if len(r.players) < 2 {
		r.mu.Unlock()
		r.sendErrorToPlayer(deviceHash, "NOT_ENOUGH_PLAYERS", "At least 2 players are required to start")
		return
	}

	// Valid round count.
	if payload.RoundCount != 5 && payload.RoundCount != 10 && payload.RoundCount != 15 {
		r.mu.Unlock()
		r.sendErrorToPlayer(deviceHash, "INVALID_ROUND_COUNT", "Round count must be 5, 10, or 15")
		return
	}

	// Punishments ready or timeout elapsed.
	allSubmitted := len(r.punishments) >= len(r.players) && len(r.players) > 0
	timedOut := !r.punishmentPhaseStartedAt.IsZero() && time.Since(r.punishmentPhaseStartedAt) >= PunishmentTimeout
	if !allSubmitted && !timedOut {
		r.mu.Unlock()
		r.sendErrorToPlayer(deviceHash, "PUNISHMENTS_PENDING", "Not all players have submitted punishments")
		return
	}

	// Prevent double-start.
	if r.gameStarted {
		r.mu.Unlock()
		r.sendErrorToPlayer(deviceHash, "GAME_ALREADY_STARTED", "Game has already started")
		return
	}

	// Broadcast game started to all players.
	startedPayload, err := json.Marshal(protocol.GameStartedPayload{
		RoundCount: payload.RoundCount,
	})
	if err != nil {
		r.mu.Unlock()
		slog.Error("failed to marshal game started payload", "code", r.code, "error", err)
		return
	}

	r.roundCount = payload.RoundCount
	r.gameStarted = true
	r.broadcastLocked(protocol.Message{
		Action:  protocol.ActionLobbyGameStarted,
		Payload: startedPayload,
	})

	// Initialize game state.
	playerNames := make(map[string]string, len(r.players))
	for dh, pc := range r.players {
		playerNames[dh] = pc.DisplayName()
	}
	r.gameState = game.NewGameState(playerNames, r.slotAssignments, r.roundCount, r.hostDeviceHash)

	// Build and broadcast game.initialized payload.
	gamePlayers := make([]protocol.GamePlayerPayload, 0, len(r.gameState.Players))
	for _, dh := range r.gameState.TurnOrder {
		gp := r.gameState.Players[dh]
		gamePlayers = append(gamePlayers, protocol.GamePlayerPayload{
			DeviceIDHash: gp.DeviceIDHash,
			DisplayName:  gp.DisplayName,
			Slot:         gp.Slot,
			Score:        gp.Score,
			Streak:       gp.Streak,
			IsReferee:    gp.IsReferee,
		})
	}
	gameInitPayload, err := json.Marshal(protocol.GameInitializedPayload{
		RoundCount:                 r.roundCount,
		RefereeDeviceIDHash:        r.gameState.RefereeDeviceIDHash,
		TurnOrder:                  r.gameState.TurnOrder,
		CurrentShooterDeviceIDHash: r.gameState.CurrentShooterDeviceIDHash(),
		Players:                    gamePlayers,
	})
	if err != nil {
		slog.Error("failed to marshal game initialized payload", "code", r.code, "error", err)
		r.mu.Unlock()
		return
	}
	r.broadcastLocked(protocol.Message{
		Action:  protocol.ActionGameInitialized,
		Payload: gameInitPayload,
	})
	r.mu.Unlock()
}

// handleGameAction routes game/referee-namespaced actions.
// Referee actions (confirm_shot, undo_shot) acquire a write lock because they mutate GameState.
func (r *Room) handleGameAction(deviceHash, action string, payload json.RawMessage) {
	// Referee-namespaced actions need write lock for mutations.
	if strings.HasPrefix(action, "referee.") {
		r.mu.Lock()

		if r.gameState == nil {
			r.mu.Unlock()
			r.sendErrorToPlayer(deviceHash, "GAME_NOT_STARTED", "Game has not started")
			return
		}

		if !r.gameState.IsReferee(deviceHash) {
			r.mu.Unlock()
			r.sendErrorToPlayer(deviceHash, "NOT_REFEREE", "Only the referee can perform this action")
			return
		}

		switch action {
		case protocol.ActionRefereeConfirmShot:
			r.handleConfirmShotLocked(deviceHash, payload)
		case protocol.ActionRefereeUndoShot:
			r.handleUndoShotLocked(deviceHash)
		default:
			slog.Debug("unhandled referee action", "code", r.code, "action", action)
		}

		r.mu.Unlock()
		return
	}

	// Non-referee game actions (read-only).
	r.mu.RLock()
	gs := r.gameState
	r.mu.RUnlock()

	if gs == nil {
		r.sendErrorToPlayer(deviceHash, "GAME_NOT_STARTED", "Game has not started")
		return
	}

	slog.Debug("game action received", "code", r.code, "action", action, "device", deviceHash)
}

// handleConfirmShotLocked processes referee.confirm_shot. Must be called with r.mu held (write lock).
func (r *Room) handleConfirmShotLocked(deviceHash string, payload json.RawMessage) {
	var shotPayload protocol.ConfirmShotPayload
	if err := json.Unmarshal(payload, &shotPayload); err != nil {
		slog.Warn("failed to parse confirm_shot payload", "code", r.code, "error", err)
		r.sendErrorToPlayerLocked(deviceHash, "INVALID_PAYLOAD", "Invalid confirm_shot payload")
		return
	}

	// Run consequence chain instead of direct ProcessShot.
	chain := game.NewConsequenceChain()
	chainCtx, err := chain.Run(r.gameState, r.gameState.CurrentShooterDeviceIDHash(), shotPayload.Result)
	if err != nil {
		slog.Warn("ConsequenceChain failed", "code", r.code, "error", err)
		r.sendErrorToPlayerLocked(deviceHash, "SHOT_FAILED", err.Error())
		return
	}

	result := chainCtx.TurnResult

	// Check game over.
	if result.IsGameOver {
		r.gameState.GamePhase = game.PhaseEnded
	}

	// Broadcast enriched turn_complete.
	r.broadcastTurnCompleteLocked(chainCtx)

	// If game over, also broadcast game_ended.
	if result.IsGameOver {
		endPayload, err := json.Marshal(map[string]bool{"gameOver": true})
		if err == nil {
			r.broadcastLocked(protocol.Message{
				Action:  protocol.ActionGameEnded,
				Payload: endPayload,
			})
		}
	}
}

// handleUndoShotLocked processes referee.undo_shot. Must be called with r.mu held (write lock).
func (r *Room) handleUndoShotLocked(deviceHash string) {
	// Block undo after game-ending shots — game_ended was already broadcast and cannot be retracted.
	if r.gameState.GamePhase == game.PhaseEnded {
		r.sendErrorToPlayerLocked(deviceHash, "UNDO_BLOCKED", "Cannot undo after game has ended")
		return
	}

	// Validate within 5-second undo window.
	if r.gameState.LastShotTime.IsZero() || time.Since(r.gameState.LastShotTime) > 5*time.Second {
		r.sendErrorToPlayerLocked(deviceHash, "UNDO_EXPIRED", "Undo window has expired")
		return
	}

	if err := r.gameState.UndoLastShot(); err != nil {
		slog.Warn("UndoLastShot failed", "code", r.code, "error", err)
		r.sendErrorToPlayerLocked(deviceHash, "UNDO_FAILED", err.Error())
		return
	}

	// Broadcast corrected state as turn_complete with recalculated leaderboard.
	shooter := r.gameState.CurrentShooterDeviceIDHash()
	player := r.gameState.Players[shooter]
	correctedCtx := &game.ChainContext{
		ShooterHash:    shooter,
		ShotResult:     "undo",
		TurnResult: &game.TurnResult{
			ShooterHash:     shooter,
			Result:          "undo",
			PointsAwarded:   0,
			NewScore:        player.Score,
			NewStreak:       player.Streak,
			NextShooterHash: shooter, // same shooter (turn reverted)
			CurrentRound:    r.gameState.CurrentRound,
			IsGameOver:      false,
			IsTriplePoints:  r.gameState.IsTriplePoints(),
		},
		StreakLabel:           game.StreakLabel(player.Streak),
		StreakMilestone:       false,
		TriplePointsActivated: false, // undo never triggers activation
		Leaderboard:           r.gameState.CalculateLeaderboard(nil),
		CascadeProfile:        "routine",
	}
	r.broadcastTurnCompleteLocked(correctedCtx)
}

// broadcastTurnCompleteLocked broadcasts a game.turn_complete message with enriched chain data.
// Must be called with r.mu held.
func (r *Room) broadcastTurnCompleteLocked(chainCtx *game.ChainContext) {
	result := chainCtx.TurnResult

	// Convert game.LeaderboardEntry to protocol.LeaderboardEntry.
	leaderboard := make([]protocol.LeaderboardEntry, len(chainCtx.Leaderboard))
	for i, entry := range chainCtx.Leaderboard {
		leaderboard[i] = protocol.LeaderboardEntry{
			DeviceIDHash: entry.DeviceIDHash,
			DisplayName:  entry.DisplayName,
			Score:        entry.Score,
			Streak:       entry.Streak,
			StreakLabel:   entry.StreakLabel,
			Rank:         entry.Rank,
			RankChanged:  entry.RankChanged,
		}
	}

	payload, err := json.Marshal(protocol.TurnCompletePayload{
		ShooterHash:           result.ShooterHash,
		Result:                result.Result,
		PointsAwarded:         result.PointsAwarded,
		NewScore:              result.NewScore,
		NewStreak:             result.NewStreak,
		CurrentShooterHash:    result.NextShooterHash,
		CurrentRound:          result.CurrentRound,
		IsGameOver:            result.IsGameOver,
		StreakLabel:            chainCtx.StreakLabel,
		StreakMilestone:        chainCtx.StreakMilestone,
		Leaderboard:           leaderboard,
		CascadeProfile:        chainCtx.CascadeProfile,
		IsTriplePoints:        result.IsTriplePoints,
		TriplePointsActivated: chainCtx.TriplePointsActivated,
	})
	if err != nil {
		slog.Error("failed to marshal turn_complete", "code", r.code, "error", err)
		return
	}
	r.broadcastLocked(protocol.Message{
		Action:  protocol.ActionGameTurnComplete,
		Payload: payload,
	})
}

// sendErrorToPlayerLocked sends an error message to a specific player.
// Must be called with r.mu held.
func (r *Room) sendErrorToPlayerLocked(deviceHash, code, message string) {
	payload, err := json.Marshal(protocol.ErrorPayload{
		Code:    code,
		Message: message,
	})
	if err != nil {
		return
	}
	data, err := json.Marshal(protocol.Message{
		Action:  protocol.ActionError,
		Payload: payload,
	})
	if err != nil {
		return
	}
	if conn, ok := r.players[deviceHash]; ok {
		if writeErr := conn.WriteMessage(data); writeErr != nil {
			slog.Warn("failed to send error to player", "code", r.code, "device", deviceHash, "error", writeErr)
		}
	}
}

// sendErrorToPlayer sends an error message to a specific player.
func (r *Room) sendErrorToPlayer(deviceHash, code, message string) {
	payload, err := json.Marshal(protocol.ErrorPayload{
		Code:    code,
		Message: message,
	})
	if err != nil {
		return
	}
	data, err := json.Marshal(protocol.Message{
		Action:  protocol.ActionError,
		Payload: payload,
	})
	if err != nil {
		return
	}

	r.mu.RLock()
	defer r.mu.RUnlock()
	if conn, ok := r.players[deviceHash]; ok {
		if writeErr := conn.WriteMessage(data); writeErr != nil {
			slog.Warn("failed to send error to player", "code", r.code, "device", deviceHash, "error", writeErr)
		}
	}
}

// broadcastPlayerStatus broadcasts a player status change to all connected players.
func (r *Room) broadcastPlayerStatus(deviceHash, status string) {
	payload, err := json.Marshal(protocol.PlayerStatusChangedPayload{
		DeviceIDHash: deviceHash,
		Status:       status,
	})
	if err != nil {
		slog.Error("failed to marshal status change", "code", r.code, "error", err)
		return
	}

	r.BroadcastMessage(protocol.Message{
		Action:  protocol.ActionLobbyPlayerStatusChanged,
		Payload: payload,
	})
}

// AllPunishmentsSubmitted returns true if every connected player has submitted a punishment.
func (r *Room) AllPunishmentsSubmitted() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.punishments) >= len(r.players) && len(r.players) > 0
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
