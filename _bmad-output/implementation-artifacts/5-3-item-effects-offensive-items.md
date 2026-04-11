# Story 5.3: Item Effects — Offensive Items

Status: ready-for-dev

## Story

As a player,
I want offensive items that let me disrupt other players' scores and streaks,
So that I can strategically attack leaders and create dramatic comebacks.

## Acceptance Criteria

1. **Blue Shell (FR36a):** Target loses 3 points; target must shoot off-handed next turn; all players see The Eruption animation + Blue Shell sound; effect text throbs with electric blue energy
2. **Score Steal (FR36c):** 5 points transfer from target to deployer; leaderboard updates with position-shuffle animation if rankings change
3. **Streak Breaker (FR36d):** Target's streak resets to zero; target's Streak Fire Indicator disappears; event appears in all players' Event Feed
4. **Reverse (FR36g):** Deployer's score and target's score are swapped; leaderboard updates with position-shuffle animation
5. **Trap Card (FR36f):** Next player to miss receives the deployer's punishment instead of a random draw; activation revealed to all players when triggered

## Tasks / Subtasks

- [ ] Task 1: Implement ItemEffect interface execution in room.go (AC: all)
  - [ ] 1.1 Create `internal/game/items/` directory
  - [ ] 1.2 Update `ItemEffect.Execute()` signature from `Execute(gs *GameState, userHash string, targetHash string) error` to `Execute(gs *GameState, userHash string, targetHash string) (*EffectResult, error)` — no existing implementations to break
  - [ ] 1.3 Add `EffectResult` struct to `item_effect.go` to carry effect outcomes (score changes, streak changes, status effects) back to room.go
  - [ ] 1.4 Create `ItemEffectRegistry` map linking item type constants to `ItemEffect` implementations
  - [ ] 1.5 Update `handleItemDeployLocked()` in room.go: after consuming item, look up effect in registry → call `Execute()` → apply `EffectResult` to game state → include effect details in `item.deployed` broadcast
  - [ ] 1.6 Extend `ItemDeployedPayload` (Go + Dart) with an `effectResult` field to carry effect details (score changes, status effects applied) to clients

- [ ] Task 2: Blue Shell effect implementation (AC: #1)
  - [ ] 2.1 Create `internal/game/items/blue_shell.go` implementing `ItemEffect`
  - [ ] 2.2 Execute: target.Score -= 3 (floor at 0); set `OffHanded` flag on target for next turn
  - [ ] 2.3 Add `OffHanded bool` field to `GamePlayer` struct in `game_state.go`
  - [ ] 2.4 Clear `OffHanded` flag in `ProcessShot()` after the off-handed turn is consumed
  - [ ] 2.5 Create `internal/game/items/blue_shell_test.go` — verify -3 points, off-handed flag set, floor at 0 score

- [ ] Task 3: Score Steal effect implementation (AC: #2)
  - [ ] 3.1 Create `internal/game/items/score_steal.go` implementing `ItemEffect`
  - [ ] 3.2 Execute: target.Score -= 5, deployer.Score += 5 (target floor at 0, deployer gets only what target had if < 5)
  - [ ] 3.3 Create `internal/game/items/score_steal_test.go` — verify transfer, floor behavior, edge cases

- [ ] Task 4: Streak Breaker effect implementation (AC: #3)
  - [ ] 4.1 Create `internal/game/items/streak_breaker.go` implementing `ItemEffect`
  - [ ] 4.2 Execute: target.Streak = 0
  - [ ] 4.3 Create `internal/game/items/streak_breaker_test.go` — verify streak reset, already-zero case

- [ ] Task 5: Reverse effect implementation (AC: #4)
  - [ ] 5.1 Create `internal/game/items/reverse.go` implementing `ItemEffect`
  - [ ] 5.2 Execute: swap deployer.Score and target.Score
  - [ ] 5.3 Create `internal/game/items/reverse_test.go` — verify swap, equal scores, zero-score cases

- [ ] Task 6: Trap Card effect implementation (AC: #5)
  - [ ] 6.1 Create `internal/game/items/trap_card.go` implementing `ItemEffect`
  - [ ] 6.2 Execute: set `ActiveTrapCard` on GameState with deployer's device hash
  - [ ] 6.3 Add `ActiveTrapCard *TrapCardState` field to `GameState` (DeployerHash, activated bool)
  - [ ] 6.4 Modify `PunishmentStep.Execute()`: if `ActiveTrapCard` is set and a different player misses → draw from the deployer's stored punishment tier (spicy) for the victim instead of normal progression-based draw → clear the trap → set `TrapCardActivated` flag on ChainContext. Note: PRD says "receives the deployer's punishment" — interpret as "draws from spicy tier" (deployer's implied tier), not a pre-stored text
  - [ ] 6.5 Add `TrapCardActivated bool` + `TrapCardDeployerHash string` to `ChainContext` for broadcast
  - [ ] 6.6 Handle Trap Card overwrite: if a second Trap Card is deployed while one is active, the new one replaces the old (use-it-or-lose-it, consistent with item slot design)
  - [ ] 6.7 Handle Trap Card on game end: if game ends with an active Trap Card, it simply expires (no special handling — `GameState` is discarded)
  - [ ] 6.8 Create `internal/game/items/trap_card_test.go` — verify deferred activation, trap consumed, deployer exempt, overwrite behavior

- [ ] Task 7: Protocol extension for effect results (AC: all)
  - [ ] 7.1 Add `EffectResult` payload struct to Go `protocol/messages.go`: `{effectType string, scoreChanges map[string]int, streakChanges map[string]int, statusEffects map[string][]string}` — use `[]string` to support multiple simultaneous effects per player (e.g., off-handed + shielded)
  - [ ] 7.2 Add `EffectResult` field to `ItemDeployedPayload`
  - [ ] 7.3 Add `TrapCardActivated` + `TrapCardDeployerHash` to `TurnCompletePayload` for Trap Card reveal
  - [ ] 7.4 Add `ActiveEffects []string` field to `LeaderboardEntry` (Go + Dart) so off-handed and other status effects survive reconnection and are visible in every leaderboard broadcast (e.g., `["off_handed"]`)
  - [ ] 7.5 Mirror all Go protocol changes in Dart `protocol/messages.dart`
  - [ ] 7.6 Update `protocol/messages_test.go` with serialization tests

- [ ] Task 8: Client effect handling in GameMessageListener (AC: all)
  - [ ] 8.1 Update `item.deployed` handler: parse `effectResult`, dispatch score/streak changes to `LeaderboardBloc`
  - [ ] 8.2 Generate item-specific event feed text per effect type (e.g., "Blue Shell hits [Target]! -3 points + off-handed next turn", "Score Steal: [Deployer] takes 5 from [Target]")
  - [ ] 8.3 Handle Trap Card activation in `game.turn_complete`: when `trapCardActivated` is true, add event feed entry "[Player] triggered [Deployer]'s Trap Card!"
  - [ ] 8.4 Play `GameSound.blueShellImpact` for Blue Shell deployments (already in assets); add `GameSound.itemEffect` for other offensive items

- [ ] Task 9: Client visual feedback for effects (AC: #1, #2, #4)
  - [ ] 9.1 Update `LeaderboardBloc` to handle score changes from item effects (position-shuffle animation already exists)
  - [ ] 9.2 Add off-handed indicator to leaderboard entry or turn announcement widget when target has OffHanded status
  - [ ] 9.3 Ensure Trap Card pending indicator displays on deployer's event feed (e.g., "Trap Card armed...")
  - [ ] 9.4 Blue Shell triggers The Eruption animation (already implemented as cascade_controller pattern) — ensure `cascadeProfile` in `item.deployed` is set to trigger Eruption timing for Blue Shell

- [ ] Task 10: Comprehensive tests (AC: all)
  - [ ] 10.1 Server: item effect registry tests — all 5 offensive items registered and Execute() callable
  - [ ] 10.2 Server: room.go integration test — deploy item → effect applied → correct `item.deployed` broadcast
  - [ ] 10.3 Server: Trap Card integration with PunishmentStep — deploy trap → other player misses → trap fires
  - [ ] 10.4 Client: GameMessageListener routes effect results to correct blocs
  - [ ] 10.5 Client: Event feed generates correct text for each offensive item effect
  - [ ] 10.6 Client: LeaderboardBloc receives updated scores from item effects
  - [ ] 10.7 Client: Widget test for off-handed indicator display
  - [ ] 10.8 Server: Trap Card overwrite test — deploy second trap while first active

## Dev Notes

### Architecture Pattern: ItemEffect Interface

The `ItemEffect` interface is already defined in `item_effect.go:54-58`:

```go
type ItemEffect interface {
    Execute(gs *GameState, userHash string, targetHash string) error
    RequiresTarget() bool
    RequiresVote() bool
}
```

Each offensive item goes in its own file under `internal/game/items/`. The interface returns an error but currently has no `EffectResult` return — **you must extend the interface** to return `(*EffectResult, error)` so the room goroutine can broadcast what happened. This is a breaking change to the interface signature but there are no existing implementations yet, so it's safe.

### Critical: Room.go Deployment Handler Update

The current `handleItemDeployLocked()` in `room.go:847-919` consumes the item and broadcasts `item.deployed` but does NOT execute any effect logic. Story 5.3 must:
1. Look up the item in an effect registry
2. Call `Execute()` on the effect
3. Apply the result to game state (scores, streaks, status flags)
4. Include the effect result in the `ItemDeployedPayload` broadcast
5. Recalculate leaderboard AFTER the effect is applied (the existing leaderboard calc on line 888 is already positioned correctly)

### Score Floor Rule

No player's score should go below 0. Blue Shell (-3) and Score Steal (-5) must clamp at 0. For Score Steal, the deployer receives only the points actually deducted (e.g., if target has 2 points, deployer gets 2, not 5).

### Item Point Values Are Fixed (Not Affected by Triple Points)

Blue Shell always deducts exactly 3, Score Steal always transfers exactly 5 — regardless of triple-points mode. Per FR31, only "base shots, streak bonuses, and mission bonuses" are tripled. Item effects are not listed. Add a code comment documenting this design decision to prevent future "fixes."

### Trap Card: Deferred Activation Pattern

Trap Card is unique — it does NOT resolve immediately on deploy. It sets state on `GameState` that the `PunishmentStep` checks on the NEXT miss by any other player. This means:
- Deploy → `GameState.ActiveTrapCard = {DeployerHash: deployerID}`
- Next player misses → `PunishmentStep` sees active trap → assigns spicy-tier punishment to the missing player → clears trap → sets `TrapCardActivated` on `ChainContext`
- The deployer who set the trap does NOT trigger their own trap if they miss
- Trap Card activation must be broadcast to all players via a field in `TurnCompletePayload`
- **Trap Card overwrite:** If a second Trap Card is deployed while one is active, the new one replaces the old silently (same use-it-or-lose-it philosophy as the item slot)
- **Trap Card on game end:** Active trap simply expires when `GameState` is discarded — no special cleanup needed

### Off-Handed Flag: Blue Shell Secondary Effect

Blue Shell has a secondary effect: the target must shoot off-handed on their next turn. This is a display/announcement concern — the server tracks the flag, but enforcement is social (the referee and group enforce it). Add `OffHanded bool` to `GamePlayer`, set it on Blue Shell effect, clear it in `ProcessShot()` when the off-handed player takes their shot. Best location: clear at the START of `ProcessShot()` (line ~168 in `game_state.go`, after the `player := gs.Players[shooterHash]` lookup) so the flag is consumed on the shot that was supposed to be off-handed.

**Client propagation:** The off-handed status must be visible in EVERY leaderboard broadcast (not just the `item.deployed` message) so clients that reconnect still know who is off-handed. Add `ActiveEffects []string` to `LeaderboardEntry` and populate from `GamePlayer.OffHanded` in `CalculateLeaderboard()`. This also enables the turn announcement widget to display "shoots OFF-HANDED" without relying on client-side state.

### Items That Do NOT Require Target Validation Changes

Trap Card (`RequiresTarget: false`) deploys without a target — it's a deferred effect. The existing validation in `handleItemDeployLocked()` already clears spurious targetId for non-targeted items (line 880-882).

### Event Feed Text Patterns (follow existing conventions)

Existing patterns from `game_message_listener.dart`:
- Item drop: `"The pool gods smile upon $recipientName — $itemName!"`
- Deploy: `"$deployerName deployed $itemName on $targetName!"`
- Fizzle: `"$itemName fizzled!"`

New effect-specific event feed text should follow this style:
- Blue Shell: `"$targetName hit by Blue Shell! -3 points + off-handed next turn"`
- Score Steal: `"$deployerName stole $amount points from $targetName!"`
- Streak Breaker: `"$targetName's streak broken by $deployerName!"`
- Reverse: `"$deployerName and $targetName swapped scores!"`
- Trap Card deploy: `"$deployerName set a Trap Card... 👀"`
- Trap Card triggered: `"$victimName triggered $deployerName's Trap Card!"`

### Sound Design

- Blue Shell impact: `GameSound.blueShellImpact` — file `assets/sounds/blue_shell_impact.mp3` already exists
- Other offensive items: Add a generic `GameSound.itemEffect` sound or reuse `GameSound.itemDeployed`

### Previous Story Intelligence

**From Story 5.2 (review status):**
- `handleItemAction()` and `handleItemDeployLocked()` in room.go lines 810-942 — this is where you add effect execution
- `ItemDeployedPayload` already has `Item`, `DeployerID`, `TargetID`, `Leaderboard` — extend with `EffectResult`
- `GameMessageListener` already handles `item.deployed` and `item.fizzled` — extend the handler
- Optimistic-then-confirm architecture: client animates immediately, server confirms
- Protocol sync pattern: Go structs are authoritative, Dart mirrors with `// SYNC WITH:` comment

**From Story 5.1 (done):**
- `ItemDropStep` pattern shows how chain steps interact with `ChainContext` and `GameState`
- `cascadePriority` map in `punishment_step.go` for cascade profile upgrades
- `GamePlayer.HeldItem` and `ClearItem()` already exist
- Item registry and deck in `item_effect.go` — constants and metadata ready to use

### Files to Create

| File | Purpose |
|------|---------|
| `rackup-server/internal/game/items/blue_shell.go` | Blue Shell ItemEffect |
| `rackup-server/internal/game/items/score_steal.go` | Score Steal ItemEffect |
| `rackup-server/internal/game/items/streak_breaker.go` | Streak Breaker ItemEffect |
| `rackup-server/internal/game/items/reverse.go` | Reverse ItemEffect |
| `rackup-server/internal/game/items/trap_card.go` | Trap Card ItemEffect |
| `rackup-server/internal/game/items/blue_shell_test.go` | Blue Shell tests |
| `rackup-server/internal/game/items/score_steal_test.go` | Score Steal tests |
| `rackup-server/internal/game/items/streak_breaker_test.go` | Streak Breaker tests |
| `rackup-server/internal/game/items/reverse_test.go` | Reverse tests |
| `rackup-server/internal/game/items/trap_card_test.go` | Trap Card tests |

### Files to Modify

| File | Changes |
|------|---------|
| `rackup-server/internal/game/item_effect.go` | Add `EffectResult` struct, update `ItemEffect.Execute()` signature to return `(*EffectResult, error)`, add `ItemEffectRegistry`, add 5 offensive item effect files (or `items/` subpackage) |
| `rackup-server/internal/game/game_state.go` | Add `OffHanded bool` to `GamePlayer`, add `ActiveTrapCard *TrapCardState` to `GameState`, clear OffHanded in `ProcessShot()`, populate `ActiveEffects` in `CalculateLeaderboard()` |
| `rackup-server/internal/game/engine.go` | Add `TrapCardActivated` + `TrapCardDeployerHash` to `ChainContext` |
| `rackup-server/internal/game/punishment_step.go` | Check `ActiveTrapCard` before normal draw |
| `rackup-server/internal/room/room.go` | Execute item effects in `handleItemDeployLocked()` |
| `rackup-server/internal/protocol/messages.go` | Add `EffectResultPayload`, extend `ItemDeployedPayload`, add trap fields to `TurnCompletePayload`, add `ActiveEffects` to `LeaderboardEntry` |
| `rackup/lib/core/protocol/messages.dart` | Mirror Go protocol changes |
| `rackup/lib/core/websocket/game_message_listener.dart` | Handle effect results, Trap Card activation, effect-specific event feed text |
| `rackup/lib/core/audio/sound_manager.dart` | Add `GameSound.itemEffect` if needed |
| `rackup/lib/core/audio/audio_listener.dart` | Wire Blue Shell impact sound on specific item type |

### Project Structure Notes — CRITICAL: Circular Import Avoidance

The architecture spec shows `internal/game/items/` as a separate package. However, this creates a **circular import** (`game` imports `items` for registry, `items` imports `game` for `GameState`). Two viable approaches:

**Option A (Recommended — consistent with codebase):** Keep item effect implementations in the `game` package as separate files (e.g., `blue_shell_effect.go`, `score_steal_effect.go`). This follows the same pattern as `punishment_step.go` and `item_drop_step.go` which are already in `game` package. No circular imports. Registry lives in `item_effect.go`.

**Option B (Architecture spec — requires init pattern):** Create `internal/game/items/` package. Each item file calls `game.RegisterItemEffect()` in its `init()` function. `room.go` adds blank import `_ "github.com/ducdo/rackup-server/internal/game/items"` to trigger registration. More complexity for no real benefit at current codebase size.

- All existing chain steps (`PunishmentStep`, `ItemDropStep`, `ShotResultStep`, `StreakUpdateStep`) live in the `game` package — Option A is the consistent choice
- The architecture spec's `items/` directory can be revisited if the game package grows too large

### References

- [Source: architecture.md#Item Effect Interface Pattern] — ItemEffect interface, one file per item, 4 execution patterns
- [Source: architecture.md#Item Deployment Data Flow] — room.go validates → executes → broadcasts
- [Source: architecture.md#Anytime item deployment] — queues behind active cascade
- [Source: architecture.md#Cross-Package Orchestration Rule] — room.go is sole orchestrator
- [Source: epics.md#Story 5.3] — AC for all 5 offensive items
- [Source: prd.md#FR36a-FR36g] — Individual item requirements
- [Source: ux-design-specification.md#Item Deployment Flow] — Targeting, The Eruption animation
- [Source: ux-design-specification.md#Fizzle Feedback] — Optimistic-then-confirm pattern

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
