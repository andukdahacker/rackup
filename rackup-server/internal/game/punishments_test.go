package game

import (
	"testing"
)

func TestNewPunishmentDeck_BuiltInPunishments(t *testing.T) {
	deck := NewPunishmentDeck(nil)

	if deck.PoolSize(TierMild) != len(builtInMild) {
		t.Errorf("mild pool: got %d, want %d", deck.PoolSize(TierMild), len(builtInMild))
	}
	if deck.PoolSize(TierMedium) != len(builtInMedium) {
		t.Errorf("medium pool: got %d, want %d", deck.PoolSize(TierMedium), len(builtInMedium))
	}
	if deck.PoolSize(TierSpicy) != len(builtInSpicy) {
		t.Errorf("spicy pool: got %d, want %d", deck.PoolSize(TierSpicy), len(builtInSpicy))
	}
}

func TestNewPunishmentDeck_CustomPunishmentsMixedIntoAllTiers(t *testing.T) {
	customs := []string{"Custom A", "Custom B"}
	deck := NewPunishmentDeck(customs)

	// Each tier should have built-ins + 2 customs.
	if deck.PoolSize(TierMild) != len(builtInMild)+2 {
		t.Errorf("mild pool: got %d, want %d", deck.PoolSize(TierMild), len(builtInMild)+2)
	}
	if deck.PoolSize(TierMedium) != len(builtInMedium)+2 {
		t.Errorf("medium pool: got %d, want %d", deck.PoolSize(TierMedium), len(builtInMedium)+2)
	}
	if deck.PoolSize(TierSpicy) != len(builtInSpicy)+2 {
		t.Errorf("spicy pool: got %d, want %d", deck.PoolSize(TierSpicy), len(builtInSpicy)+2)
	}
}

func TestNewPunishmentDeck_EmptyCustomList(t *testing.T) {
	deck := NewPunishmentDeck([]string{})
	if deck.PoolSize(TierMild) != len(builtInMild) {
		t.Errorf("mild pool: got %d, want %d", deck.PoolSize(TierMild), len(builtInMild))
	}
}

func TestDraw_ReturnsPunishmentFromTier(t *testing.T) {
	deck := NewPunishmentDeck(nil)

	text, tier := deck.Draw(TierMild)
	if text == "" {
		t.Error("expected non-empty punishment text")
	}
	if tier != TierMild {
		t.Errorf("expected tier %q, got %q", TierMild, tier)
	}
}

func TestDraw_CustomPunishmentGetCustomTier(t *testing.T) {
	customs := []string{"My custom punishment"}
	deck := NewPunishmentDeck(customs)

	// Draw many times to eventually get the custom one.
	foundCustom := false
	for i := 0; i < 100; i++ {
		text, tier := deck.Draw(TierMild)
		if text == "My custom punishment" {
			if tier != TierCustom {
				t.Errorf("custom punishment should have tier %q, got %q", TierCustom, tier)
			}
			foundCustom = true
			break
		}
	}
	if !foundCustom {
		t.Error("expected to draw custom punishment within 100 draws")
	}
}

func TestDraw_DeprioritizesRecentlyDrawn(t *testing.T) {
	// Create deck with only 2 mild punishments to test deprioritization.
	deck := &PunishmentDeck{
		pools: map[string][]string{
			TierMild:   {"A", "B"},
			TierMedium: {"C"},
			TierSpicy:  {"D"},
		},
		recent: make([]string, 0, recentListSize),
	}

	// Draw "A" first (we'll force it by drawing until we get it).
	// Then the next draw should prefer "B".
	first, _ := deck.Draw(TierMild)
	second, _ := deck.Draw(TierMild)
	if first == second {
		t.Error("second draw should deprioritize the first drawn punishment")
	}
}

func TestDraw_RecyclesWhenAllRecentlyDrawn(t *testing.T) {
	deck := &PunishmentDeck{
		pools: map[string][]string{
			TierMild:   {"only-one"},
			TierMedium: {},
			TierSpicy:  {},
		},
		recent: []string{"only-one"},
	}

	// Should still return the only option even though it's recent.
	text, _ := deck.Draw(TierMild)
	if text != "only-one" {
		t.Errorf("expected 'only-one', got %q", text)
	}
}

func TestDraw_RecentListCapsAtSize(t *testing.T) {
	deck := NewPunishmentDeck(nil)

	// Draw more than recentListSize times.
	for i := 0; i < recentListSize+5; i++ {
		deck.Draw(TierMild)
	}

	if deck.RecentCount() > recentListSize {
		t.Errorf("recent list should cap at %d, got %d", recentListSize, deck.RecentCount())
	}
}

func TestDraw_NeverReturnsEmpty(t *testing.T) {
	deck := NewPunishmentDeck(nil)
	for i := 0; i < 50; i++ {
		text, tier := deck.Draw(TierMild)
		if text == "" {
			t.Error("Draw should never return empty text")
		}
		if tier == "" {
			t.Error("Draw should never return empty tier")
		}
	}
}

func TestTierForProgression_Boundaries(t *testing.T) {
	tests := []struct {
		current int
		total   int
		want    string
	}{
		{1, 10, TierMild},   // 10% → mild
		{3, 10, TierMild},   // 30% → mild (boundary)
		{4, 10, TierMedium}, // 40% → medium
		{7, 10, TierMedium}, // 70% → medium (boundary)
		{8, 10, TierSpicy},  // 80% → spicy
		{10, 10, TierSpicy}, // 100% → spicy
		{1, 5, TierMild},    // 20% → mild
		{2, 5, TierMedium},  // 40% → medium
		{4, 5, TierSpicy},   // 80% → spicy
		{5, 5, TierSpicy},   // 100% → spicy
		{1, 15, TierMild},   // 6.7% → mild
		{5, 15, TierMedium}, // 33% → medium
		{11, 15, TierSpicy}, // 73% → spicy
	}

	for _, tt := range tests {
		got := TierForProgression(tt.current, tt.total)
		if got != tt.want {
			t.Errorf("TierForProgression(%d, %d) = %q, want %q", tt.current, tt.total, got, tt.want)
		}
	}
}

func TestTierForProgression_ZeroTotalRounds(t *testing.T) {
	got := TierForProgression(1, 0)
	if got != TierMild {
		t.Errorf("expected mild for zero total rounds, got %q", got)
	}
}

func TestIsCustomPunishment(t *testing.T) {
	if isCustomPunishment(builtInMild[0]) {
		t.Error("built-in mild should not be custom")
	}
	if isCustomPunishment(builtInMedium[0]) {
		t.Error("built-in medium should not be custom")
	}
	if isCustomPunishment(builtInSpicy[0]) {
		t.Error("built-in spicy should not be custom")
	}
	if !isCustomPunishment("Totally custom punishment") {
		t.Error("non-built-in should be custom")
	}
}
