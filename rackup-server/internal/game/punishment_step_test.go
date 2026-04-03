package game

import "testing"

func TestPunishmentStep_MissedDrawsPunishment(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{
		RoundCount:   10,
		CurrentRound: 2, // 20% → mild
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
		},
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.Punishment == "" {
		t.Error("expected punishment text for missed shot")
	}
	if ctx.PunishmentTier == "" {
		t.Error("expected punishment tier for missed shot")
	}
}

func TestPunishmentStep_MadeSkipsPunishment(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{
		RoundCount:   10,
		CurrentRound: 2,
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
		},
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "made",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.Punishment != "" {
		t.Errorf("expected no punishment for made shot, got %q", ctx.Punishment)
	}
	if ctx.PunishmentTier != "" {
		t.Errorf("expected no tier for made shot, got %q", ctx.PunishmentTier)
	}
}

func TestPunishmentStep_TierCalculation(t *testing.T) {
	tests := []struct {
		name         string
		currentRound int
		totalRounds  int
		wantTierIn   []string
	}{
		{"mild_early", 1, 10, []string{TierMild, TierCustom}},
		{"medium_mid", 5, 10, []string{TierMedium, TierCustom}},
		{"spicy_late", 9, 10, []string{TierSpicy, TierCustom}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			deck := NewPunishmentDeck(nil)
			step := &PunishmentStep{Deck: deck}

			gs := &GameState{
				RoundCount:   tt.totalRounds,
				CurrentRound: tt.currentRound,
				Players: map[string]*GamePlayer{
					"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
				},
			}

			ctx := &ChainContext{
				ShooterHash:    "shooter",
				ShotResult:     "missed",
				CascadeProfile: "routine",
				gameState:      gs,
			}

			if err := step.Execute(ctx); err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			found := false
			for _, allowed := range tt.wantTierIn {
				if ctx.PunishmentTier == allowed {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("tier %q not in allowed set %v", ctx.PunishmentTier, tt.wantTierIn)
			}
		})
	}
}

func TestPunishmentStep_CascadeUpgradeMild(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{RoundCount: 10, CurrentRound: 1} // mild

	ctx := &ChainContext{
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step.Execute(ctx)
	// Mild → streak_milestone (priority 1 > routine 0).
	if ctx.CascadeProfile != "streak_milestone" {
		t.Errorf("expected cascade 'streak_milestone', got %q", ctx.CascadeProfile)
	}
}

func TestPunishmentStep_CascadeUpgradeMedium(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{RoundCount: 10, CurrentRound: 5} // medium

	ctx := &ChainContext{
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step.Execute(ctx)
	if ctx.CascadeProfile != "item_punishment" {
		t.Errorf("expected cascade 'item_punishment', got %q", ctx.CascadeProfile)
	}
}

func TestPunishmentStep_CascadeUpgradeSpicy(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{RoundCount: 10, CurrentRound: 9} // spicy

	ctx := &ChainContext{
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step.Execute(ctx)
	if ctx.CascadeProfile != "spicy" {
		t.Errorf("expected cascade 'spicy', got %q", ctx.CascadeProfile)
	}
}

func TestPunishmentStep_NeverDowngradeCascade(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	step := &PunishmentStep{Deck: deck}

	gs := &GameState{RoundCount: 10, CurrentRound: 1} // mild → streak_milestone

	ctx := &ChainContext{
		ShotResult:     "missed",
		CascadeProfile: "record_this", // already highest
		gameState:      gs,
	}

	step.Execute(ctx)
	if ctx.CascadeProfile != "record_this" {
		t.Errorf("cascade should not downgrade from record_this, got %q", ctx.CascadeProfile)
	}
}

func TestPunishmentStep_CustomPunishmentTierTag(t *testing.T) {
	// Create deck with ONLY a custom punishment in mild to guarantee drawing it.
	deck := &PunishmentDeck{
		pools: map[string][]string{
			TierMild:   {"My custom one"},
			TierMedium: {},
			TierSpicy:  {},
		},
		recent: make([]string, 0, recentListSize),
	}

	step := &PunishmentStep{Deck: deck}
	gs := &GameState{RoundCount: 10, CurrentRound: 1}

	ctx := &ChainContext{
		ShotResult:     "missed",
		CascadeProfile: "routine",
		gameState:      gs,
	}

	step.Execute(ctx)
	if ctx.PunishmentTier != TierCustom {
		t.Errorf("expected tier %q for custom punishment, got %q", TierCustom, ctx.PunishmentTier)
	}
}
