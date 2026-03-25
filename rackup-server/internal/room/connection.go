package room

import (
	"context"
	"log/slog"
	"sync"

	"nhooyr.io/websocket"
)

// PlayerConn wraps a WebSocket connection for a player.
type PlayerConn struct {
	mu          sync.Mutex
	conn        *websocket.Conn
	deviceHash  string
	displayName string
	outbound    chan []byte
	closed      bool
}

// NewPlayerConn creates a PlayerConn wrapping the given WebSocket connection.
func NewPlayerConn(conn *websocket.Conn, deviceHash, displayName string) *PlayerConn {
	return &PlayerConn{
		conn:        conn,
		deviceHash:  deviceHash,
		displayName: displayName,
		outbound:    make(chan []byte, 64),
	}
}

// DeviceHash returns the player's device ID hash.
func (pc *PlayerConn) DeviceHash() string {
	return pc.deviceHash
}

// DisplayName returns the player's display name.
func (pc *PlayerConn) DisplayName() string {
	return pc.displayName
}

// ReadMessage reads a single text message from the WebSocket.
func (pc *PlayerConn) ReadMessage(ctx context.Context) ([]byte, error) {
	_, data, err := pc.conn.Read(ctx)
	return data, err
}

// WriteMessage queues a message for sending via the write pump.
// Returns ErrOutboundFull if the channel is full.
func (pc *PlayerConn) WriteMessage(data []byte) error {
	pc.mu.Lock()
	defer pc.mu.Unlock()

	if pc.closed {
		return websocket.CloseError{Code: websocket.StatusGoingAway}
	}

	select {
	case pc.outbound <- data:
		return nil
	default:
		slog.Warn("player outbound channel full", "device", pc.deviceHash)
		return ErrOutboundFull
	}
}

// WritePump continuously sends messages from the outbound channel to the WebSocket.
// It runs until the context is cancelled or the connection is closed.
// All writes go through this single goroutine to avoid concurrent writes.
func (pc *PlayerConn) WritePump(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-pc.outbound:
			if !ok {
				return
			}
			pc.mu.Lock()
			closed := pc.closed
			pc.mu.Unlock()
			if closed {
				return
			}
			if err := pc.conn.Write(ctx, websocket.MessageText, msg); err != nil {
				slog.Debug("write pump error", "device", pc.deviceHash, "error", err)
				return
			}
		}
	}
}

// Close closes the WebSocket connection.
func (pc *PlayerConn) Close() {
	pc.mu.Lock()
	defer pc.mu.Unlock()

	if pc.closed {
		return
	}
	pc.closed = true
	close(pc.outbound)
	pc.conn.Close(websocket.StatusNormalClosure, "")
}
