package game

// cascadePriority maps cascade profiles to priority values.
// Higher value = higher priority. Never downgrade.
var cascadePriority = map[string]int{
	"routine":          0,
	"streak_milestone": 1,
	"triple_points":    2,
	"item_punishment":  3,
	"spicy":            4,
	"record_this":      5,
}

// PunishmentStep draws a punishment from the deck when a shot is missed.
// Implements ChainStep interface.
type PunishmentStep struct {
	Deck *PunishmentDeck
}

func (s *PunishmentStep) Execute(ctx *ChainContext) error {
	// Only draw punishment on missed shots.
	if ctx.ShotResult != "missed" {
		return nil
	}

	// Determine tier from game progression.
	tier := TierForProgression(ctx.gameState.CurrentRound, ctx.gameState.RoundCount)

	// Draw punishment.
	text, tierTag := s.Deck.Draw(tier)

	ctx.Punishment = text
	ctx.PunishmentTier = tierTag

	// Upgrade cascade profile based on punishment tier (never downgrade).
	var targetProfile string
	switch tier {
	case TierMild:
		targetProfile = "streak_milestone"
	case TierMedium:
		targetProfile = "item_punishment"
	case TierSpicy:
		targetProfile = "spicy"
	default:
		targetProfile = "streak_milestone"
	}

	currentPri := cascadePriority[ctx.CascadeProfile]
	targetPri := cascadePriority[targetProfile]
	if targetPri > currentPri {
		ctx.CascadeProfile = targetProfile
	}

	return nil
}
