package game

import (
	"math/rand"
	"testing"
)

func TestItemDropStep_SkipsOnMadeShot(t *testing.T) {
	step := &ItemDropStep{}
	gs := &GameState{
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
		},
	}

	ctx := &ChainContext{
		ShooterHash:    "shooter",
		ShotResult:     "made",
		CascadeProfile: "routine",
		PreviousLeaderboard: []LeaderboardEntry{
			{DeviceIDHash: "shooter", Rank: 1},
		},
		gameState: gs,
	}

	if err := step.Execute(ctx); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.ItemDrop != nil {
		t.Error("expected no item drop on made shot")
	}
	if gs.Players["shooter"].HeldItem != nil {
		t.Error("expected no HeldItem on made shot")
	}
}

func TestItemDropStep_50PercentProbability(t *testing.T) {
	// Seed random for reproducibility. Run 1000 trials and verify ~50% drop rate.
	rand.Seed(42)
	dropCount := 0
	trials := 1000

	for i := 0; i < trials; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "shooter",
			ShotResult:     "missed",
			CascadeProfile: "routine",
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "shooter", Rank: 1},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil {
			dropCount++
		}
	}

	rate := float64(dropCount) / float64(trials)
	if rate < 0.35 || rate > 0.65 {
		t.Errorf("drop rate %.2f outside expected range [0.35, 0.65]", rate)
	}
}

func TestItemDropStep_AssignsItemToPlayer(t *testing.T) {
	// Force item drop by running until we get one.
	for i := 0; i < 100; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "shooter",
			ShotResult:     "missed",
			CascadeProfile: "routine",
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "shooter", Rank: 1},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil {
			if gs.Players["shooter"].HeldItem == nil {
				t.Error("expected HeldItem to be set after item drop")
			}
			if *gs.Players["shooter"].HeldItem != ctx.ItemDrop.ItemType {
				t.Errorf("HeldItem %q != ItemDrop.ItemType %q", *gs.Players["shooter"].HeldItem, ctx.ItemDrop.ItemType)
			}
			if ctx.ItemDrop.ReplacedItem != nil {
				t.Error("expected no replaced item on first drop")
			}
			return
		}
	}
	t.Error("expected at least one item drop in 100 tries")
}

func TestItemDropStep_UseItOrLoseItReplacement(t *testing.T) {
	oldItem := ItemShield
	for i := 0; i < 100; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex", HeldItem: &oldItem},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "shooter",
			ShotResult:     "missed",
			CascadeProfile: "routine",
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "shooter", Rank: 1},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil {
			if ctx.ItemDrop.ReplacedItem == nil {
				t.Error("expected ReplacedItem to be set when replacing existing item")
				return
			}
			if *ctx.ItemDrop.ReplacedItem != ItemShield {
				t.Errorf("expected ReplacedItem %q, got %q", ItemShield, *ctx.ItemDrop.ReplacedItem)
			}
			return
		}
	}
	t.Error("expected at least one item drop in 100 tries")
}

func TestItemDropStep_CascadeUpgradeToItemPunishment(t *testing.T) {
	for i := 0; i < 100; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "shooter",
			ShotResult:     "missed",
			CascadeProfile: "routine", // priority 0
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "shooter", Rank: 1},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil {
			if ctx.CascadeProfile != "item_punishment" {
				t.Errorf("expected cascade 'item_punishment', got %q", ctx.CascadeProfile)
			}
			return
		}
	}
	t.Error("expected at least one item drop in 100 tries")
}

func TestItemDropStep_NeverDowngradeCascade(t *testing.T) {
	for i := 0; i < 100; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex"},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "shooter",
			ShotResult:     "missed",
			CascadeProfile: "spicy", // priority 4 > item_punishment 3
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "shooter", Rank: 1},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil {
			if ctx.CascadeProfile != "spicy" {
				t.Errorf("cascade should not downgrade from spicy, got %q", ctx.CascadeProfile)
			}
			return
		}
	}
	t.Error("expected at least one item drop in 100 tries")
}

func TestItemDropStep_FirstPlaceNoBlueshell(t *testing.T) {
	for i := 0; i < 500; i++ {
		step := &ItemDropStep{}
		gs := &GameState{
			Players: map[string]*GamePlayer{
				"first": {DeviceIDHash: "first", DisplayName: "Leader"},
				"last":  {DeviceIDHash: "last", DisplayName: "Lagging"},
			},
		}

		ctx := &ChainContext{
			ShooterHash:    "first",
			ShotResult:     "missed",
			CascadeProfile: "routine",
			PreviousLeaderboard: []LeaderboardEntry{
				{DeviceIDHash: "first", Rank: 1},
				{DeviceIDHash: "last", Rank: 2},
			},
			gameState: gs,
		}

		step.Execute(ctx)
		if ctx.ItemDrop != nil && ctx.ItemDrop.ItemType == ItemBlueshell {
			t.Fatal("first place should never get Blue Shell")
		}
	}
}

// Integration: full consequence chain with ItemDropStep plugged in.
func TestConsequenceChain_WithItemDropStep_MissedShot(t *testing.T) {
	// Run multiple times to get at least one item drop.
	gotDrop := false
	for i := 0; i < 50; i++ {
		gs := &GameState{
			RoundCount:   10,
			CurrentRound: 2,
			TurnOrder:    []string{"shooter", "other"},
			Players: map[string]*GamePlayer{
				"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex", Slot: 1},
				"other":   {DeviceIDHash: "other", DisplayName: "Bob", Slot: 2, IsReferee: true},
			},
			GamePhase:           PhasePlaying,
			CurrentShooterIndex: 0,
		}

		chain := NewConsequenceChain()
		chain.ReplaceStep("punishment_slot", &PunishmentStep{Deck: NewPunishmentDeck(nil)})
		chain.ReplaceStep("item_drop_slot", &ItemDropStep{})

		ctx, err := chain.Run(gs, "shooter", "missed")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if ctx.ItemDrop != nil {
			gotDrop = true
			break
		}
	}
	if !gotDrop {
		t.Error("expected at least one item drop in 50 missed-shot runs")
	}
}

func TestConsequenceChain_WithItemDropStep_MadeShot(t *testing.T) {
	gs := &GameState{
		RoundCount:   10,
		CurrentRound: 2,
		TurnOrder:    []string{"shooter", "other"},
		Players: map[string]*GamePlayer{
			"shooter": {DeviceIDHash: "shooter", DisplayName: "Alex", Slot: 1},
			"other":   {DeviceIDHash: "other", DisplayName: "Bob", Slot: 2, IsReferee: true},
		},
		GamePhase:           PhasePlaying,
		CurrentShooterIndex: 0,
	}

	chain := NewConsequenceChain()
	chain.ReplaceStep("item_drop_slot", &ItemDropStep{})

	ctx, err := chain.Run(gs, "shooter", "made")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if ctx.ItemDrop != nil {
		t.Error("expected no item drop on made shot")
	}
}
