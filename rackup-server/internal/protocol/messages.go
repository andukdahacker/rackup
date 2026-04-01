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
	RoomCode           string               `json:"roomCode"`
	HostDeviceIDHash   string               `json:"hostDeviceIdHash"`
	Players            []LobbyPlayerPayload `json:"players"`
	AllReadyOrTimedOut bool                 `json:"allReadyOrTimedOut"`
}

// PunishmentSubmitPayload is the client→server payload for punishment submission.
type PunishmentSubmitPayload struct {
	Text string `json:"text"`
}

// PlayerStatusChangedPayload is the server→client payload for status change broadcasts.
type PlayerStatusChangedPayload struct {
	DeviceIDHash string `json:"deviceIdHash"`
	Status       string `json:"status"`
}

// StartGamePayload is the client→server payload for starting the game.
type StartGamePayload struct {
	RoundCount int `json:"roundCount"`
}

// GameStartedPayload is the server→client payload for game started broadcast.
type GameStartedPayload struct {
	RoundCount int `json:"roundCount"`
}

// ErrorPayload is the payload for action "error".
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}
