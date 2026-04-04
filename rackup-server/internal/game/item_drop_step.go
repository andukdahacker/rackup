package game

import "math/rand"

// ItemDropResult holds the result of an item drop for the turn_complete broadcast.
type ItemDropResult struct {
	ItemType     string  // the item type key (e.g., "blue_shell")
	ReplacedItem *string // the previous item lost (for analytics), nil if slot was empty
}

// ItemDropStep rolls for an item drop on missed shots and assigns the item
// to the shooting player's inventory. Implements ChainStep.
type ItemDropStep struct{}

func (s *ItemDropStep) Execute(ctx *ChainContext) error {
	// Only drop items on missed shots.
	if ctx.ShotResult != "missed" {
		return nil
	}

	// 50% probability of item drop.
	if rand.Float64() >= 0.5 {
		return nil
	}

	// Determine player rank from leaderboard.
	shooterHash := ctx.ShooterHash
	isFirstPlace := false
	isLastPlace := false

	if len(ctx.PreviousLeaderboard) > 0 {
		// Find the max rank to handle tied-rank edge cases.
		maxRank := 0
		for _, entry := range ctx.PreviousLeaderboard {
			if entry.Rank > maxRank {
				maxRank = entry.Rank
			}
		}
		for _, entry := range ctx.PreviousLeaderboard {
			if entry.DeviceIDHash == shooterHash {
				isFirstPlace = entry.Rank == 1
				isLastPlace = entry.Rank == maxRank
				break
			}
		}
	}

	// Draw an item from the appropriate deck.
	itemType := DrawItem(isLastPlace, isFirstPlace)

	// Assign to player (use-it-or-lose-it).
	player := ctx.gameState.Players[shooterHash]
	if player == nil {
		return nil
	}

	var replacedItem *string
	if player.HeldItem != nil {
		prev := *player.HeldItem
		replacedItem = &prev
	}
	player.HeldItem = &itemType

	// Store result for turn_complete broadcast.
	ctx.ItemDrop = &ItemDropResult{
		ItemType:     itemType,
		ReplacedItem: replacedItem,
	}

	// Upgrade cascade profile if item_punishment has higher priority.
	currentPri := cascadePriority[ctx.CascadeProfile]
	targetPri := cascadePriority["item_punishment"]
	if targetPri > currentPri {
		ctx.CascadeProfile = "item_punishment"
	}

	return nil
}
