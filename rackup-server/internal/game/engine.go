package game

import "sort"

// ChainStep processes one stage of the consequence chain.
// Each step receives the accumulating chain context and enriches it.
type ChainStep interface {
	Execute(ctx *ChainContext) error
}

// ChainContext accumulates state as the consequence chain executes.
type ChainContext struct {
	// Input: the shooter and result.
	ShooterHash string
	ShotResult  string // "made" or "missed"

	// Populated by shot_result step.
	TurnResult *TurnResult

	// Populated by streak_update step.
	StreakLabel     string // "", "warming_up", "on_fire", "unstoppable"
	StreakMilestone bool   // true when streak just crossed a threshold (2, 3, or 4)

	// Populated by Run() before chain executes — snapshot for rank change detection.
	PreviousLeaderboard []LeaderboardEntry

	// Populated by score_update / leaderboard_recalc steps.
	Leaderboard []LeaderboardEntry

	// TriplePointsActivated is true only on the first turn where triple points become active.
	TriplePointsActivated bool

	// RecordThis is true when a shareable "RECORD THIS" moment is detected.
	RecordThis        bool
	RecordThisSubtext string
	TargetPlayerHash  string

	// CascadeProfile for UI timing.
	CascadeProfile string // "routine", "streak_milestone", "item_punishment", "spicy", "record_this", "triple_points"

	// Reference to game state (read-only after shot processing).
	gameState *GameState
}

// LeaderboardEntry represents a single player's ranking.
type LeaderboardEntry struct {
	DeviceIDHash string `json:"deviceIdHash"`
	DisplayName  string `json:"displayName"`
	Score        int    `json:"score"`
	Streak       int    `json:"streak"`
	StreakLabel   string `json:"streakLabel"`
	Rank         int    `json:"rank"`
	RankChanged  bool   `json:"rankChanged"`
}

// ConsequenceChain executes a deterministic pipeline of steps after a shot.
// Step order: shot_result -> streak_update -> [punishment_slot] -> [item_drop_slot] ->
// [mission_check_slot] -> score_update -> leaderboard_recalc -> UI_events ->
// sound_triggers -> [record_this_check_slot]
type ConsequenceChain struct {
	steps []namedStep
}

type namedStep struct {
	name string
	step ChainStep
}

// NewConsequenceChain creates a chain with the default step sequence.
func NewConsequenceChain() *ConsequenceChain {
	return &ConsequenceChain{
		steps: []namedStep{
			{name: "shot_result", step: &ShotResultStep{}},
			{name: "streak_update", step: &StreakUpdateStep{}},
			{name: "punishment_slot", step: &NoOpStep{}},
			{name: "item_drop_slot", step: &NoOpStep{}},
			{name: "mission_check_slot", step: &NoOpStep{}},
			{name: "score_update", step: &ScoreUpdateStep{}},
			{name: "leaderboard_recalc", step: &LeaderboardRecalcStep{}},
			{name: "ui_events", step: &NoOpStep{}},
			{name: "sound_triggers", step: &NoOpStep{}},
			{name: "record_this_check_slot", step: &NoOpStep{}},
		},
	}
}

// ReplaceStep replaces a named step in the chain. Used by future epics
// to plug in real implementations for extension points.
func (c *ConsequenceChain) ReplaceStep(name string, step ChainStep) {
	for i, ns := range c.steps {
		if ns.name == name {
			c.steps[i].step = step
			return
		}
	}
}

// Run executes the chain steps in order against the given game state.
func (c *ConsequenceChain) Run(gs *GameState, shooterHash, shotResult string) (*ChainContext, error) {
	// Snapshot leaderboard before chain executes for rank change detection.
	previousLeaderboard := gs.CalculateLeaderboard(nil)

	ctx := &ChainContext{
		ShooterHash:         shooterHash,
		ShotResult:          shotResult,
		CascadeProfile:      "routine",
		PreviousLeaderboard: previousLeaderboard,
		gameState:           gs,
	}

	for _, ns := range c.steps {
		if err := ns.step.Execute(ctx); err != nil {
			return nil, err
		}
	}

	return ctx, nil
}

// StepNames returns the ordered list of step names (for testing).
func (c *ConsequenceChain) StepNames() []string {
	names := make([]string, len(c.steps))
	for i, ns := range c.steps {
		names[i] = ns.name
	}
	return names
}

// --- Built-in chain steps ---

// ShotResultStep processes the shot via GameState.ProcessShot.
type ShotResultStep struct{}

func (s *ShotResultStep) Execute(ctx *ChainContext) error {
	// Capture triple-point state BEFORE ProcessShot (which may call AdvanceTurn).
	preShotTriple := ctx.gameState.IsTriplePoints()

	result, err := ctx.gameState.ProcessShot(ctx.ShooterHash, ctx.ShotResult)
	if err != nil {
		return err
	}
	ctx.TurnResult = result

	// Detect activation: triple points just became active due to AdvanceTurn.
	postShotTriple := ctx.gameState.IsTriplePoints()
	ctx.TriplePointsActivated = !preShotTriple && postShotTriple

	// Override cascade profile on activation (takes priority over streak_milestone).
	if ctx.TriplePointsActivated {
		ctx.CascadeProfile = "triple_points"
	}

	return nil
}

// StreakUpdateStep computes streak label and milestone detection.
type StreakUpdateStep struct{}

func (s *StreakUpdateStep) Execute(ctx *ChainContext) error {
	if ctx.TurnResult == nil {
		return nil
	}

	streak := ctx.TurnResult.NewStreak
	ctx.StreakLabel = StreakLabel(streak)

	// Milestone: streak just crossed a threshold (2, 3, or 4).
	ctx.StreakMilestone = streak == 2 || streak == 3 || streak == 4

	// Update cascade profile for milestone transitions.
	// Do not override "triple_points" — it takes priority over streak_milestone.
	if ctx.StreakMilestone && ctx.CascadeProfile != "triple_points" {
		ctx.CascadeProfile = "streak_milestone"
	}

	return nil
}

// ScoreUpdateStep is a placeholder — scoring already happens in ProcessShot.
// This step exists for future enrichment.
type ScoreUpdateStep struct{}

func (s *ScoreUpdateStep) Execute(ctx *ChainContext) error {
	return nil
}

// LeaderboardRecalcStep recalculates the leaderboard from game state.
type LeaderboardRecalcStep struct{}

func (s *LeaderboardRecalcStep) Execute(ctx *ChainContext) error {
	ctx.Leaderboard = ctx.gameState.CalculateLeaderboard(ctx.PreviousLeaderboard)
	return nil
}

// NoOpStep is a placeholder for future extension points.
type NoOpStep struct{}

func (s *NoOpStep) Execute(ctx *ChainContext) error {
	return nil
}

// --- Helper functions ---

// StreakLabel returns the display label for a streak count.
func StreakLabel(streak int) string {
	switch {
	case streak >= 4:
		return "unstoppable"
	case streak == 3:
		return "on_fire"
	case streak == 2:
		return "warming_up"
	default:
		return ""
	}
}

// CalculateLeaderboard returns non-referee players sorted by score descending with ranks.
// If previous is non-nil, RankChanged is set for players whose rank differs.
func (gs *GameState) CalculateLeaderboard(previous []LeaderboardEntry) []LeaderboardEntry {
	entries := make([]LeaderboardEntry, 0, len(gs.Players))
	for _, player := range gs.Players {
		if player.IsReferee {
			continue
		}
		entries = append(entries, LeaderboardEntry{
			DeviceIDHash: player.DeviceIDHash,
			DisplayName:  player.DisplayName,
			Score:        player.Score,
			Streak:       player.Streak,
			StreakLabel:   StreakLabel(player.Streak),
		})
	}

	// Sort by score descending, then by slot ascending for tie-breaking.
	sort.Slice(entries, func(i, j int) bool {
		if entries[i].Score != entries[j].Score {
			return entries[i].Score > entries[j].Score
		}
		// Tie-break by slot (lower slot = higher rank).
		pi := gs.Players[entries[i].DeviceIDHash]
		pj := gs.Players[entries[j].DeviceIDHash]
		if pi != nil && pj != nil {
			return pi.Slot < pj.Slot
		}
		return entries[i].DeviceIDHash < entries[j].DeviceIDHash
	})

	// Assign ranks (1-based, tied players get same rank).
	for i := range entries {
		if i == 0 {
			entries[i].Rank = 1
		} else if entries[i].Score == entries[i-1].Score {
			entries[i].Rank = entries[i-1].Rank
		} else {
			entries[i].Rank = i + 1
		}
	}

	// Compute RankChanged by comparing with previous leaderboard.
	if len(previous) > 0 {
		prevRankMap := make(map[string]int, len(previous))
		for _, p := range previous {
			prevRankMap[p.DeviceIDHash] = p.Rank
		}
		for i := range entries {
			if prevRank, ok := prevRankMap[entries[i].DeviceIDHash]; ok {
				entries[i].RankChanged = entries[i].Rank != prevRank
			}
		}
	}

	return entries
}
