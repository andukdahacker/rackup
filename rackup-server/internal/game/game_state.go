package game

import "sort"

// GamePhase represents the current phase of a game.
const (
	PhasePlaying = "playing"
	PhaseEnded   = "ended"
)

// GamePlayer holds per-player game state.
type GamePlayer struct {
	DeviceIDHash string
	DisplayName  string
	Slot         int
	Score        int
	Streak       int
	IsReferee    bool
}

// GameState holds the full state of an active game session.
type GameState struct {
	RoundCount          int
	CurrentRound        int
	RefereeDeviceIDHash string
	TurnOrder           []string
	CurrentShooterIndex int
	Players             map[string]*GamePlayer
	GamePhase           string
}

// NewGameState creates a GameState from the current room players.
// Referee assignment: first non-host player in slot order; if only 2 players, host is referee.
// Turn order: players sorted by ascending slot number.
func NewGameState(players map[string]string, slotAssignments map[string]int, roundCount int, hostDeviceHash string) *GameState {
	// Build sorted player list by slot number.
	type playerEntry struct {
		deviceHash  string
		displayName string
		slot        int
	}

	entries := make([]playerEntry, 0, len(players))
	for deviceHash, displayName := range players {
		slot := slotAssignments[deviceHash]
		entries = append(entries, playerEntry{
			deviceHash:  deviceHash,
			displayName: displayName,
			slot:        slot,
		})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].slot < entries[j].slot
	})

	// Determine referee.
	refereeHash := hostDeviceHash // default: host is referee (2-player case)
	if len(entries) > 2 {
		// First non-host player in slot order.
		for _, e := range entries {
			if e.deviceHash != hostDeviceHash {
				refereeHash = e.deviceHash
				break
			}
		}
	}

	// Build turn order and player map.
	turnOrder := make([]string, len(entries))
	gamePlayers := make(map[string]*GamePlayer, len(entries))
	for i, e := range entries {
		turnOrder[i] = e.deviceHash
		gamePlayers[e.deviceHash] = &GamePlayer{
			DeviceIDHash: e.deviceHash,
			DisplayName:  e.displayName,
			Slot:         e.slot,
			Score:        0,
			Streak:       0,
			IsReferee:    e.deviceHash == refereeHash,
		}
	}

	return &GameState{
		RoundCount:          roundCount,
		CurrentRound:        1,
		RefereeDeviceIDHash: refereeHash,
		TurnOrder:           turnOrder,
		CurrentShooterIndex: 0,
		Players:             gamePlayers,
		GamePhase:           PhasePlaying,
	}
}

// IsReferee returns true if the given device ID hash matches the current referee.
func (gs *GameState) IsReferee(deviceIDHash string) bool {
	return gs.RefereeDeviceIDHash == deviceIDHash
}

// CurrentShooterDeviceIDHash returns the device ID hash of the current shooter.
func (gs *GameState) CurrentShooterDeviceIDHash() string {
	if len(gs.TurnOrder) == 0 {
		return ""
	}
	return gs.TurnOrder[gs.CurrentShooterIndex]
}
