package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ducdo/rackup-server/internal/protocol"
)

func TestHealth(t *testing.T) {
	h := New(nil) // pool not needed for health check

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

func TestCreateRoom_NotImplemented(t *testing.T) {
	h := New(nil)

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodPost, "/rooms", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusNotImplemented {
		t.Fatalf("expected status 501, got %d", w.Code)
	}

	var msg protocol.Message
	if err := json.NewDecoder(w.Body).Decode(&msg); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if msg.Action != protocol.ActionError {
		t.Errorf("expected action %q, got %q", protocol.ActionError, msg.Action)
	}

	var payload protocol.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("failed to decode payload: %v", err)
	}
	if payload.Code != protocol.ErrNotImplemented {
		t.Errorf("expected code %q, got %q", protocol.ErrNotImplemented, payload.Code)
	}
}

func TestJoinRoom_NotImplemented(t *testing.T) {
	h := New(nil)

	mux := http.NewServeMux()
	h.RegisterRoutes(mux)

	req := httptest.NewRequest(http.MethodPost, "/rooms/ABCD/join", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusNotImplemented {
		t.Fatalf("expected status 501, got %d", w.Code)
	}
}
