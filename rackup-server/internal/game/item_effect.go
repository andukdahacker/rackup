package game

import "math/rand"

// ItemType constants for all 10 power-up items.
const (
	ItemBlueshell     = "blue_shell"
	ItemShield        = "shield"
	ItemScoreSteal    = "score_steal"
	ItemStreakBreaker  = "streak_breaker"
	ItemDoubleUp      = "double_up"
	ItemTrapCard      = "trap_card"
	ItemReverse        = "reverse"
	ItemImmunity       = "immunity"
	ItemMulligan       = "mulligan"
	ItemWildcard       = "wildcard"
)

// ItemMeta holds display metadata for an item type.
type ItemMeta struct {
	Name           string
	Description    string
	AccentColor    string // hex color
	RequiresTarget bool   // true if item needs a target player on deploy
}

// ItemRegistry maps item type strings to display metadata.
var ItemRegistry = map[string]ItemMeta{
	ItemBlueshell:    {Name: "Blue Shell", Description: "Targets 1st place automatically", AccentColor: "#3B82F6", RequiresTarget: true},
	ItemShield:       {Name: "Shield", Description: "Blocks one incoming item", AccentColor: "#14B8A6", RequiresTarget: false},
	ItemScoreSteal:   {Name: "Score Steal", Description: "Steal points from a target", AccentColor: "#FF6B6B", RequiresTarget: true},
	ItemStreakBreaker: {Name: "Streak Breaker", Description: "Break a target's streak", AccentColor: "#F97316", RequiresTarget: true},
	ItemDoubleUp:     {Name: "Double Up", Description: "Double your next score", AccentColor: "#FFD700", RequiresTarget: false},
	ItemTrapCard:     {Name: "Trap Card", Description: "Delayed trap for next miss", AccentColor: "#DC2626", RequiresTarget: false},
	ItemReverse:      {Name: "Reverse", Description: "Reverse the turn order", AccentColor: "#8B5CF6", RequiresTarget: true},
	ItemImmunity:     {Name: "Immunity", Description: "Block the next punishment", AccentColor: "#10B981", RequiresTarget: false},
	ItemMulligan:     {Name: "Mulligan", Description: "Group vote to redo a shot", AccentColor: "#60A5FA", RequiresTarget: false},
	ItemWildcard:     {Name: "Wildcard", Description: "Create a custom rule", AccentColor: "#EAB308", RequiresTarget: false},
}

// FullDeck contains all 10 item types.
var FullDeck = []string{
	ItemBlueshell, ItemShield, ItemScoreSteal, ItemStreakBreaker, ItemDoubleUp,
	ItemTrapCard, ItemReverse, ItemImmunity, ItemMulligan, ItemWildcard,
}

// DeckWithoutBlueshell contains 9 items (excludes Blue Shell for first-place draws).
var DeckWithoutBlueshell = []string{
	ItemShield, ItemScoreSteal, ItemStreakBreaker, ItemDoubleUp,
	ItemTrapCard, ItemReverse, ItemImmunity, ItemMulligan, ItemWildcard,
}

// ItemEffect defines the interface for item execution (Stories 5.3/5.4).
type ItemEffect interface {
	Execute(gs *GameState, userHash string, targetHash string) error
	RequiresTarget() bool
	RequiresVote() bool
}

// ItemRequiresTarget returns whether the given item type requires a target player on deployment.
func ItemRequiresTarget(itemType string) bool {
	if meta, ok := ItemRegistry[itemType]; ok {
		return meta.RequiresTarget
	}
	return false
}

// DrawItem selects a random item from the appropriate deck based on player position.
// isFirstPlace excludes Blue Shell. isLastPlace draws from full deck (Blue Shell possible).
// This function always returns an item — the 50% probability check is in the caller.
func DrawItem(isLastPlace bool, isFirstPlace bool) string {
	if isFirstPlace {
		return DeckWithoutBlueshell[rand.Intn(len(DeckWithoutBlueshell))]
	}
	// Both last place and middle positions draw from full deck.
	return FullDeck[rand.Intn(len(FullDeck))]
}
