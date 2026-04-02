package game

import (
	"testing"
)

// --- Helper ---

func setupThreePlayerGame() *GameState {
	players := map[string]string{
		"host": "Host",
		"p2":   "Player2",
		"p3":   "Player3",
	}
	slots := map[string]int{
		"host": 1,
		"p2":   2,
		"p3":   3,
	}
	return NewGameState(players, slots, 5, "host")
}

// --- ConsequenceChain step ordering ---

func TestConsequenceChain_StepOrder(t *testing.T) {
	chain := NewConsequenceChain()
	expected := []string{
		"shot_result",
		"streak_update",
		"punishment_slot",
		"item_drop_slot",
		"mission_check_slot",
		"score_update",
		"leaderboard_recalc",
		"ui_events",
		"sound_triggers",
		"record_this_check_slot",
	}
	names := chain.StepNames()
	if len(names) != len(expected) {
		t.Fatalf("expected %d steps, got %d", len(expected), len(names))
	}
	for i, name := range names {
		if name != expected[i] {
			t.Errorf("step %d: expected %q, got %q", i, expected[i], name)
		}
	}
}

// --- ConsequenceChain Run ---

func TestConsequenceChain_Run_MadeShot(t *testing.T) {
	gs := setupThreePlayerGame()
	chain := NewConsequenceChain()

	// First shooter is turn order[0]. Referee is p2 (first non-host in 3+ player game).
	shooter := gs.CurrentShooterDeviceIDHash()

	ctx, err := chain.Run(gs, shooter, "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Verify turn result.
	if ctx.TurnResult == nil {
		t.Fatal("TurnResult should not be nil")
	}
	if ctx.TurnResult.PointsAwarded != 3 {
		t.Errorf("expected 3 points, got %d", ctx.TurnResult.PointsAwarded)
	}
	if ctx.TurnResult.NewStreak != 1 {
		t.Errorf("expected streak 1, got %d", ctx.TurnResult.NewStreak)
	}

	// Streak label should be empty for streak=1.
	if ctx.StreakLabel != "" {
		t.Errorf("expected empty streak label, got %q", ctx.StreakLabel)
	}
	if ctx.StreakMilestone {
		t.Error("expected no milestone for streak=1")
	}

	// Cascade profile should be routine.
	if ctx.CascadeProfile != "routine" {
		t.Errorf("expected cascade profile 'routine', got %q", ctx.CascadeProfile)
	}

	// Leaderboard should be populated.
	if len(ctx.Leaderboard) == 0 {
		t.Error("leaderboard should not be empty")
	}
}

func TestConsequenceChain_Run_MissedShot(t *testing.T) {
	gs := setupThreePlayerGame()
	chain := NewConsequenceChain()

	shooter := gs.CurrentShooterDeviceIDHash()

	ctx, err := chain.Run(gs, shooter, "missed")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.TurnResult.PointsAwarded != 0 {
		t.Errorf("expected 0 points, got %d", ctx.TurnResult.PointsAwarded)
	}
	if ctx.TurnResult.NewStreak != 0 {
		t.Errorf("expected streak 0, got %d", ctx.TurnResult.NewStreak)
	}
	if ctx.StreakLabel != "" {
		t.Errorf("expected empty streak label, got %q", ctx.StreakLabel)
	}
	if ctx.CascadeProfile != "routine" {
		t.Errorf("expected cascade profile 'routine', got %q", ctx.CascadeProfile)
	}
}

func TestConsequenceChain_Run_StreakMilestones(t *testing.T) {
	gs := setupThreePlayerGame()
	chain := NewConsequenceChain()

	// Make shots to build streak. Each run advances the turn,
	// so we need to cycle through all players to get back to the first shooter.
	shooter := gs.CurrentShooterDeviceIDHash()

	// Shot 1: streak=1, no milestone.
	ctx, _ := chain.Run(gs, shooter, "made")
	if ctx.StreakLabel != "" || ctx.StreakMilestone {
		t.Error("streak=1: expected no label, no milestone")
	}

	// Advance other players' turns (miss).
	for i := 0; i < len(gs.TurnOrder)-1; i++ {
		current := gs.CurrentShooterDeviceIDHash()
		chain.Run(gs, current, "missed")
	}

	// Shot 2: streak=2, warming_up milestone.
	ctx, _ = chain.Run(gs, shooter, "made")
	if ctx.StreakLabel != "warming_up" {
		t.Errorf("streak=2: expected 'warming_up', got %q", ctx.StreakLabel)
	}
	if !ctx.StreakMilestone {
		t.Error("streak=2: expected milestone=true")
	}
	if ctx.CascadeProfile != "streak_milestone" {
		t.Errorf("streak=2: expected cascade profile 'streak_milestone', got %q", ctx.CascadeProfile)
	}

	// Advance other players.
	for i := 0; i < len(gs.TurnOrder)-1; i++ {
		current := gs.CurrentShooterDeviceIDHash()
		chain.Run(gs, current, "missed")
	}

	// Shot 3: streak=3, on_fire milestone.
	ctx, _ = chain.Run(gs, shooter, "made")
	if ctx.StreakLabel != "on_fire" {
		t.Errorf("streak=3: expected 'on_fire', got %q", ctx.StreakLabel)
	}
	if !ctx.StreakMilestone {
		t.Error("streak=3: expected milestone=true")
	}

	// Advance other players.
	for i := 0; i < len(gs.TurnOrder)-1; i++ {
		current := gs.CurrentShooterDeviceIDHash()
		chain.Run(gs, current, "missed")
	}

	// Shot 4: streak=4, unstoppable milestone.
	ctx, _ = chain.Run(gs, shooter, "made")
	if ctx.StreakLabel != "unstoppable" {
		t.Errorf("streak=4: expected 'unstoppable', got %q", ctx.StreakLabel)
	}
	if !ctx.StreakMilestone {
		t.Error("streak=4: expected milestone=true")
	}

	// Advance other players.
	for i := 0; i < len(gs.TurnOrder)-1; i++ {
		current := gs.CurrentShooterDeviceIDHash()
		chain.Run(gs, current, "missed")
	}

	// Shot 5: streak=5, still unstoppable but NO milestone (already past threshold).
	ctx, _ = chain.Run(gs, shooter, "made")
	if ctx.StreakLabel != "unstoppable" {
		t.Errorf("streak=5: expected 'unstoppable', got %q", ctx.StreakLabel)
	}
	if ctx.StreakMilestone {
		t.Error("streak=5: expected milestone=false (not a threshold crossing)")
	}
}

func TestConsequenceChain_Run_ErrorPropagation(t *testing.T) {
	gs := setupThreePlayerGame()
	chain := NewConsequenceChain()

	// Wrong shooter should error.
	_, err := chain.Run(gs, "wrong_player", "made")
	if err == nil {
		t.Error("expected error for wrong shooter")
	}
}

// --- ReplaceStep ---

type recordingStep struct {
	called bool
}

func (r *recordingStep) Execute(ctx *ChainContext) error {
	r.called = true
	return nil
}

func TestConsequenceChain_ReplaceStep(t *testing.T) {
	chain := NewConsequenceChain()
	step := &recordingStep{}
	chain.ReplaceStep("punishment_slot", step)

	gs := setupThreePlayerGame()
	shooter := gs.CurrentShooterDeviceIDHash()
	_, err := chain.Run(gs, shooter, "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !step.called {
		t.Error("replacement step was not called")
	}
}

// --- StreakLabel ---

func TestStreakLabel(t *testing.T) {
	tests := []struct {
		streak int
		want   string
	}{
		{0, ""},
		{1, ""},
		{2, "warming_up"},
		{3, "on_fire"},
		{4, "unstoppable"},
		{5, "unstoppable"},
		{10, "unstoppable"},
	}
	for _, tt := range tests {
		got := StreakLabel(tt.streak)
		if got != tt.want {
			t.Errorf("StreakLabel(%d) = %q, want %q", tt.streak, got, tt.want)
		}
	}
}

// --- CalculateLeaderboard ---

func TestCalculateLeaderboard_SortingAndRank(t *testing.T) {
	gs := setupThreePlayerGame()

	// Set scores: host=10, p2 is referee (excluded), p3=5.
	gs.Players["host"].Score = 10
	gs.Players["p3"].Score = 5

	lb := gs.CalculateLeaderboard(nil)
	// Referee (p2) is excluded, so only 2 entries.
	if len(lb) != 2 {
		t.Fatalf("expected 2 entries (referee excluded), got %d", len(lb))
	}

	// First should be host (score 10).
	if lb[0].DeviceIDHash != "host" || lb[0].Rank != 1 {
		t.Errorf("rank 1: expected host, got %s rank %d", lb[0].DeviceIDHash, lb[0].Rank)
	}
	if lb[0].DisplayName != "Host" {
		t.Errorf("expected DisplayName 'Host', got %q", lb[0].DisplayName)
	}
	// Second should be p3 (score 5).
	if lb[1].DeviceIDHash != "p3" || lb[1].Rank != 2 {
		t.Errorf("rank 2: expected p3, got %s rank %d", lb[1].DeviceIDHash, lb[1].Rank)
	}
}

func TestCalculateLeaderboard_TieHandling(t *testing.T) {
	gs := setupThreePlayerGame()

	// Non-referee players tied at 6 points. p2 is referee (excluded).
	gs.Players["host"].Score = 6
	gs.Players["p3"].Score = 6

	lb := gs.CalculateLeaderboard(nil)

	if len(lb) != 2 {
		t.Fatalf("expected 2 entries (referee excluded), got %d", len(lb))
	}

	// Both should have rank 1 (tied).
	for _, entry := range lb {
		if entry.Rank != 1 {
			t.Errorf("tied players: %s expected rank 1, got %d", entry.DeviceIDHash, entry.Rank)
		}
	}

	// Should be sorted by slot ascending (host=1, p3=3).
	if lb[0].DeviceIDHash != "host" {
		t.Errorf("expected host first (slot 1), got %s", lb[0].DeviceIDHash)
	}
}

func TestCalculateLeaderboard_IncludesStreak(t *testing.T) {
	gs := setupThreePlayerGame()
	gs.Players["host"].Score = 10
	gs.Players["host"].Streak = 3

	lb := gs.CalculateLeaderboard(nil)
	for _, entry := range lb {
		if entry.DeviceIDHash == "host" {
			if entry.Streak != 3 {
				t.Errorf("expected streak 3 for host, got %d", entry.Streak)
			}
		}
	}
}

func TestCalculateLeaderboard_RankChanged(t *testing.T) {
	gs := setupThreePlayerGame()

	// Initial: host=0, p3=0.
	prev := gs.CalculateLeaderboard(nil)

	// Host scores, now host=10, p3=0.
	gs.Players["host"].Score = 10
	lb := gs.CalculateLeaderboard(prev)

	for _, entry := range lb {
		if entry.DeviceIDHash == "host" {
			if entry.RankChanged {
				t.Error("host was already rank 1, RankChanged should be false")
			}
		}
	}

	// Now p3 overtakes host.
	gs.Players["p3"].Score = 20
	prev = lb
	lb = gs.CalculateLeaderboard(prev)

	for _, entry := range lb {
		if entry.DeviceIDHash == "p3" && !entry.RankChanged {
			t.Error("p3 moved to rank 1, RankChanged should be true")
		}
		if entry.DeviceIDHash == "host" && !entry.RankChanged {
			t.Error("host moved to rank 2, RankChanged should be true")
		}
	}
}

func TestCalculateLeaderboard_StreakLabel(t *testing.T) {
	gs := setupThreePlayerGame()
	gs.Players["host"].Streak = 3

	lb := gs.CalculateLeaderboard(nil)
	for _, entry := range lb {
		if entry.DeviceIDHash == "host" {
			if entry.StreakLabel != "on_fire" {
				t.Errorf("expected StreakLabel 'on_fire' for streak 3, got %q", entry.StreakLabel)
			}
		}
		if entry.DeviceIDHash == "p3" {
			if entry.StreakLabel != "" {
				t.Errorf("expected empty StreakLabel for streak 0, got %q", entry.StreakLabel)
			}
		}
	}
}

func TestCalculateLeaderboard_ExcludesReferee(t *testing.T) {
	gs := setupThreePlayerGame()

	lb := gs.CalculateLeaderboard(nil)
	for _, entry := range lb {
		if entry.DeviceIDHash == "p2" {
			t.Error("referee (p2) should be excluded from leaderboard")
		}
	}
}

// --- Chain context passing ---

func TestConsequenceChain_ContextFlowsThroughSteps(t *testing.T) {
	gs := setupThreePlayerGame()
	chain := NewConsequenceChain()

	shooter := gs.CurrentShooterDeviceIDHash()
	ctx, err := chain.Run(gs, shooter, "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// All fields should be populated.
	if ctx.ShooterHash != shooter {
		t.Errorf("expected ShooterHash=%s, got %s", shooter, ctx.ShooterHash)
	}
	if ctx.ShotResult != "made" {
		t.Errorf("expected ShotResult=made, got %s", ctx.ShotResult)
	}
	if ctx.TurnResult == nil {
		t.Fatal("TurnResult should be set by shot_result step")
	}
	if len(ctx.Leaderboard) == 0 {
		t.Error("Leaderboard should be set by leaderboard_recalc step")
	}
}
