package protocol

import (
	"encoding/json"
	"testing"
)

func TestTurnCompletePayload_JSONWithItemDrop(t *testing.T) {
	payload := TurnCompletePayload{
		ShooterHash:        "hash-a",
		Result:             "missed",
		PointsAwarded:      0,
		NewScore:           5,
		NewStreak:          0,
		CurrentShooterHash: "hash-b",
		CurrentRound:       3,
		IsGameOver:         false,
		StreakLabel:         "",
		StreakMilestone:     false,
		CascadeProfile:     "item_punishment",
		IsTriplePoints:     false,
		Punishment: &PunishmentPayload{
			Text: "Take a sip",
			Tier: "mild",
		},
		ItemDrop: &ItemDropPayload{
			Item:     "blue_shell",
			PlayerID: "hash-a",
		},
	}

	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}

	var decoded TurnCompletePayload
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}

	if decoded.ItemDrop == nil {
		t.Fatal("expected ItemDrop to be present")
	}
	if decoded.ItemDrop.Item != "blue_shell" {
		t.Errorf("expected item 'blue_shell', got %q", decoded.ItemDrop.Item)
	}
	if decoded.ItemDrop.PlayerID != "hash-a" {
		t.Errorf("expected playerId 'hash-a', got %q", decoded.ItemDrop.PlayerID)
	}
}

func TestTurnCompletePayload_JSONWithoutItemDrop(t *testing.T) {
	payload := TurnCompletePayload{
		ShooterHash:        "hash-a",
		Result:             "made",
		PointsAwarded:      3,
		NewScore:           8,
		NewStreak:          1,
		CurrentShooterHash: "hash-b",
		CurrentRound:       3,
		IsGameOver:         false,
		CascadeProfile:     "routine",
	}

	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}

	// Verify itemDrop is omitted from JSON.
	var raw map[string]interface{}
	json.Unmarshal(data, &raw)
	if _, exists := raw["itemDrop"]; exists {
		t.Error("expected itemDrop to be omitted when nil")
	}

	var decoded TurnCompletePayload
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}

	if decoded.ItemDrop != nil {
		t.Error("expected ItemDrop to be nil")
	}
}
