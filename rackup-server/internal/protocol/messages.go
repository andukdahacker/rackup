package protocol

import "encoding/json"

// Message is the wire format for all WebSocket communication.
// All messages use: {"action": "namespace.verb_noun", "payload": {...}}
type Message struct {
	Action  string          `json:"action"`
	Payload json.RawMessage `json:"payload"`
}

// LobbyPlayerPayload represents a single player in lobby messages.
type LobbyPlayerPayload struct {
	DisplayName  string `json:"displayName"`
	DeviceIDHash string `json:"deviceIdHash"`
	Slot         int    `json:"slot"`
	IsHost       bool   `json:"isHost"`
	Status       string `json:"status"`
}

// LobbyRoomStatePayload is the payload for lobby.room_state.
type LobbyRoomStatePayload struct {
	RoomCode         string               `json:"roomCode"`
	HostDeviceIDHash string               `json:"hostDeviceIdHash"`
	Players          []LobbyPlayerPayload `json:"players"`
}

// ErrorPayload is the payload for action "error".
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}
