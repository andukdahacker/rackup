package protocol

import "encoding/json"

// Message is the wire format for all WebSocket communication.
// All messages use: {"action": "namespace.verb_noun", "payload": {...}}
type Message struct {
	Action  string          `json:"action"`
	Payload json.RawMessage `json:"payload"`
}

// ErrorPayload is the payload for action "error".
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}
