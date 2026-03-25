package testutil

import (
	"context"

	"github.com/ducdo/rackup-server/internal/room"
)

// NewTestRoomManager creates a RoomManager for testing.
func NewTestRoomManager() *room.RoomManager {
	return room.NewRoomManager()
}

// NewTestRoom creates a Room with a test code and returns the cancel func.
func NewTestRoom(code, hostHash string) (*room.Room, context.CancelFunc) {
	_, cancel := context.WithCancel(context.Background())
	r := room.NewRoom(code, hostHash, cancel, nil)
	return r, cancel
}
