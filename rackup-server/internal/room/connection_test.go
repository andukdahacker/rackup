package room

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"nhooyr.io/websocket"
)

func newWSPair(t *testing.T) (*websocket.Conn, *websocket.Conn) {
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
		// Block until test ends.
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

func TestNewPlayerConn(t *testing.T) {
	clientConn, _ := newWSPair(t)
	pc := NewPlayerConn(clientConn, "device-hash", "Alice")

	if pc.DeviceHash() != "device-hash" {
		t.Errorf("expected device hash 'device-hash', got %q", pc.DeviceHash())
	}
	if pc.DisplayName() != "Alice" {
		t.Errorf("expected display name 'Alice', got %q", pc.DisplayName())
	}
}

func TestWriteAndReadMessage(t *testing.T) {
	clientConn, serverConn := newWSPair(t)

	// Write from server, read from client PlayerConn.
	pc := NewPlayerConn(clientConn, "device-hash", "")

	msg := []byte(`{"action":"test","payload":{}}`)
	err := serverConn.Write(context.Background(), websocket.MessageText, msg)
	if err != nil {
		t.Fatalf("server write failed: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	data, err := pc.ReadMessage(ctx)
	if err != nil {
		t.Fatalf("ReadMessage failed: %v", err)
	}

	if string(data) != string(msg) {
		t.Errorf("expected %q, got %q", string(msg), string(data))
	}
}

func TestWriteMessageQueuesAndWritePumpSends(t *testing.T) {
	clientConn, serverConn := newWSPair(t)

	pc := NewPlayerConn(clientConn, "device-hash", "")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go pc.WritePump(ctx)

	msg := []byte(`{"action":"pump.test","payload":{}}`)
	if err := pc.WriteMessage(msg); err != nil {
		t.Fatalf("WriteMessage failed: %v", err)
	}

	readCtx, readCancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer readCancel()

	_, data, err := serverConn.Read(readCtx)
	if err != nil {
		t.Fatalf("server read failed: %v", err)
	}

	if string(data) != string(msg) {
		t.Errorf("expected %q, got %q", string(msg), string(data))
	}
}

func TestClose(t *testing.T) {
	clientConn, _ := newWSPair(t)
	pc := NewPlayerConn(clientConn, "device-hash", "")

	pc.Close()

	// Writing after close should not panic.
	err := pc.WriteMessage([]byte("test"))
	if err == nil {
		t.Error("expected error writing to closed connection")
	}

	// Double close should not panic.
	pc.Close()
}
