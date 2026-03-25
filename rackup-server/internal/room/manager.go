package room

import (
	"context"
	"crypto/rand"
	"fmt"
	"log/slog"
	"math/big"
	"sync"
)

const (
	// codeLength is the length of a room code.
	codeLength = 4
	// maxRooms is the maximum number of concurrent rooms (NFR16).
	maxRooms = 100
	// codeChars are the characters used for room code generation (A-Z only).
	codeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	// maxCodeAttempts is the maximum number of attempts to generate a unique code.
	maxCodeAttempts = 100
)

// RoomManager manages the lifecycle of game rooms.
type RoomManager struct {
	mu    sync.RWMutex
	rooms map[string]*Room
}

// NewRoomManager creates a new RoomManager.
func NewRoomManager() *RoomManager {
	return &RoomManager{
		rooms: make(map[string]*Room),
	}
}

// ErrCapacityExceeded is returned when the room limit is reached.
var ErrCapacityExceeded = fmt.Errorf("room capacity exceeded")

// CreateRoom creates a new room with a unique code and starts its goroutine.
// Returns the room and its code, or an error if capacity is exceeded.
// The room goroutine uses a background context (not tied to the HTTP request).
func (m *RoomManager) CreateRoom(_ context.Context, hostDeviceIDHash string) (*Room, string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if len(m.rooms) >= maxRooms {
		return nil, "", ErrCapacityExceeded
	}

	code, err := m.generateUniqueCode()
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate room code: %w", err)
	}

	roomCtx, cancel := context.WithCancel(context.Background())
	room := NewRoom(code, hostDeviceIDHash, cancel, m)
	m.rooms[code] = room

	go room.Run(roomCtx)

	slog.Info("room created", "code", code, "host", hostDeviceIDHash)
	return room, code, nil
}

// FindRoom returns the room with the given code, or nil if not found.
func (m *RoomManager) FindRoom(code string) *Room {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.rooms[code]
}

// CleanupRoom cancels the room's context and removes it from the registry.
func (m *RoomManager) CleanupRoom(code string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	room, ok := m.rooms[code]
	if !ok {
		return
	}

	room.cancel()
	delete(m.rooms, code)
	slog.Info("room cleaned up", "code", code)
}

// RoomCount returns the number of active rooms.
func (m *RoomManager) RoomCount() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.rooms)
}

// generateUniqueCode generates a random 4-character alpha code
// that doesn't collide with existing rooms. Must be called with mu held.
func (m *RoomManager) generateUniqueCode() (string, error) {
	for i := 0; i < maxCodeAttempts; i++ {
		code, err := generateCode()
		if err != nil {
			return "", err
		}
		if _, exists := m.rooms[code]; !exists {
			return code, nil
		}
	}
	return "", fmt.Errorf("failed to generate unique code after %d attempts", maxCodeAttempts)
}

// generateCode generates a random 4-character alpha code using crypto/rand.
func generateCode() (string, error) {
	code := make([]byte, codeLength)
	for i := range code {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(codeChars))))
		if err != nil {
			return "", err
		}
		code[i] = codeChars[n.Int64()]
	}
	return string(code), nil
}
