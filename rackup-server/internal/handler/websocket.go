package handler

import (
	"log/slog"
	"net/http"
	"os"
	"strings"

	"github.com/ducdo/rackup-server/internal/auth"
	"github.com/ducdo/rackup-server/internal/protocol"
	"github.com/ducdo/rackup-server/internal/room"
	"nhooyr.io/websocket"
)

// Upgrade handles GET /ws — validates JWT and upgrades to WebSocket.
func (h *Handler) Upgrade(w http.ResponseWriter, r *http.Request) {
	// Extract JWT from Authorization header before upgrading.
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "missing Authorization header", http.StatusUnauthorized)
		return
	}

	tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
	if tokenStr == authHeader || tokenStr == "" {
		http.Error(w, "invalid Authorization header format", http.StatusUnauthorized)
		return
	}

	claims, err := auth.ValidateClaims(h.jwtSecret, tokenStr)
	if err != nil {
		slog.Warn("WebSocket auth failed", "error", err)
		http.Error(w, "invalid or expired token", http.StatusUnauthorized)
		return
	}

	// Find the room.
	rm := h.manager.FindRoom(claims.RoomCode)
	if rm == nil {
		http.Error(w, "room not found", http.StatusNotFound)
		return
	}

	// Accept WebSocket upgrade.
	// Only skip origin verification in development.
	acceptOpts := &websocket.AcceptOptions{}
	if os.Getenv("ENVIRONMENT") != "production" {
		acceptOpts.InsecureSkipVerify = true
	}
	conn, err := websocket.Accept(w, r, acceptOpts)
	if err != nil {
		slog.Error("WebSocket accept failed", "error", err)
		return
	}

	pc := room.NewPlayerConn(conn, claims.DeviceIDHash, claims.DisplayName)

	ctx := r.Context()

	// Start write pump before AddPlayer so the outbound channel is being drained.
	go pc.WritePump(ctx)

	// AddPlayer atomically sends room_state to the new player and broadcasts
	// player_joined to others — no separate GetRoomState call needed.
	if err := rm.AddPlayer(claims.DeviceIDHash, pc); err != nil {
		slog.Warn("failed to add player to room", "room", claims.RoomCode, "error", err)
		conn.Close(websocket.StatusPolicyViolation, protocol.ErrRoomFull)
		return
	}

	// Read pump — dispatches messages to room action channel.
	go func() {
		defer func() {
			rm.RemovePlayer(claims.DeviceIDHash)
			pc.Close()
		}()

		for {
			data, err := pc.ReadMessage(ctx)
			if err != nil {
				slog.Debug("WebSocket read error", "device", claims.DeviceIDHash, "error", err)
				return
			}

			rm.SendAction(room.Action{
				Type:    "client_message",
				Player:  claims.DeviceIDHash,
				Payload: data,
			})
		}
	}()
}
