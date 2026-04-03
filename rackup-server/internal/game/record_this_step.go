package game

import "fmt"

// RecordThisCheckStep detects shareable "RECORD THIS" moments in the
// consequence chain.  MVP trigger: a player with an "unstoppable" streak
// (4+) misses a shot, breaking the streak.
type RecordThisCheckStep struct{}

func (s *RecordThisCheckStep) Execute(ctx *ChainContext) error {
	// Only trigger on a missed shot that breaks a streak of 4+.
	if ctx.ShotResult != "missed" {
		return nil
	}
	if ctx.gameState.lastStreakBefore < 4 {
		return nil
	}

	shooter := ctx.gameState.Players[ctx.ShooterHash]
	if shooter == nil {
		return nil
	}

	ctx.RecordThis = true
	ctx.TargetPlayerHash = ctx.ShooterHash
	ctx.RecordThisSubtext = fmt.Sprintf("%s's streak just got broken!", shooter.DisplayName)
	// record_this overrides all lower cascade profiles.
	ctx.CascadeProfile = "record_this"

	return nil
}
