package game

import (
	"math/rand"
)

// Tier constants for punishment categorization.
const (
	TierMild   = "mild"
	TierMedium = "medium"
	TierSpicy  = "spicy"
	TierCustom = "custom"
)

// builtInMild contains lighthearted, silly punishments.
var builtInMild = []string{
	"Speak in an accent for the next round",
	"Do your best celebrity impression",
	"Talk in slow motion until your next turn",
	"Give a dramatic weather report about the room",
	"Narrate the next shot like a sports commentator",
	"Do 5 jumping jacks right now",
	"Say everything as a question until your next turn",
	"Strike a pose and hold it for 10 seconds",
	"Make up a haiku about pool on the spot",
	"Give everyone in the room a compliment",
	"Talk like a pirate until your next turn",
	"Do your best robot dance for 10 seconds",
}

// builtInMedium contains escalated, challenging punishments.
var builtInMedium = []string{
	"Let the group choose your next drink",
	"Text the 3rd person in your contacts 'I miss you'",
	"Show the last photo you took to the group",
	"Let someone post a story on your social media",
	"Do a dramatic reading of your last sent text",
	"Let the group pick a song you have to dance to",
	"Switch drinks with the person to your left",
	"Tell an embarrassing story from high school",
	"Let someone change your phone wallpaper",
	"Do your best impression of the person to your right",
	"Reveal your screen time report to the group",
	"Let the group compose a text and you have to send it",
}

// builtInSpicy contains dramatic, intense punishments.
var builtInSpicy = []string{
	"Call someone in your contacts and sing happy birthday",
	"Let the group go through your camera roll for 30 seconds",
	"Post a selfie right now with no filter, no retakes",
	"Call your mom and tell her you love her on speaker",
	"Do a dramatic confession of your biggest pet peeve",
	"Let someone send a DM from your account",
	"Show your most recent search history to the group",
	"FaceTime a friend and introduce them to the group",
	"Let the group pick your profile picture for a week",
	"Do a dramatic reenactment of your most embarrassing moment",
	"Send a voice note to your crush saying 'thinking of you'",
	"Read your last 5 search queries out loud",
}

// recentListSize is the number of recently drawn punishments to deprioritize.
const recentListSize = 8

// PunishmentDeck manages the deck of punishments organized by tier.
type PunishmentDeck struct {
	pools  map[string][]string // tier → punishment texts
	recent []string            // recently drawn punishments (ring buffer)
}

// NewPunishmentDeck creates a punishment deck with built-in punishments and
// custom punishments shuffled into all tiers.
func NewPunishmentDeck(customPunishments []string) *PunishmentDeck {
	deck := &PunishmentDeck{
		pools: map[string][]string{
			TierMild:   make([]string, len(builtInMild)),
			TierMedium: make([]string, len(builtInMedium)),
			TierSpicy:  make([]string, len(builtInSpicy)),
		},
		recent: make([]string, 0, recentListSize),
	}

	copy(deck.pools[TierMild], builtInMild)
	copy(deck.pools[TierMedium], builtInMedium)
	copy(deck.pools[TierSpicy], builtInSpicy)

	// Shuffle custom punishments into all tiers.
	for _, cp := range customPunishments {
		deck.pools[TierMild] = append(deck.pools[TierMild], cp)
		deck.pools[TierMedium] = append(deck.pools[TierMedium], cp)
		deck.pools[TierSpicy] = append(deck.pools[TierSpicy], cp)
	}

	// Shuffle each pool.
	for tier := range deck.pools {
		rand.Shuffle(len(deck.pools[tier]), func(i, j int) {
			deck.pools[tier][i], deck.pools[tier][j] = deck.pools[tier][j], deck.pools[tier][i]
		})
	}

	return deck
}

// Draw selects a punishment from the specified tier pool, deprioritizing
// recently drawn punishments. Returns the text and the tier tag.
// Custom punishments return TierCustom as the tier tag.
func (d *PunishmentDeck) Draw(tier string) (text string, tierTag string) {
	pool := d.pools[tier]
	if len(pool) == 0 {
		// Fallback: try any tier.
		for _, t := range []string{TierMild, TierMedium, TierSpicy} {
			if len(d.pools[t]) > 0 {
				pool = d.pools[t]
				tier = t
				break
			}
		}
		if len(pool) == 0 {
			return "Take a drink!", TierMild
		}
	}

	// Build set of recently drawn for fast lookup.
	recentSet := make(map[string]bool, len(d.recent))
	for _, r := range d.recent {
		recentSet[r] = true
	}

	// Prefer punishments not recently drawn.
	var candidates []int
	for i, p := range pool {
		if !recentSet[p] {
			candidates = append(candidates, i)
		}
	}

	// If all are recently drawn, allow any.
	if len(candidates) == 0 {
		candidates = make([]int, len(pool))
		for i := range pool {
			candidates[i] = i
		}
	}

	idx := candidates[rand.Intn(len(candidates))]
	selected := pool[idx]

	// Track in recent list (ring buffer).
	if len(d.recent) >= recentListSize {
		d.recent = d.recent[1:]
	}
	d.recent = append(d.recent, selected)

	// Determine tier tag: custom punishments get "custom" tag.
	tag := tier
	if isCustomPunishment(selected) {
		tag = TierCustom
	}

	return selected, tag
}

// isCustomPunishment checks if a text is a custom (non-built-in) punishment.
func isCustomPunishment(text string) bool {
	for _, p := range builtInMild {
		if p == text {
			return false
		}
	}
	for _, p := range builtInMedium {
		if p == text {
			return false
		}
	}
	for _, p := range builtInSpicy {
		if p == text {
			return false
		}
	}
	return true
}

// TierForProgression returns the punishment tier based on game progression.
// Uses the same percentage logic as game_theme.dart:tierForProgression().
func TierForProgression(currentRound, totalRounds int) string {
	if totalRounds <= 0 {
		return TierMild
	}
	progress := float64(currentRound) / float64(totalRounds)
	switch {
	case progress <= 0.3:
		return TierMild
	case progress <= 0.7:
		return TierMedium
	default:
		return TierSpicy
	}
}

// PoolSize returns the number of punishments in a tier pool (for testing).
func (d *PunishmentDeck) PoolSize(tier string) int {
	return len(d.pools[tier])
}

// RecentCount returns the number of recently drawn punishments (for testing).
func (d *PunishmentDeck) RecentCount() int {
	return len(d.recent)
}
