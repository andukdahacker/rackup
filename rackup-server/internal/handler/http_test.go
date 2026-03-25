package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/ducdo/rackup-server/internal/protocol"
	"github.com/ducdo/rackup-server/internal/room"
)

var testSecret = []byte("test-secret-key-that-is-at-least-32-bytes-long!!")

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

func TestJoinRoom_NotImplemented(t *testing.T) {
	h := newTestHandler()

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodPost, "/rooms/ABCD/join", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusNotImplemented {
		t.Fatalf("expected status 501, got %d", w.Code)
	}
}
