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

func TestItemDeployPayload_JSON(t *testing.T) {
	payload := ItemDeployPayload{
		Item:     "blue_shell",
		TargetID: "target-hash",
	}
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var decoded ItemDeployPayload
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if decoded.Item != "blue_shell" {
		t.Errorf("expected Item blue_shell, got %q", decoded.Item)
	}
	if decoded.TargetID != "target-hash" {
		t.Errorf("expected TargetID target-hash, got %q", decoded.TargetID)
	}
}

func TestItemDeployPayload_JSONOmitsEmptyTarget(t *testing.T) {
	payload := ItemDeployPayload{Item: "shield"}
	data, _ := json.Marshal(payload)
	var raw map[string]interface{}
	json.Unmarshal(data, &raw)
	if _, exists := raw["targetId"]; exists {
		t.Error("expected targetId to be omitted when empty")
	}
}

func TestItemDeployedPayload_JSON(t *testing.T) {
	payload := ItemDeployedPayload{
		Item:       "blue_shell",
		DeployerID: "deployer-hash",
		TargetID:   "target-hash",
		Leaderboard: []LeaderboardEntry{
			{DeviceIDHash: "p1", DisplayName: "Alice", Score: 10, Rank: 1},
		},
	}
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var decoded ItemDeployedPayload
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if decoded.DeployerID != "deployer-hash" {
		t.Errorf("expected DeployerID deployer-hash, got %q", decoded.DeployerID)
	}
	if len(decoded.Leaderboard) != 1 {
		t.Errorf("expected 1 leaderboard entry, got %d", len(decoded.Leaderboard))
	}
}

func TestItemFizzledPayload_JSON(t *testing.T) {
	payload := ItemFizzledPayload{
		Item:   "shield",
		Reason: "ITEM_CONSUMED",
	}
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var decoded ItemFizzledPayload
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if decoded.Item != "shield" {
		t.Errorf("expected Item shield, got %q", decoded.Item)
	}
	if decoded.Reason != "ITEM_CONSUMED" {
		t.Errorf("expected Reason ITEM_CONSUMED, got %q", decoded.Reason)
	}
}
