package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ducdo/rackup-server/internal/protocol"
	"github.com/ducdo/rackup-server/internal/room"
	"nhooyr.io/websocket"
)

var testSecret = []byte("test-secret-key-that-is-at-least-32-bytes-long!!")

func newWSPairForHandler(t *testing.T) (*websocket.Conn, *websocket.Conn) {
	t.Helper()

	var serverConn *websocket.Conn
	ready := make(chan struct{})

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		c, err := websocket.Accept(w, r, nil)
		if err != nil {
			return
		}
		serverConn = c
		close(ready)
		<-r.Context().Done()
	}))
	t.Cleanup(server.Close)

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http")
	clientConn, _, err := websocket.Dial(context.Background(), wsURL, nil)
	if err != nil {
		t.Fatalf("failed to dial: %v", err)
	}

	select {
	case <-ready:
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for server connection")
	}

	t.Cleanup(func() {
		clientConn.Close(websocket.StatusNormalClosure, "")
		serverConn.Close(websocket.StatusNormalClosure, "")
	})

	return clientConn, serverConn
}

func newTestHandler() *Handler {
	mgr := room.NewRoomManager()
	return New(nil, mgr, testSecret)
}

func TestHealth(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var resp healthResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Status != "ok" {
		t.Errorf("expected status 'ok', got %q", resp.Status)
	}
	if resp.Rooms != 0 {
		t.Errorf("expected rooms 0, got %d", resp.Rooms)
	}
	if resp.Connections != 0 {
		t.Errorf("expected connections 0, got %d", resp.Connections)
	}
	if resp.Uptime == "" {
		t.Error("expected non-empty uptime")
	}

	contentType := w.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("expected Content-Type application/json, got %q", contentType)
	}
}

func TestCreateRoom_Success(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"abc123hash"}`
	req := httptest.NewRequest(http.MethodPost, "/rooms", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected status 201, got %d; body: %s", w.Code, w.Body.String())
	}

	var resp createRoomResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if len(resp.RoomCode) != 4 {
		t.Errorf("expected 4-char room code, got %q", resp.RoomCode)
	}
	if resp.JWT == "" {
		t.Error("expected non-empty JWT")
	}

	// Cleanup
	h.manager.CleanupRoom(resp.RoomCode)
}

func TestCreateRoom_MissingBody(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodPost, "/rooms", strings.NewReader(""))
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", w.Code)
	}
}

func TestCreateRoom_EmptyDeviceIdHash(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":""}`
	req := httptest.NewRequest(http.MethodPost, "/rooms", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", w.Code)
	}

	var msg protocol.Message
	if err := json.NewDecoder(w.Body).Decode(&msg); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	var payload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to decode payload: %v", err)
	}
	if payload.Code != protocol.ErrInvalidRequest {
		t.Errorf("expected code %q, got %q", protocol.ErrInvalidRequest, payload.Code)
	}
}

func createTestRoom(t *testing.T, h *Handler) string {
	t.Helper()
	_, code, err := h.manager.CreateRoom(nil, "host-hash")
	if err != nil {
		t.Fatalf("failed to create test room: %v", err)
	}
	t.Cleanup(func() { h.manager.CleanupRoom(code) })
	return code
}

func TestJoinRoom_Success(t *testing.T) {
	h := newTestHandler()
	code := createTestRoom(t, h)

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"player-hash","displayName":"Alice"}`
	req := httptest.NewRequest(http.MethodPost, "/rooms/"+code+"/join", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d; body: %s", w.Code, w.Body.String())
	}

	var resp struct {
		JWT string `json:"jwt"`
	}
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if resp.JWT == "" {
		t.Error("expected non-empty JWT")
	}
}

func TestJoinRoom_MissingBody(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodPost, "/rooms/ABCD/join", strings.NewReader(""))
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", w.Code)
	}
}

func TestJoinRoom_EmptyDisplayName(t *testing.T) {
	h := newTestHandler()
	code := createTestRoom(t, h)

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"player-hash","displayName":""}`
	req := httptest.NewRequest(http.MethodPost, "/rooms/"+code+"/join", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d; body: %s", w.Code, w.Body.String())
	}
}

func TestJoinRoom_DisplayNameTooLong(t *testing.T) {
	h := newTestHandler()
	code := createTestRoom(t, h)

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"player-hash","displayName":"ThisNameIsWayTooLongForTheLimit"}`
	req := httptest.NewRequest(http.MethodPost, "/rooms/"+code+"/join", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d; body: %s", w.Code, w.Body.String())
	}
}

func TestJoinRoom_RoomNotFound(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"player-hash","displayName":"Alice"}`
	req := httptest.NewRequest(http.MethodPost, "/rooms/ZZZZ/join", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Fatalf("expected status 404, got %d; body: %s", w.Code, w.Body.String())
	}

	var msg protocol.Message
	if err := json.NewDecoder(w.Body).Decode(&msg); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	var payload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to decode payload: %v", err)
	}
	if payload.Code != protocol.ErrRoomNotFound {
		t.Errorf("expected code %q, got %q", protocol.ErrRoomNotFound, payload.Code)
	}
}

func TestJoinRoom_RoomFull(t *testing.T) {
	h := newTestHandler()
	code := createTestRoom(t, h)

	rm := h.manager.FindRoom(code)

	// Fill the room to capacity with mock player connections.
	for i := 0; i < room.MaxPlayers; i++ {
		conn, _ := newWSPairForHandler(t)
		pc := room.NewPlayerConn(conn, fmt.Sprintf("player-%d", i), "")
		if err := rm.AddPlayer(fmt.Sprintf("player-%d", i), pc); err != nil {
			t.Fatalf("failed to add player %d: %v", i, err)
		}
	}

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	body := `{"deviceIdHash":"extra-player","displayName":"Bob"}`
	req := httptest.NewRequest(http.MethodPost, "/rooms/"+code+"/join", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusConflict {
		t.Fatalf("expected status 409, got %d; body: %s", w.Code, w.Body.String())
	}

	var msg protocol.Message
	if err := json.NewDecoder(w.Body).Decode(&msg); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	var payload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to decode payload: %v", err)
	}
	if payload.Code != protocol.ErrRoomFull {
		t.Errorf("expected code %q, got %q", protocol.ErrRoomFull, payload.Code)
	}
}
