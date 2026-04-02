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

// GamePlayerPayload represents a single player in game initialization messages.
type GamePlayerPayload struct {
	DeviceIDHash string `json:"deviceIdHash"`
	DisplayName  string `json:"displayName"`
	Slot         int    `json:"slot"`
	Score        int    `json:"score"`
	Streak       int    `json:"streak"`
	IsReferee    bool   `json:"isReferee"`
}

// GameInitializedPayload is the server→client payload for game.initialized broadcast.
type GameInitializedPayload struct {
	RoundCount               int                 `json:"roundCount"`
	RefereeDeviceIDHash      string              `json:"refereeDeviceIdHash"`
	TurnOrder                []string             `json:"turnOrder"`
	CurrentShooterDeviceIDHash string            `json:"currentShooterDeviceIdHash"`
	Players                  []GamePlayerPayload  `json:"players"`
}

// ConfirmShotPayload is the client→server payload for referee.confirm_shot.
type ConfirmShotPayload struct {
	Result string `json:"result"` // "made" or "missed"
}

// TurnCompletePayload is the server→client payload for game.turn_complete.
type TurnCompletePayload struct {
	ShooterHash        string             `json:"shooterHash"`
	Result             string             `json:"result"`
	PointsAwarded      int                `json:"pointsAwarded"`
	NewScore           int                `json:"newScore"`
	NewStreak          int                `json:"newStreak"`
	CurrentShooterHash string             `json:"currentShooterHash"` // next shooter
	CurrentRound       int                `json:"currentRound"`
	IsGameOver         bool               `json:"isGameOver"`
	StreakLabel         string             `json:"streakLabel"`         // "", "warming_up", "on_fire", "unstoppable"
	StreakMilestone     bool               `json:"streakMilestone"`     // true when streak threshold just crossed
	Leaderboard        []LeaderboardEntry `json:"leaderboard"`         // sorted by score descending
	CascadeProfile     string             `json:"cascadeProfile"`      // "routine", "streak_milestone", etc.
}

// LeaderboardEntry represents a single player's ranking in the leaderboard.
type LeaderboardEntry struct {
	DeviceIDHash string `json:"deviceIdHash"`
	DisplayName  string `json:"displayName"`
	Score        int    `json:"score"`
	Streak       int    `json:"streak"`
	StreakLabel   string `json:"streakLabel"`
	Rank         int    `json:"rank"`
	RankChanged  bool   `json:"rankChanged"`
}

// ErrorPayload is the payload for action "error".
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}
