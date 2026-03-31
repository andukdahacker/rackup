package room

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/ducdo/rackup-server/internal/protocol"
	"nhooyr.io/websocket"
)

func newTestRoom(t *testing.T) (*Room, context.CancelFunc) {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	r := NewRoom("TEST", "host-hash", cancel, nil)
	go r.Run(ctx)
	return r, cancel
}

func TestAddPlayer(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	conn, _ := newWSPair(t)
	pc := NewPlayerConn(conn, "player1", "")
	if err := r.AddPlayer("player1", pc); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	if r.PlayerCount() != 1 {
		t.Errorf("expected 1 player, got %d", r.PlayerCount())
	}
}

func TestAddPlayer_MaxEnforcement(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	for i := 0; i < MaxPlayers; i++ {
		conn, _ := newWSPair(t)
		pc := NewPlayerConn(conn, "", "")
		hash := string(rune('A'+i)) + "hash"
		if err := r.AddPlayer(hash, pc); err != nil {
			t.Fatalf("AddPlayer failed at %d: %v", i, err)
		}
	}

	conn, _ := newWSPair(t)
	pc := NewPlayerConn(conn, "", "")
	err := r.AddPlayer("extra-player", pc)
	if err == nil {
		t.Fatal("expected ErrRoomFull")
	}
	if err != ErrRoomFull {
		t.Errorf("expected ErrRoomFull, got %v", err)
	}
}

func TestAddPlayer_Reconnection(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "player1", "")
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player1", "")
	if err := r.AddPlayer("player1", pc2); err != nil {
		t.Fatalf("AddPlayer reconnection failed: %v", err)
	}

	if r.PlayerCount() != 1 {
		t.Errorf("expected 1 player after reconnection, got %d", r.PlayerCount())
	}
}

func TestRemovePlayer(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	conn, _ := newWSPair(t)
	pc := NewPlayerConn(conn, "player1", "")
	if err := r.AddPlayer("player1", pc); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	r.RemovePlayer("player1")
	if r.PlayerCount() != 0 {
		t.Errorf("expected 0 players, got %d", r.PlayerCount())
	}
}

func TestBroadcastMessage(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	var serverConns []*websocket.Conn
	for i := 0; i < 3; i++ {
		clientConn, serverConn := newWSPair(t)
		pc := NewPlayerConn(clientConn, string(rune('A'+i)), "")
		go pc.WritePump(pumpCtx)
		r.mu.Lock()
		r.players[string(rune('A'+i))] = pc
		r.mu.Unlock()
		serverConns = append(serverConns, serverConn)
	}

	msg := protocol.Message{
		Action:  "test.broadcast",
		Payload: json.RawMessage(`{"hello":"world"}`),
	}
	r.BroadcastMessage(msg)

	for i, srv := range serverConns {
		ctx, ctxCancel := context.WithTimeout(context.Background(), 2*time.Second)
		_, data, err := srv.Read(ctx)
		ctxCancel()
		if err != nil {
			t.Errorf("server conn %d read error: %v", i, err)
			continue
		}

		var received protocol.Message
		if err := json.Unmarshal(data, &received); err != nil {
			t.Errorf("server conn %d unmarshal error: %v", i, err)
			continue
		}
		if received.Action != "test.broadcast" {
			t.Errorf("server conn %d expected action test.broadcast, got %q", i, received.Action)
		}
	}
}

func TestAddPlayer_BroadcastsPlayerJoined(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	// Add first player with write pump so it can receive broadcasts.
	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain the room_state sent to player1 on join (no self-join broadcast anymore).
	drainCtx, drainCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel()
	_, selfData, err := serverConn1.Read(drainCtx)
	if err != nil {
		t.Fatalf("failed to drain room_state: %v", err)
	}
	var selfMsg protocol.Message
	if err := json.Unmarshal(selfData, &selfMsg); err != nil {
		t.Fatalf("failed to unmarshal self room_state: %v", err)
	}
	if selfMsg.Action != protocol.ActionLobbyRoomState {
		t.Errorf("expected first message to be room_state, got %q", selfMsg.Action)
	}

	// Add second player — should trigger player_joined broadcast to player1.
	clientConn2, serverConn2 := newWSPair(t)
	pc2 := NewPlayerConn(clientConn2, "player2", "Bob")
	go pc2.WritePump(pumpCtx)
	if err := r.AddPlayer("player2", pc2); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Read the player_joined broadcast from player1's server connection.
	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()

	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read broadcast from player1: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal broadcast: %v", err)
	}

	if msg.Action != protocol.ActionLobbyPlayerJoined {
		t.Errorf("expected action %q, got %q", protocol.ActionLobbyPlayerJoined, msg.Action)
	}

	var payload protocol.LobbyPlayerPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to unmarshal payload: %v", err)
	}

	if payload.DisplayName != "Bob" {
		t.Errorf("expected displayName 'Bob', got %v", payload.DisplayName)
	}
	if payload.DeviceIDHash != "player2" {
		t.Errorf("expected deviceIdHash 'player2', got %v", payload.DeviceIDHash)
	}
	if payload.Slot != 2 {
		t.Errorf("expected slot 2, got %d", payload.Slot)
	}
	if payload.IsHost {
		t.Errorf("expected isHost false for non-host player")
	}
	if payload.Status != "joining" {
		t.Errorf("expected status 'joining', got %q", payload.Status)
	}

	// Verify player2 received room_state (not player_joined for itself).
	p2ReadCtx, p2ReadCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer p2ReadCancel()
	_, p2Data, err := serverConn2.Read(p2ReadCtx)
	if err != nil {
		t.Fatalf("failed to read room_state from player2: %v", err)
	}
	var p2Msg protocol.Message
	if err := json.Unmarshal(p2Data, &p2Msg); err != nil {
		t.Fatalf("failed to unmarshal player2 message: %v", err)
	}
	if p2Msg.Action != protocol.ActionLobbyRoomState {
		t.Errorf("expected player2 to receive room_state, got %q", p2Msg.Action)
	}
}

func TestSlotAssignment(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	// Add 3 players — each should get sequential slots.
	for i := 0; i < 3; i++ {
		conn, _ := newWSPair(t)
		hash := string(rune('A'+i)) + "hash"
		pc := NewPlayerConn(conn, hash, "Player"+string(rune('A'+i)))
		if err := r.AddPlayer(hash, pc); err != nil {
			t.Fatalf("AddPlayer %d failed: %v", i, err)
		}
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	if r.slotAssignments["Ahash"] != 1 {
		t.Errorf("expected slot 1 for Ahash, got %d", r.slotAssignments["Ahash"])
	}
	if r.slotAssignments["Bhash"] != 2 {
		t.Errorf("expected slot 2 for Bhash, got %d", r.slotAssignments["Bhash"])
	}
	if r.slotAssignments["Chash"] != 3 {
		t.Errorf("expected slot 3 for Chash, got %d", r.slotAssignments["Chash"])
	}
}

func TestSlotAssignment_PersistsAfterDisconnect(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "player1", "Alice")
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Disconnect player.
	r.RemovePlayer("player1")

	r.mu.RLock()
	slot := r.slotAssignments["player1"]
	r.mu.RUnlock()

	if slot != 1 {
		t.Errorf("expected slot 1 to persist after disconnect, got %d", slot)
	}

	// Reconnect — should keep same slot.
	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player1", "Alice")
	if err := r.AddPlayer("player1", pc2); err != nil {
		t.Fatalf("AddPlayer reconnect failed: %v", err)
	}

	r.mu.RLock()
	slotAfterReconnect := r.slotAssignments["player1"]
	r.mu.RUnlock()

	if slotAfterReconnect != 1 {
		t.Errorf("expected slot 1 after reconnect, got %d", slotAfterReconnect)
	}
}

func TestGetRoomState(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "host-hash", "Host")
	if err := r.AddPlayer("host-hash", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player2", "Bob")
	if err := r.AddPlayer("player2", pc2); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	msg, err := r.GetRoomState()
	if err != nil {
		t.Fatalf("GetRoomState failed: %v", err)
	}

	if msg.Action != protocol.ActionLobbyRoomState {
		t.Errorf("expected action %q, got %q", protocol.ActionLobbyRoomState, msg.Action)
	}

	var payload protocol.LobbyRoomStatePayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to unmarshal room state: %v", err)
	}

	if payload.RoomCode != "TEST" {
		t.Errorf("expected roomCode 'TEST', got %q", payload.RoomCode)
	}
	if payload.HostDeviceIDHash != "host-hash" {
		t.Errorf("expected hostDeviceIdHash 'host-hash', got %q", payload.HostDeviceIDHash)
	}
	if len(payload.Players) != 2 {
		t.Fatalf("expected 2 players, got %d", len(payload.Players))
	}

	// Check that host is marked correctly.
	hostFound := false
	for _, p := range payload.Players {
		if p.DeviceIDHash == "host-hash" {
			hostFound = true
			if !p.IsHost {
				t.Errorf("host player should have isHost=true")
			}
		} else if p.DeviceIDHash == "player2" {
			if p.IsHost {
				t.Errorf("non-host player should have isHost=false")
			}
		}
	}
	if !hostFound {
		t.Errorf("host player not found in room state")
	}
}

func TestRemovePlayer_BroadcastsPlayerLeft(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	// Add two players.
	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain room_state sent to player1 on join.
	drainCtx1, drainCancel1 := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel1()
	_, _, _ = serverConn1.Read(drainCtx1)

	clientConn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(clientConn2, "player2", "Bob")
	go pc2.WritePump(pumpCtx)
	if err := r.AddPlayer("player2", pc2); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain player_joined broadcast from player1's connection.
	drainCtx2, drainCancel2 := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel2()
	_, _, _ = serverConn1.Read(drainCtx2)

	// Remove player2 — should broadcast player_left to player1.
	r.RemovePlayer("player2")

	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()

	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read player_left broadcast: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	if msg.Action != protocol.ActionLobbyPlayerLeft {
		t.Errorf("expected action %q, got %q", protocol.ActionLobbyPlayerLeft, msg.Action)
	}

	var payload map[string]string
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to unmarshal payload: %v", err)
	}

	if payload["deviceIdHash"] != "player2" {
		t.Errorf("expected deviceIdHash 'player2', got %v", payload["deviceIdHash"])
	}
}

func TestSlotReuse_AfterExpiration(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	r := NewRoom("SLOT", "host-hash", cancel, nil)
	defer cancel()

	// Add player and assign slot 1.
	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "player1", "Alice")
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Disconnect and expire the player.
	r.RemovePlayer("player1")
	r.mu.Lock()
	r.disconnected["player1"] = time.Now().Add(-2 * ReconnectWindow) // force expiry
	r.mu.Unlock()
	r.expireDisconnectedPlayers()

	// Verify slot was reclaimed.
	r.mu.RLock()
	_, hasSlot := r.slotAssignments["player1"]
	r.mu.RUnlock()
	if hasSlot {
		t.Errorf("expected slot assignment to be reclaimed after expiry")
	}

	// New player should get slot 1 (reused).
	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player2", "Bob")
	if err := r.AddPlayer("player2", pc2); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	r.mu.RLock()
	slot := r.slotAssignments["player2"]
	r.mu.RUnlock()
	if slot != 1 {
		t.Errorf("expected reused slot 1, got %d", slot)
	}
}

func TestHandleClientMessage_PunishmentSubmission(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	// Add a player with write pump.
	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain room_state.
	drainCtx, drainCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel()
	_, _, _ = serverConn1.Read(drainCtx)

	// Send punishment submission via action channel.
	innerMsg, _ := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPunishmentSubmitted,
		Payload: json.RawMessage(`{"text":"Do a dance"}`),
	})
	r.SendAction(Action{
		Type:    "client_message",
		Player:  "player1",
		Payload: innerMsg,
	})

	// Read the broadcast status change.
	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()
	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read broadcast: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	if msg.Action != protocol.ActionLobbyPlayerStatusChanged {
		t.Errorf("expected action %q, got %q", protocol.ActionLobbyPlayerStatusChanged, msg.Action)
	}

	var payload protocol.PlayerStatusChangedPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to unmarshal payload: %v", err)
	}
	if payload.DeviceIDHash != "player1" {
		t.Errorf("expected deviceIdHash 'player1', got %q", payload.DeviceIDHash)
	}
	if payload.Status != "ready" {
		t.Errorf("expected status 'ready', got %q", payload.Status)
	}

	// Verify punishment stored.
	r.mu.RLock()
	text := r.punishments["player1"]
	r.mu.RUnlock()
	if text != "Do a dance" {
		t.Errorf("expected punishment 'Do a dance', got %q", text)
	}
}

func TestHandleClientMessage_StatusChange(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain room_state.
	drainCtx, drainCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel()
	_, _, _ = serverConn1.Read(drainCtx)

	innerMsg, _ := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPlayerStatusChanged,
		Payload: json.RawMessage(`{"deviceIdHash":"player1","status":"writing"}`),
	})
	r.SendAction(Action{
		Type:    "client_message",
		Player:  "player1",
		Payload: innerMsg,
	})

	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()
	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read broadcast: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if msg.Action != protocol.ActionLobbyPlayerStatusChanged {
		t.Errorf("expected action %q, got %q", protocol.ActionLobbyPlayerStatusChanged, msg.Action)
	}

	// Verify status stored.
	r.mu.RLock()
	status := r.playerStatuses["player1"]
	r.mu.RUnlock()
	if status != "writing" {
		t.Errorf("expected status 'writing', got %q", status)
	}
}

func TestAllPunishmentsSubmitted(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	r := NewRoom("TEST", "host", cancel, nil)
	defer cancel()

	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "player1", "Alice")
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player2", "Bob")
	if err := r.AddPlayer("player2", pc2); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	if r.AllPunishmentsSubmitted() {
		t.Error("expected false when no punishments submitted")
	}

	r.mu.Lock()
	r.punishments["player1"] = "test"
	r.mu.Unlock()

	if r.AllPunishmentsSubmitted() {
		t.Error("expected false when only one player submitted")
	}

	r.mu.Lock()
	r.punishments["player2"] = "test2"
	r.mu.Unlock()

	if !r.AllPunishmentsSubmitted() {
		t.Error("expected true when all players submitted")
	}
}

func TestHandleClientMessage_PunishmentTooLong(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain room_state.
	drainCtx, drainCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel()
	_, _, _ = serverConn1.Read(drainCtx)

	// Send punishment with text longer than 140 chars.
	longText := ""
	for i := 0; i < 150; i++ {
		longText += "A"
	}
	payloadJSON := `{"text":"` + longText + `"}`
	innerMsg, _ := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPunishmentSubmitted,
		Payload: json.RawMessage(payloadJSON),
	})
	r.SendAction(Action{
		Type:    "client_message",
		Player:  "player1",
		Payload: innerMsg,
	})

	// Should receive an error message.
	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()
	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read error message: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if msg.Action != protocol.ActionError {
		t.Errorf("expected action %q, got %q", protocol.ActionError, msg.Action)
	}

	var errPayload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &errPayload); err != nil {
		t.Fatalf("failed to unmarshal error payload: %v", err)
	}
	if errPayload.Code != "PUNISHMENT_TOO_LONG" {
		t.Errorf("expected error code PUNISHMENT_TOO_LONG, got %q", errPayload.Code)
	}

	// Verify punishment NOT stored.
	r.mu.RLock()
	_, exists := r.punishments["player1"]
	r.mu.RUnlock()
	if exists {
		t.Error("punishment should not be stored when text is too long")
	}
}

func TestRoomState_IncludesPlayerStatuses(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	r := NewRoom("TEST", "host-hash", cancel, nil)
	defer cancel()

	conn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(conn1, "host-hash", "Host")
	if err := r.AddPlayer("host-hash", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Set a custom status.
	r.mu.Lock()
	r.playerStatuses["host-hash"] = "writing"
	r.mu.Unlock()

	msg, err := r.GetRoomState()
	if err != nil {
		t.Fatalf("GetRoomState failed: %v", err)
	}

	var payload protocol.LobbyRoomStatePayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}

	if len(payload.Players) != 1 {
		t.Fatalf("expected 1 player, got %d", len(payload.Players))
	}
	if payload.Players[0].Status != "writing" {
		t.Errorf("expected status 'writing', got %q", payload.Players[0].Status)
	}
}

func TestHandleClientMessage_PunishmentEmpty(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	clientConn1, serverConn1 := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Drain room_state.
	drainCtx, drainCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer drainCancel()
	_, _, _ = serverConn1.Read(drainCtx)

	// Send whitespace-only punishment.
	innerMsg, _ := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPunishmentSubmitted,
		Payload: json.RawMessage(`{"text":"   "}`),
	})
	r.SendAction(Action{
		Type:    "client_message",
		Player:  "player1",
		Payload: innerMsg,
	})

	// Should receive error.
	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()
	_, data, err := serverConn1.Read(readCtx)
	if err != nil {
		t.Fatalf("failed to read error message: %v", err)
	}

	var msg protocol.Message
	if err := json.Unmarshal(data, &msg); err != nil {
		t.Fatalf("failed to unmarshal: %v", err)
	}
	if msg.Action != protocol.ActionError {
		t.Errorf("expected action %q, got %q", protocol.ActionError, msg.Action)
	}

	var errPayload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &errPayload); err != nil {
		t.Fatalf("failed to unmarshal error payload: %v", err)
	}
	if errPayload.Code != "PUNISHMENT_EMPTY" {
		t.Errorf("expected error code PUNISHMENT_EMPTY, got %q", errPayload.Code)
	}

	// Verify punishment NOT stored.
	r.mu.RLock()
	_, exists := r.punishments["player1"]
	r.mu.RUnlock()
	if exists {
		t.Error("punishment should not be stored when text is whitespace-only")
	}
}

func TestHandleClientMessage_InvalidStatusRejected(t *testing.T) {
	r, cancel := newTestRoom(t)
	defer cancel()

	pumpCtx, pumpCancel := context.WithCancel(context.Background())
	defer pumpCancel()

	clientConn1, _ := newWSPair(t)
	pc1 := NewPlayerConn(clientConn1, "player1", "Alice")
	go pc1.WritePump(pumpCtx)
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	// Send invalid status.
	innerMsg, _ := json.Marshal(protocol.Message{
		Action:  protocol.ActionLobbyPlayerStatusChanged,
		Payload: json.RawMessage(`{"deviceIdHash":"player1","status":"hacker"}`),
	})
	r.SendAction(Action{
		Type:    "client_message",
		Player:  "player1",
		Payload: innerMsg,
	})

	// Wait for action to be processed.
	time.Sleep(100 * time.Millisecond)

	// Verify status NOT stored.
	r.mu.RLock()
	status := r.playerStatuses["player1"]
	r.mu.RUnlock()
	if status == "hacker" {
		t.Error("invalid status should not be stored")
	}
}

func TestExpireDisconnectedPlayers_CleansPunishments(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	r := NewRoom("TEST", "host", cancel, nil)
	defer cancel()

	// Directly set up maps to simulate a player who disconnected with state.
	r.mu.Lock()
	r.punishments["player1"] = "test punishment"
	r.playerStatuses["player1"] = "ready"
	r.slotAssignments["player1"] = 1
	r.disconnected["player1"] = time.Now().Add(-2 * ReconnectWindow)
	r.mu.Unlock()

	r.expireDisconnectedPlayers()

	// Verify all state cleaned up.
	r.mu.RLock()
	_, hasPunishment := r.punishments["player1"]
	_, hasStatus := r.playerStatuses["player1"]
	_, hasSlot := r.slotAssignments["player1"]
	r.mu.RUnlock()
	if hasPunishment {
		t.Error("punishment should be cleaned up after player expiration")
	}
	if hasStatus {
		t.Error("player status should be cleaned up after player expiration")
	}
	if hasSlot {
		t.Error("slot should be cleaned up after player expiration")
	}
}

func TestRoomCode(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	r := NewRoom("ABCD", "host", cancel, nil)
	defer cancel()

	if r.Code() != "ABCD" {
		t.Errorf("expected code ABCD, got %q", r.Code())
	}
}

func TestRoomGoroutineStopsOnCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	r := NewRoom("STOP", "host", cancel, nil)

	done := make(chan struct{})
	go func() {
		r.Run(ctx)
		close(done)
	}()

	cancel()

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("room goroutine did not stop after context cancel")
	}
}
