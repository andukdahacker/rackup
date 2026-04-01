package game

import (
	"testing"
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
