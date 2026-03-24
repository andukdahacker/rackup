package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/ducdo/rackup-server/internal/protocol"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Handler holds dependencies for HTTP handlers.
type Handler struct {
	pool      *pgxpool.Pool
	startTime time.Time
}

// New creates a new Handler with the given database pool.
func New(pool *pgxpool.Pool) *Handler {
	return &Handler{
		pool:      pool,
		startTime: time.Now(),
	}
}

// healthResponse is the JSON structure for the health endpoint.
type healthResponse struct {
	Status      string `json:"status"`
	Rooms       int    `json:"rooms"`
	Connections int    `json:"connections"`
	Uptime      string `json:"uptime"`
}

// Health returns server health status.
func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	resp := healthResponse{
		Status:      "ok",
		Rooms:       0,
		Connections: 0,
		Uptime:      time.Since(h.startTime).Round(time.Second).String(),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// CreateRoom is a stub for room creation (Story 1.5).
func (h *Handler) CreateRoom(w http.ResponseWriter, r *http.Request) {
	writeNotImplemented(w, "Room creation available in Story 1.5")
}

// JoinRoom is a stub for room joining (Story 1.5).
func (h *Handler) JoinRoom(w http.ResponseWriter, r *http.Request) {
	writeNotImplemented(w, "Room joining available in Story 1.5")
}

func writeNotImplemented(w http.ResponseWriter, message string) {
	resp := protocol.Message{
		Action: protocol.ActionError,
	}
	payload := protocol.ErrorPayload{
		Code:    protocol.ErrNotImplemented,
		Message: message,
	}
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		http.Error(w, `{"action":"error","payload":{"code":"INTERNAL","message":"marshal error"}}`, http.StatusInternalServerError)
		return
	}
	resp.Payload = payloadBytes

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(resp)
}

// RegisterRoutes registers all HTTP routes on the given ServeMux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /rooms", h.CreateRoom)
	mux.HandleFunc("POST /rooms/{code}/join", h.JoinRoom)
}
