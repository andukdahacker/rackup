package game

import (
	"errors"
	"sort"
	"time"
)

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

// TurnResult holds the outcome of a ProcessShot call.
type TurnResult struct {
	ShooterHash        string
	Result             string
	PointsAwarded      int
	NewScore           int
	NewStreak          int
	NextShooterHash    string
	CurrentRound       int
	IsGameOver         bool
	IsTriplePoints     bool
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

	// Undo tracking.
	LastShotResult      string    // "made" or "missed"; empty if no shot yet
	LastShotTime        time.Time // when the last shot was processed
	lastShooterHash     string    // who took the last shot
	lastScoreDelta      int       // points awarded on last shot (for undo)
	lastStreakBefore     int       // streak before last shot (for undo)
	lastShooterIdxBefore int      // currentShooterIndex before AdvanceTurn
	lastRoundBefore      int      // currentRound before AdvanceTurn
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

// streakBonus returns the bonus points for the given streak count.
// Streak 0-1 = 0, 2 = +1, 3 = +2, 4+ = +3.
func streakBonus(streak int) int {
	switch {
	case streak >= 4:
		return 3
	case streak == 3:
		return 2
	case streak == 2:
		return 1
	default:
		return 0
	}
}

// ProcessShot processes a shot result for the current shooter.
// Returns a TurnResult with scoring details.
func (gs *GameState) ProcessShot(shooterHash string, result string) (*TurnResult, error) {
	if gs.GamePhase != PhasePlaying {
		return nil, errors.New("game is not in playing phase")
	}
	if shooterHash != gs.CurrentShooterDeviceIDHash() {
		return nil, errors.New("not the current shooter")
	}
	if result != "made" && result != "missed" {
		return nil, errors.New("invalid result: must be 'made' or 'missed'")
	}

	player := gs.Players[shooterHash]
	if player == nil {
		return nil, errors.New("player not found")
	}

	// Save undo state.
	gs.lastShooterHash = shooterHash
	gs.lastStreakBefore = player.Streak
	gs.lastShooterIdxBefore = gs.CurrentShooterIndex
	gs.lastRoundBefore = gs.CurrentRound

	// Calculate score.
	var points int
	if result == "made" {
		player.Streak++
		points = 3 + streakBonus(player.Streak)
		if gs.IsTriplePoints() {
			points *= 3
		}
		player.Score += points
	} else {
		player.Streak = 0
		points = 0
	}

	gs.lastScoreDelta = points
	gs.LastShotResult = result
	gs.LastShotTime = time.Now()

	// Advance turn.
	gs.AdvanceTurn()

	return &TurnResult{
		ShooterHash:     shooterHash,
		Result:          result,
		PointsAwarded:   points,
		NewScore:        player.Score,
		NewStreak:       player.Streak,
		NextShooterHash: gs.CurrentShooterDeviceIDHash(),
		CurrentRound:    gs.CurrentRound,
		IsGameOver:      gs.IsGameOver(),
		IsTriplePoints:  gs.IsTriplePoints(),
	}, nil
}

// AdvanceTurn moves to the next shooter in turn order.
// Increments currentRound when wrapping back to the first player.
func (gs *GameState) AdvanceTurn() {
	if len(gs.TurnOrder) == 0 {
		return
	}
	gs.CurrentShooterIndex++
	if gs.CurrentShooterIndex >= len(gs.TurnOrder) {
		gs.CurrentShooterIndex = 0
		gs.CurrentRound++
	}
}

// UndoLastShot reverts the last shot's score and streak changes
// and resets the shooter index to the previous position.
func (gs *GameState) UndoLastShot() error {
	if gs.lastShooterHash == "" {
		return errors.New("no shot to undo")
	}

	player := gs.Players[gs.lastShooterHash]
	if player == nil {
		return errors.New("player not found for undo")
	}

	// Revert score and streak.
	player.Score -= gs.lastScoreDelta
	player.Streak = gs.lastStreakBefore

	// Revert turn advancement.
	gs.CurrentShooterIndex = gs.lastShooterIdxBefore
	gs.CurrentRound = gs.lastRoundBefore

	// Revert game phase if the undone shot ended the game.
	if gs.GamePhase == PhaseEnded {
		gs.GamePhase = PhasePlaying
	}

	// Clear undo state.
	gs.LastShotResult = ""
	gs.LastShotTime = time.Time{}
	gs.lastShooterHash = ""
	gs.lastScoreDelta = 0
	gs.lastStreakBefore = 0
	gs.lastShooterIdxBefore = 0
	gs.lastRoundBefore = 0

	return nil
}

// IsTriplePoints returns true when the game is in the final 3 rounds.
// Examples: 10 rounds → R8-10 triple; 5 rounds → R3-5 triple; ≤3 rounds → ALL triple.
func (gs *GameState) IsTriplePoints() bool {
	return gs.CurrentRound > gs.RoundCount-3
}

// IsGameOver returns true when currentRound exceeds roundCount.
func (gs *GameState) IsGameOver() bool {
	return gs.CurrentRound > gs.RoundCount
}
