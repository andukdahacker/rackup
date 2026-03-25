package handler

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/ducdo/rackup-server/internal/auth"
	"github.com/ducdo/rackup-server/internal/protocol"
	"github.com/ducdo/rackup-server/internal/room"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Handler holds dependencies for HTTP handlers.
type Handler struct {
	pool      *pgxpool.Pool
	manager   *room.RoomManager
	jwtSecret []byte
	startTime time.Time
}

// New creates a new Handler with the given dependencies.
func New(pool *pgxpool.Pool, manager *room.RoomManager, jwtSecret []byte) *Handler {
	return &Handler{
		pool:      pool,
		manager:   manager,
		jwtSecret: jwtSecret,
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
		Rooms:       h.manager.RoomCount(),
		Connections: 0,
		Uptime:      time.Since(h.startTime).Round(time.Second).String(),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// createRoomRequest is the expected JSON body for POST /rooms.
type createRoomRequest struct {
	DeviceIDHash string `json:"deviceIdHash"`
}

// createRoomResponse is the JSON response for successful room creation.
type createRoomResponse struct {
	RoomCode string `json:"roomCode"`
	JWT      string `json:"jwt"`
}

// CreateRoom handles POST /rooms — creates a new room and returns the code + JWT.
func (h *Handler) CreateRoom(w http.ResponseWriter, r *http.Request) {
	var req createRoomRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DeviceIDHash == "" {
		writeError(w, http.StatusBadRequest, protocol.ErrInvalidRequest, "deviceIdHash is required")
		return
	}

	rm, code, err := h.manager.CreateRoom(r.Context(), req.DeviceIDHash)
	if err != nil {
		slog.Error("failed to create room", "error", err)
		if errors.Is(err, room.ErrCapacityExceeded) {
			writeError(w, http.StatusServiceUnavailable, protocol.ErrCapacityExceeded, "Server at capacity, please try again later")
			return
		}
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "Failed to create room")
		return
	}

	// Host creates room without display name (added in lobby, Story 1.6).
	token, err := auth.IssueToken(h.jwtSecret, code, req.DeviceIDHash, "")
	if err != nil {
		slog.Error("failed to issue JWT", "error", err, "room", code)
		h.manager.CleanupRoom(code)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "Failed to create room")
		return
	}

	_ = rm // Room goroutine is already running.

	resp := createRoomResponse{
		RoomCode: code,
		JWT:      token,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

// JoinRoom is a stub for room joining (Story 1.6).
func (h *Handler) JoinRoom(w http.ResponseWriter, r *http.Request) {
	writeNotImplemented(w, "Room joining available in Story 1.6")
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	resp := protocol.Message{
		Action: protocol.ActionError,
	}
	payload := protocol.ErrorPayload{
		Code:    code,
		Message: message,
	}
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		http.Error(w, `{"action":"error","payload":{"code":"INTERNAL","message":"marshal error"}}`, http.StatusInternalServerError)
		return
	}
	resp.Payload = payloadBytes

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(resp)
}

func writeNotImplemented(w http.ResponseWriter, message string) {
	writeError(w, http.StatusNotImplemented, protocol.ErrNotImplemented, message)
}

// RegisterRoutes registers all HTTP routes on the given ServeMux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /rooms", h.CreateRoom)
	mux.HandleFunc("POST /rooms/{code}/join", h.JoinRoom)
	mux.HandleFunc("GET /ws", h.Upgrade)
}
