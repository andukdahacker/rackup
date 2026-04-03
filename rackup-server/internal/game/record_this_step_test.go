package game

import "testing"

// --- RecordThisCheckStep ---

func TestRecordThisCheckStep_StreakBreakTriggers(t *testing.T) {
	// Streak of 4 (unstoppable) + missed shot → should trigger.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex", Score: 20, Streak: 0},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 4,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !ctx.RecordThis {
		t.Error("expected RecordThis=true for streak break (4→0)")
	}
	if ctx.TargetPlayerHash != "shooter" {
		t.Errorf("expected TargetPlayerHash='shooter', got %q", ctx.TargetPlayerHash)
	}
	if ctx.RecordThisSubtext != "Alex's streak just got broken!" {
		t.Errorf("unexpected subtext: %q", ctx.RecordThisSubtext)
	}
	if ctx.CascadeProfile != "record_this" {
		t.Errorf("expected CascadeProfile='record_this', got %q", ctx.CascadeProfile)
	}
}

func TestRecordThisCheckStep_HigherStreakTriggers(t *testing.T) {
	// Streak of 7 + missed → should trigger (>= 4).
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Kim", Score: 50, Streak: 0},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 7,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !ctx.RecordThis {
		t.Error("expected RecordThis=true for streak break (7→0)")
	}
}

func TestRecordThisCheckStep_NoTrigger_StreakTooLow(t *testing.T) {
	// Streak of 3 + missed → should NOT trigger (< 4).
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Pat", Score: 10, Streak: 0},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 3,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.RecordThis {
		t.Error("expected RecordThis=false for streak < 4")
	}
	if ctx.CascadeProfile != "routine" {
		t.Errorf("expected CascadeProfile unchanged ('routine'), got %q", ctx.CascadeProfile)
	}
}

func TestRecordThisCheckStep_NoTrigger_MadeShot(t *testing.T) {
	// Streak of 4 + made shot → should NOT trigger.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Sam", Score: 20, Streak: 5},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 4,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "made",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.RecordThis {
		t.Error("expected RecordThis=false for made shot")
	}
}

func TestRecordThisCheckStep_OverridesCascadeProfile(t *testing.T) {
	// Even if cascade is already "streak_milestone", record_this should override.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Dana", Score: 30, Streak: 0},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 5,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "streak_milestone",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.CascadeProfile != "record_this" {
		t.Errorf("expected record_this to override streak_milestone, got %q", ctx.CascadeProfile)
	}
}

func TestRecordThisCheckStep_NoTrigger_ZeroStreak(t *testing.T) {
	// No streak at all + missed → should NOT trigger.
	gs := &GameState{
		RoundCount:          10,
		CurrentRound:        3,
		RefereeDeviceIDHash: "ref",
		TurnOrder:           []string{"shooter"},
		CurrentShooterIndex: 0,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Jo", Score: 0, Streak: 0},
		},
		GamePhase:       PhasePlaying,
		lastStreakBefore: 0,
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step := &RecordThisCheckStep{}
	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.RecordThis {
		t.Error("expected RecordThis=false for zero streak")
	}
}
