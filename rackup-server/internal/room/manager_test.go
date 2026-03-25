package room

import (
	"context"
	"sync"
	"testing"
)

func TestCreateRoom(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()

	room, code, err := m.CreateRoom(ctx, "host-hash")
	if err != nil {
		t.Fatalf("CreateRoom failed: %v", err)
	}
	if room == nil {
		t.Fatal("expected non-nil room")
	}
	if len(code) != codeLength {
		t.Errorf("expected code length %d, got %d", codeLength, len(code))
	}
	for _, c := range code {
		if c < 'A' || c > 'Z' {
			t.Errorf("code contains non-alpha character: %c", c)
		}
	}

	// Cleanup
	m.CleanupRoom(code)
}

func TestFindRoom(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()

	room, code, err := m.CreateRoom(ctx, "host-hash")
	if err != nil {
		t.Fatalf("CreateRoom failed: %v", err)
	}

	found := m.FindRoom(code)
	if found != room {
		t.Error("FindRoom returned different room")
	}

	notFound := m.FindRoom("ZZZZ")
	if notFound != nil {
		t.Error("expected nil for non-existent room")
	}

	m.CleanupRoom(code)
}

func TestCleanupRoom(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()

	_, code, err := m.CreateRoom(ctx, "host-hash")
	if err != nil {
		t.Fatalf("CreateRoom failed: %v", err)
	}

	m.CleanupRoom(code)

	if m.FindRoom(code) != nil {
		t.Error("expected room to be removed after cleanup")
	}
	if m.RoomCount() != 0 {
		t.Errorf("expected 0 rooms, got %d", m.RoomCount())
	}
}

func TestCleanupRoom_NonExistent(t *testing.T) {
	m := NewRoomManager()
	// Should not panic.
	m.CleanupRoom("XXXX")
}

func TestCodeGenerationUniqueness(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()
	codes := make(map[string]bool)

	for i := 0; i < 20; i++ {
		_, code, err := m.CreateRoom(ctx, "host-hash")
		if err != nil {
			t.Fatalf("CreateRoom failed on iteration %d: %v", i, err)
		}
		if codes[code] {
			t.Fatalf("duplicate code generated: %s", code)
		}
		codes[code] = true
	}

	// Cleanup
	for code := range codes {
		m.CleanupRoom(code)
	}
}

func TestConcurrentRoomCreation(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()
	const n = 20

	var wg sync.WaitGroup
	errs := make(chan error, n)
	codes := make(chan string, n)

	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, code, err := m.CreateRoom(ctx, "host-hash")
			if err != nil {
				errs <- err
				return
			}
			codes <- code
		}()
	}

	wg.Wait()
	close(errs)
	close(codes)

	for err := range errs {
		t.Errorf("concurrent CreateRoom error: %v", err)
	}

	if m.RoomCount() != n {
		t.Errorf("expected %d rooms, got %d", n, m.RoomCount())
	}

	// Cleanup
	for code := range codes {
		m.CleanupRoom(code)
	}
}

func TestCapacityExceeded(t *testing.T) {
	m := NewRoomManager()
	ctx := context.Background()

	var createdCodes []string
	for i := 0; i < maxRooms; i++ {
		_, code, err := m.CreateRoom(ctx, "host-hash")
		if err != nil {
			t.Fatalf("CreateRoom failed at %d: %v", i, err)
		}
		createdCodes = append(createdCodes, code)
	}

	_, _, err := m.CreateRoom(ctx, "host-hash")
	if err == nil {
		t.Fatal("expected capacity exceeded error")
	}

	// Cleanup
	for _, code := range createdCodes {
		m.CleanupRoom(code)
	}
}
