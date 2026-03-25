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
	pc := NewPlayerConn(conn, "player1")
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
		pc := NewPlayerConn(conn, "")
		hash := string(rune('A'+i)) + "hash"
		if err := r.AddPlayer(hash, pc); err != nil {
			t.Fatalf("AddPlayer failed at %d: %v", i, err)
		}
	}

	conn, _ := newWSPair(t)
	pc := NewPlayerConn(conn, "")
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
	pc1 := NewPlayerConn(conn1, "player1")
	if err := r.AddPlayer("player1", pc1); err != nil {
		t.Fatalf("AddPlayer failed: %v", err)
	}

	conn2, _ := newWSPair(t)
	pc2 := NewPlayerConn(conn2, "player1")
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
	pc := NewPlayerConn(conn, "player1")
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
		pc := NewPlayerConn(clientConn, string(rune('A'+i)))
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
