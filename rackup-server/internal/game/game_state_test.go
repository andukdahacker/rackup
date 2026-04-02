package game

import (
	"testing"
	"time"
)

func TestNewGameState_RefereeAssignment_ThreePlayers(t *testing.T) {
	// When 3+ players, first non-host in slot order becomes referee.
	players := map[string]string{
		"host-hash":   "Host",
		"player2-hash": "Player2",
		"player3-hash": "Player3",
	}
	slots := map[string]int{
		"host-hash":    1,
		"player2-hash": 2,
		"player3-hash": 3,
	}

	gs := NewGameState(players, slots, 10, "host-hash")

	if gs.RefereeDeviceIDHash != "player2-hash" {
		t.Errorf("expected referee to be player2-hash (first non-host in slot order), got %q", gs.RefereeDeviceIDHash)
	}

	// Verify referee player has IsReferee=true.
	if !gs.Players["player2-hash"].IsReferee {
		t.Error("expected player2 to have IsReferee=true")
	}
	if gs.Players["host-hash"].IsReferee {
		t.Error("expected host to have IsReferee=false")
	}
}

func TestNewGameState_RefereeAssignment_TwoPlayers(t *testing.T) {
	// When only 2 players, host becomes referee.
	players := map[string]string{
		"host-hash":   "Host",
		"player2-hash": "Player2",
	}
	slots := map[string]int{
		"host-hash":    1,
		"player2-hash": 2,
	}

	gs := NewGameState(players, slots, 10, "host-hash")

	if gs.RefereeDeviceIDHash != "host-hash" {
		t.Errorf("expected referee to be host-hash (2-player case), got %q", gs.RefereeDeviceIDHash)
	}

	if !gs.Players["host-hash"].IsReferee {
		t.Error("expected host to have IsReferee=true in 2-player case")
	}
}

func TestNewGameState_TurnOrderSortedBySlot(t *testing.T) {
	players := map[string]string{
		"hash-c": "Charlie",
		"hash-a": "Alice",
		"hash-b": "Bob",
	}
	slots := map[string]int{
		"hash-c": 3,
		"hash-a": 1,
		"hash-b": 2,
	}

	gs := NewGameState(players, slots, 5, "hash-a")

	expected := []string{"hash-a", "hash-b", "hash-c"}
	if len(gs.TurnOrder) != len(expected) {
		t.Fatalf("expected %d players in turn order, got %d", len(expected), len(gs.TurnOrder))
	}
	for i, want := range expected {
		if gs.TurnOrder[i] != want {
			t.Errorf("turn order[%d]: expected %q, got %q", i, want, gs.TurnOrder[i])
		}
	}
}

func TestIsReferee(t *testing.T) {
	players := map[string]string{
		"host-hash":   "Host",
		"player2-hash": "Player2",
		"player3-hash": "Player3",
	}
	slots := map[string]int{
		"host-hash":    1,
		"player2-hash": 2,
		"player3-hash": 3,
	}

	gs := NewGameState(players, slots, 10, "host-hash")

	if !gs.IsReferee("player2-hash") {
		t.Error("expected IsReferee to return true for the assigned referee")
	}
	if gs.IsReferee("host-hash") {
		t.Error("expected IsReferee to return false for non-referee")
	}
	if gs.IsReferee("unknown-hash") {
		t.Error("expected IsReferee to return false for unknown player")
	}
}

// newTestGameState creates a 3-player game state for shot processing tests.
// Turn order: hash-a (slot 1), hash-b (slot 2), hash-c (slot 3).
// Referee: hash-b (first non-host).
func newTestGameState() *GameState {
	players := map[string]string{
		"hash-a": "Alice",
		"hash-b": "Bob",
		"hash-c": "Charlie",
	}
	slots := map[string]int{
		"hash-a": 1,
		"hash-b": 2,
		"hash-c": 3,
	}
	return NewGameState(players, slots, 10, "hash-a")
}

func TestProcessShot_Made_BaseScoring(t *testing.T) {
	gs := newTestGameState()
	shooter := gs.CurrentShooterDeviceIDHash() // hash-a

	result, err := gs.ProcessShot(shooter, "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.PointsAwarded != 3 {
		t.Errorf("expected 3 base points, got %d", result.PointsAwarded)
	}
	if result.NewScore != 3 {
		t.Errorf("expected score=3, got %d", result.NewScore)
	}
	if result.NewStreak != 1 {
		t.Errorf("expected streak=1, got %d", result.NewStreak)
	}
	if result.Result != "made" {
		t.Errorf("expected result='made', got %q", result.Result)
	}
}

func TestProcessShot_Missed(t *testing.T) {
	gs := newTestGameState()
	shooter := gs.CurrentShooterDeviceIDHash()

	result, err := gs.ProcessShot(shooter, "missed")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.PointsAwarded != 0 {
		t.Errorf("expected 0 points, got %d", result.PointsAwarded)
	}
	if result.NewStreak != 0 {
		t.Errorf("expected streak=0, got %d", result.NewStreak)
	}
}

func TestProcessShot_StreakBonuses(t *testing.T) {
	gs := newTestGameState()

	// We need to manually set up streaks by processing multiple shots.
	// Each shot advances the turn, so we need to advance through all players.
	tests := []struct {
		shooter       string
		expectedBonus int
		expectedTotal int
		streak        int
	}{
		// Set up hash-a with consecutive made shots by cycling through rounds.
		// Round 1: hash-a makes (streak=1, bonus=0, points=3)
		{"hash-a", 0, 3, 1},
	}

	for i, tc := range tests {
		result, err := gs.ProcessShot(tc.shooter, "made")
		if err != nil {
			t.Fatalf("test %d: unexpected error: %v", i, err)
		}
		if result.NewStreak != tc.streak {
			t.Errorf("test %d: expected streak=%d, got %d", i, tc.streak, result.NewStreak)
		}
		if result.PointsAwarded != 3+tc.expectedBonus {
			t.Errorf("test %d: expected points=%d, got %d", i, 3+tc.expectedBonus, result.PointsAwarded)
		}
	}
}

func TestProcessShot_StreakBonusProgression(t *testing.T) {
	// Test streak bonus: 0→1 (no bonus), 1→2 (+1), 2→3 (+2), 3→4 (+3)
	// Use a single-player turn order to easily chain shots.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	expected := []struct {
		points int
		streak int
		score  int
	}{
		{3, 1, 3},   // streak 0→1, bonus=0
		{4, 2, 7},   // streak 1→2, bonus=+1
		{5, 3, 12},  // streak 2→3, bonus=+2
		{6, 4, 18},  // streak 3→4, bonus=+3
		{6, 5, 24},  // streak 4→5, bonus=+3 (capped)
	}

	for i, e := range expected {
		result, err := gs.ProcessShot("shooter", "made")
		if err != nil {
			t.Fatalf("shot %d: error: %v", i, err)
		}
		if result.PointsAwarded != e.points {
			t.Errorf("shot %d: expected %d points, got %d", i, e.points, result.PointsAwarded)
		}
		if result.NewStreak != e.streak {
			t.Errorf("shot %d: expected streak=%d, got %d", i, e.streak, result.NewStreak)
		}
		if result.NewScore != e.score {
			t.Errorf("shot %d: expected score=%d, got %d", i, e.score, result.NewScore)
		}
	}
}

func TestProcessShot_MissedResetsStreak(t *testing.T) {
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: 3},
		},
		GamePhase: PhasePlaying,
	}

	result, err := gs.ProcessShot("shooter", "missed")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.NewStreak != 0 {
		t.Errorf("expected streak reset to 0, got %d", result.NewStreak)
	}
}

func TestAdvanceTurn_WrapsAround(t *testing.T) {
	gs := newTestGameState()
	// Turn order: hash-a(0), hash-b(1), hash-c(2)
	if gs.CurrentShooterIndex != 0 {
		t.Fatalf("expected start at index 0")
	}

	gs.AdvanceTurn() // → 1
	if gs.CurrentShooterIndex != 1 || gs.CurrentRound != 1 {
		t.Errorf("after 1st advance: idx=%d round=%d", gs.CurrentShooterIndex, gs.CurrentRound)
	}

	gs.AdvanceTurn() // → 2
	if gs.CurrentShooterIndex != 2 || gs.CurrentRound != 1 {
		t.Errorf("after 2nd advance: idx=%d round=%d", gs.CurrentShooterIndex, gs.CurrentRound)
	}

	gs.AdvanceTurn() // → 0, round 1→2
	if gs.CurrentShooterIndex != 0 || gs.CurrentRound != 2 {
		t.Errorf("after wrap: idx=%d round=%d, expected idx=0 round=2", gs.CurrentShooterIndex, gs.CurrentRound)
	}
}

func TestIsGameOver(t *testing.T) {
	gs := &GameState{
		RoundCount:   3,
		CurrentRound: 3,
		TurnOrder:    []string{"a", "b"},
		GamePhase:    PhasePlaying,
	}

	if gs.IsGameOver() {
		t.Error("should not be game over at round 3 of 3")
	}

	gs.CurrentRound = 4
	if !gs.IsGameOver() {
		t.Error("should be game over when currentRound > roundCount")
	}
}

func TestUndoLastShot(t *testing.T) {
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter", "other"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: 2},
			"other":   {DeviceIDHash: "other", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	// Process a shot (streak 2→3, bonus +2, total 5 points).
	_, err := gs.ProcessShot("shooter", "made")
	if err != nil {
		t.Fatalf("ProcessShot error: %v", err)
	}

	// Verify state changed.
	if gs.Players["shooter"].Score != 5 {
		t.Fatalf("expected score=5 after shot, got %d", gs.Players["shooter"].Score)
	}
	if gs.Players["shooter"].Streak != 3 {
		t.Fatalf("expected streak=3 after shot, got %d", gs.Players["shooter"].Streak)
	}

	// Undo.
	if err := gs.UndoLastShot(); err != nil {
		t.Fatalf("UndoLastShot error: %v", err)
	}

	if gs.Players["shooter"].Score != 0 {
		t.Errorf("expected score=0 after undo, got %d", gs.Players["shooter"].Score)
	}
	if gs.Players["shooter"].Streak != 2 {
		t.Errorf("expected streak=2 after undo, got %d", gs.Players["shooter"].Streak)
	}
	if gs.CurrentShooterDeviceIDHash() != "shooter" {
		t.Errorf("expected current shooter reverted to 'shooter', got %q", gs.CurrentShooterDeviceIDHash())
	}
}

func TestUndoLastShot_NoShotToUndo(t *testing.T) {
	gs := newTestGameState()
	err := gs.UndoLastShot()
	if err == nil {
		t.Error("expected error when no shot to undo")
	}
}

func TestProcessShot_InvalidResult(t *testing.T) {
	gs := newTestGameState()
	shooter := gs.CurrentShooterDeviceIDHash()

	_, err := gs.ProcessShot(shooter, "invalid")
	if err == nil {
		t.Error("expected error for invalid result")
	}
}

func TestProcessShot_WrongShooter(t *testing.T) {
	gs := newTestGameState()

	_, err := gs.ProcessShot("wrong-hash", "made")
	if err == nil {
		t.Error("expected error for wrong shooter")
	}
}

func TestProcessShot_GameNotPlaying(t *testing.T) {
	gs := newTestGameState()
	gs.GamePhase = PhaseEnded

	_, err := gs.ProcessShot(gs.CurrentShooterDeviceIDHash(), "made")
	if err == nil {
		t.Error("expected error when game phase is ended")
	}
}

func TestProcessShot_RoundIncrementOnWrap(t *testing.T) {
	gs := newTestGameState() // 3 players, 3 rounds
	// Process 3 shots to complete round 1.
	for i := 0; i < 3; i++ {
		shooter := gs.CurrentShooterDeviceIDHash()
		_, err := gs.ProcessShot(shooter, "missed")
		if err != nil {
			t.Fatalf("shot %d error: %v", i, err)
		}
	}
	if gs.CurrentRound != 2 {
		t.Errorf("expected round 2 after all players shot, got %d", gs.CurrentRound)
	}
}

func TestProcessShot_GameOverAfterFinalRound(t *testing.T) {
	gs := &GameState{
		RoundCount:          1,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"a"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"a": {DeviceIDHash: "a", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	result, err := gs.ProcessShot("a", "made")
	if err != nil {
		t.Fatalf("error: %v", err)
	}
	if !result.IsGameOver {
		t.Error("expected game over after final round")
	}
}

func TestUndoLastShot_RevertsGamePhaseAfterGameOver(t *testing.T) {
	gs := &GameState{
		RoundCount:          1,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"a"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"a": {DeviceIDHash: "a", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	result, err := gs.ProcessShot("a", "made")
	if err != nil {
		t.Fatalf("ProcessShot error: %v", err)
	}
	if !result.IsGameOver {
		t.Fatal("expected game over")
	}

	// Simulate server setting phase to ended.
	gs.GamePhase = PhaseEnded

	// Undo should revert phase back to playing.
	if err := gs.UndoLastShot(); err != nil {
		t.Fatalf("UndoLastShot error: %v", err)
	}
	if gs.GamePhase != PhasePlaying {
		t.Errorf("expected GamePhase=%q after undo, got %q", PhasePlaying, gs.GamePhase)
	}
	if gs.Players["a"].Score != 0 {
		t.Errorf("expected score=0 after undo, got %d", gs.Players["a"].Score)
	}

	// Should be able to process another shot.
	_, err = gs.ProcessShot("a", "missed")
	if err != nil {
		t.Errorf("expected ProcessShot to succeed after undo, got: %v", err)
	}
}

// --- IsTriplePoints ---

func TestIsTriplePoints_BoundaryDetection(t *testing.T) {
	tests := []struct {
		name         string
		roundCount   int
		currentRound int
		want         bool
	}{
		// 10 rounds: R8=true, R7=false
		{"10 rounds, R7 not triple", 10, 7, false},
		{"10 rounds, R8 triple", 10, 8, true},
		{"10 rounds, R9 triple", 10, 9, true},
		{"10 rounds, R10 triple", 10, 10, true},
		// 5 rounds: R3=true, R2=false
		{"5 rounds, R2 not triple", 5, 2, false},
		{"5 rounds, R3 triple", 5, 3, true},
		{"5 rounds, R5 triple", 5, 5, true},
		// 15 rounds: R13=true, R12=false
		{"15 rounds, R12 not triple", 15, 12, false},
		{"15 rounds, R13 triple", 15, 13, true},
		// 3 rounds: ALL rounds triple
		{"3 rounds, R1 triple", 3, 1, true},
		{"3 rounds, R2 triple", 3, 2, true},
		{"3 rounds, R3 triple", 3, 3, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gs := &GameState{
				RoundCount:   tt.roundCount,
				CurrentRound: tt.currentRound,
			}
			if got := gs.IsTriplePoints(); got != tt.want {
				t.Errorf("IsTriplePoints() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestProcessShot_TriplePointScoring(t *testing.T) {
	tests := []struct {
		name           string
		roundCount     int
		currentRound   int
		streak         int
		expectedPoints int
		desc           string
	}{
		// Normal scoring (not triple)
		{"normal base", 10, 5, 0, 3, "base 3 pts"},
		{"normal streak2", 10, 5, 1, 4, "base 3 + streak bonus 1"},
		// Triple scoring: 3x everything
		{"triple base", 10, 8, 0, 9, "3x base (3*3=9)"},
		{"triple streak2", 10, 8, 1, 12, "(3+1)*3=12"},
		{"triple streak3", 10, 8, 2, 15, "(3+2)*3=15"},
		{"triple streak4", 10, 8, 3, 18, "(3+3)*3=18"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gs := &GameState{
				RoundCount:          tt.roundCount,
				CurrentRound:        tt.currentRound,
				RefereeDeviceIDHash: "ref",
				TurnOrder:           []string{"shooter"},
				CurrentShooterIndex: 0,
				Players: map[string]*GamePlayer{
					"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: tt.streak},
				},
				GamePhase: PhasePlaying,
			}

			result, err := gs.ProcessShot("shooter", "made")
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if result.PointsAwarded != tt.expectedPoints {
				t.Errorf("expected %d points (%s), got %d", tt.expectedPoints, tt.desc, result.PointsAwarded)
			}
		})
	}
}

func TestProcessShot_TriplePointsFieldOnTurnResult(t *testing.T) {
	// In triple territory — result.IsTriplePoints should be true.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        8,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	result, err := gs.ProcessShot("shooter", "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// After AdvanceTurn, CurrentRound becomes 9 (still triple).
	if !result.IsTriplePoints {
		t.Error("expected IsTriplePoints=true in final 3 rounds")
	}

	// Not in triple territory.
	gs2 := &GameState{
		RoundCount:          10,
		CurrentRound:        5,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	result2, err := gs2.ProcessShot("shooter", "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result2.IsTriplePoints {
		t.Error("expected IsTriplePoints=false outside final 3 rounds")
	}
}

func TestLastShotTime_SetOnProcessShot(t *testing.T) {
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        1,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"s"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"s": {DeviceIDHash: "s", Score: 0, Streak: 0},
		},
		GamePhase: PhasePlaying,
	}

	before := time.Now()
	_, _ = gs.ProcessShot("s", "made")
	after := time.Now()

	if gs.LastShotTime.Before(before) || gs.LastShotTime.After(after) {
		t.Error("LastShotTime not set correctly")
	}
}
