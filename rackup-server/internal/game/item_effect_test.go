package game

import "testing"

func TestDrawItem_LastPlaceCanGetBlueshell(t *testing.T) {
	// Run enough times to statistically expect Blue Shell at least once.
	gotBlueshell := false
	for i := 0; i < 200; i++ {
		item := DrawItem(true, false)
		if item == ItemBlueshell {
			gotBlueshell = true
			break
		}
	}
	if !gotBlueshell {
		t.Error("expected Blue Shell to appear for last place after 200 draws")
	}
}

func TestDrawItem_FirstPlaceNeverGetsBlueshell(t *testing.T) {
	for i := 0; i < 500; i++ {
		item := DrawItem(false, true)
		if item == ItemBlueshell {
			t.Fatalf("first place should never get Blue Shell, got it on draw %d", i)
		}
	}
}

func TestDrawItem_MiddlePositionDrawsFromFullDeck(t *testing.T) {
	seen := make(map[string]bool)
	for i := 0; i < 500; i++ {
		item := DrawItem(false, false)
		seen[item] = true
	}
	// Should see all 10 items including Blue Shell.
	for _, itemType := range FullDeck {
		if !seen[itemType] {
			t.Errorf("expected to see item %q in middle-position draws", itemType)
		}
	}
}

func TestDrawItem_AlwaysReturnsValidItem(t *testing.T) {
	validItems := make(map[string]bool, len(FullDeck))
	for _, item := range FullDeck {
		validItems[item] = true
	}

	for i := 0; i < 100; i++ {
		item := DrawItem(false, false)
		if !validItems[item] {
			t.Errorf("DrawItem returned invalid item: %q", item)
		}
	}
}

func TestItemTypeConstants_AllDefined(t *testing.T) {
	expected := []string{
		ItemBlueshell, ItemShield, ItemScoreSteal, ItemStreakBreaker,
		ItemDoubleUp, ItemTrapCard, ItemReverse, ItemImmunity,
		ItemMulligan, ItemWildcard,
	}
	if len(expected) != 10 {
		t.Errorf("expected 10 item types, got %d", len(expected))
	}
	for _, item := range expected {
		if _, ok := ItemRegistry[item]; !ok {
			t.Errorf("item %q not found in ItemRegistry", item)
		}
	}
}

func TestFullDeck_Has10Items(t *testing.T) {
	if len(FullDeck) != 10 {
		t.Errorf("FullDeck should have 10 items, got %d", len(FullDeck))
	}
}

func TestDeckWithoutBlueshell_Has9Items(t *testing.T) {
	if len(DeckWithoutBlueshell) != 9 {
		t.Errorf("DeckWithoutBlueshell should have 9 items, got %d", len(DeckWithoutBlueshell))
	}
	for _, item := range DeckWithoutBlueshell {
		if item == ItemBlueshell {
			t.Error("DeckWithoutBlueshell should not contain Blue Shell")
		}
	}
}

func TestItemRequiresTarget_Targeted(t *testing.T) {
	targeted := []string{ItemBlueshell, ItemScoreSteal, ItemStreakBreaker, ItemReverse}
	for _, item := range targeted {
		if !ItemRequiresTarget(item) {
			t.Errorf("expected ItemRequiresTarget(%q) = true", item)
		}
	}
}

func TestItemRequiresTarget_NonTargeted(t *testing.T) {
	nonTargeted := []string{ItemShield, ItemDoubleUp, ItemTrapCard, ItemImmunity, ItemMulligan, ItemWildcard}
	for _, item := range nonTargeted {
		if ItemRequiresTarget(item) {
			t.Errorf("expected ItemRequiresTarget(%q) = false", item)
		}
	}
}

func TestItemRequiresTarget_UnknownItem(t *testing.T) {
	if ItemRequiresTarget("unknown_item") {
		t.Error("expected ItemRequiresTarget for unknown item to return false")
	}
}

func TestItemRegistry_RequiresTargetField(t *testing.T) {
	expectedTargeted := map[string]bool{
		ItemBlueshell:    true,
		ItemShield:       false,
		ItemScoreSteal:   true,
		ItemStreakBreaker: true,
		ItemDoubleUp:     false,
		ItemTrapCard:     false,
		ItemReverse:      true,
		ItemImmunity:     false,
		ItemMulligan:     false,
		ItemWildcard:     false,
	}
	for itemType, expected := range expectedTargeted {
		meta, ok := ItemRegistry[itemType]
		if !ok {
			t.Errorf("item %q not in registry", itemType)
			continue
		}
		if meta.RequiresTarget != expected {
			t.Errorf("ItemRegistry[%q].RequiresTarget = %v, want %v", itemType, meta.RequiresTarget, expected)
		}
	}
}

func TestGamePlayer_HeldItem(t *testing.T) {
	player := &GamePlayer{DeviceIDHash: "p1", DisplayName: "Test"}

	// Initially nil.
	if player.HeldItem != nil {
		t.Error("expected HeldItem to be nil initially")
	}

	// Assign item.
	item := ItemShield
	player.HeldItem = &item
	if *player.HeldItem != ItemShield {
		t.Errorf("expected HeldItem %q, got %q", ItemShield, *player.HeldItem)
	}

	// Use-it-or-lose-it: overwrite unconditionally.
	newItem := ItemBlueshell
	player.HeldItem = &newItem
	if *player.HeldItem != ItemBlueshell {
		t.Errorf("expected HeldItem %q after overwrite, got %q", ItemBlueshell, *player.HeldItem)
	}

	// ClearItem.
	player.ClearItem()
	if player.HeldItem != nil {
		t.Error("expected HeldItem to be nil after ClearItem()")
	}
}
