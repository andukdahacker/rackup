# Story 3.5: Game Progression & Triple Points

Status: done

## Story

As a player,
I want the game to escalate in intensity as it progresses,
So that the final rounds feel climactic and high-stakes.

## Acceptance Criteria

1. **Given** a game is in progress **When** the Progress/Tier Bar renders (~60dp fixed height, top of screen) **Then** it displays: tier tag badge (left), progress bar fill (4dp, color matches current tier), round label "R{current}/{total}" format (right)

2. **Given** the game is in the first 30% of rounds **When** the tier is evaluated **Then** the tier is "Mild" with teal color (#0D2B3E) and the tier tag badge displays "MILD"

3. **Given** the game is between 30-70% of rounds **When** the tier transitions **Then** the tier changes to "Medium" with amber color (#3D2008), a 500ms crossfade via AnimatedContainer transitions the scaffold background, and the tier tag badge updates to "MEDIUM"

4. **Given** the game is in the final 30% of rounds **When** the tier transitions **Then** the tier changes to "Spicy" with deep red color (#3D0A0A) and the tier tag badge updates to "SPICY"

5. **Given** the game enters the final 3 rounds **When** triple-point scoring activates (FR16) **Then** all point values are tripled: base shots, streak bonuses, and mission bonuses (FR31), all players receive a notification of triple-point activation, the Progress/Tier Bar shows a pulsing gold "3X" badge with red background, and gold accents (#FFD700) appear in the tier color scheme

## Tasks / Subtasks

- [x] Task 1: Server — Triple-points multiplier in scoring engine (AC: #5)
  - [x] 1.1 Add `IsTriplePoints()` method to `GameState` — returns true when `CurrentRound > RoundCount - 3` (final 3 rounds)
  - [x] 1.2 Modify `ProcessShot()` in `game_state.go` — multiply `points` (base + streak bonus) by 3 when `IsTriplePoints()` returns true
  - [x] 1.3 Add `IsTriplePoints bool` field to `TurnResult` struct
  - [x] 1.4 Add `TriplePointsActivated bool` field to `ChainContext` — true only on the first turn where triple points become active (not every triple-point turn)
  - [x] 1.5 Update `ShotResultStep.Execute()` — CRITICAL TIMING: capture `preShotTriple := ctx.gameState.IsTriplePoints()` BEFORE calling `ctx.gameState.ProcessShot()`. After `ProcessShot()` returns, `CurrentRound` may have advanced (due to `AdvanceTurn()` inside `ProcessShot()`). Then check `postShotTriple := ctx.gameState.IsTriplePoints()`. Set `ctx.TriplePointsActivated = !preShotTriple && postShotTriple`. This means activation fires when `AdvanceTurn()` moves into triple territory — the notification shows at the START of the first triple-point round, and that round's shots will be triple-scored.
  - [x] 1.6 When `TriplePointsActivated`, set `ctx.CascadeProfile = "triple_points"` (overrides streak_milestone if both occur)
  - [x] 1.7 Write table-driven Go tests: normal scoring, triple-point scoring (3x base, 3x streak bonus), boundary round detection, activation flag fires exactly once

- [x] Task 2: Server — Wire protocol update (AC: #5)
  - [x] 2.1 Add `IsTriplePoints bool` and `TriplePointsActivated bool` fields to `TurnCompletePayload` in `protocol/messages.go`
  - [x] 2.2 Populate fields in `room.go` where `TurnCompletePayload` is constructed from `chainCtx` (~line 744). Map: `IsTriplePoints` from `result.IsTriplePoints` (TurnResult), `TriplePointsActivated` from `chainCtx.TriplePointsActivated` (ChainContext)
  - [x] 2.3 Also update the undo broadcast path in `room.go` (~line 720) — when constructing the corrected `TurnCompletePayload` after undo, populate `IsTriplePoints` from the reverted `gs.IsTriplePoints()` and set `TriplePointsActivated: false` (undo never triggers activation)

- [x] Task 3: Client — Protocol and state updates (AC: #5)
  - [x] 3.1 Add `isTriplePoints` and `triplePointsActivated` fields to `TurnCompletePayload` in `messages.dart` (with defaults `false`)
  - [x] 3.2 Add `isTriplePoints` field to `GameActive` state in `game_state.dart` (with `copyWith` and `props`)
  - [x] 3.3 Add `isTriplePoints` and `triplePointsActivated` fields to `GameTurnCompleted` event in `game_event.dart`
  - [x] 3.4 Update `GameBloc._onGameTurnCompleted` — add `isTriplePoints: event.isTriplePoints` to the `current.copyWith(...)` call in the `emit()` statement
  - [x] 3.5 Update `GameMessageListener._handleMessage` — map `isTriplePoints` and `triplePointsActivated` from payload to event
  - [x] 3.6 Add `'triple_points' => const Duration(milliseconds: 500)` to `CascadeTiming.delayFor()` switch expression in `cascade_timing.dart` (Dart 3 switch expression syntax, matching existing pattern)

- [x] Task 4: Client — Tier transition animation (AC: #3, #4)
  - [x] 4.1 Wrap `ProgressTierBar` tier badge and progress bar color in `AnimatedContainer` with 500ms duration using `RackUpGameThemeData.tierTransitionDuration`
  - [x] 4.2 Implement tier-based scaffold background crossfade. Currently `player_screen.dart` and `referee_screen.dart` use static `Scaffold(backgroundColor: RackUpColors.canvas)`. Replace with `AnimatedContainer` wrapping the scaffold body, using `RackUpGameTheme.of(context).backgroundColor` and `RackUpGameTheme.of(context).tierTransitionDuration`. Leave `game_page.dart` scaffold static (it only shows during `GameInitial` loading state).
  - [x] 4.3 Respect `RackUpGameThemeData.animationsEnabled` — use `Duration.zero` when reduced motion is on

- [x] Task 5: Client — Pulsing "3X" badge on Progress/Tier Bar (AC: #5)
  - [x] 5.1 Add `isTriplePoints` parameter to `ProgressTierBar` constructor
  - [x] 5.2 When `isTriplePoints == true`, render a pulsing gold "3X" badge: use `RackUpColors.streakGold` (gold #FFD700) text on `RackUpColors.tierSpicy` (red #3D0A0A) background, positioned next to the tier tag badge
  - [x] 5.3 Pulse animation: scale 1.0 <-> 1.1 over 1.5s repeating — requires `AnimationController` with `repeat(reverse: true)` + `CurvedAnimation`. `ProgressTierBar` MUST become a `StatefulWidget` to manage the controller lifecycle (dispose on unmount). Do NOT use `TweenAnimationBuilder` (it runs once, not repeating).
  - [x] 5.4 When `isTriplePoints`, use `RackUpColors.tierSpicyAccent` (gold) for the progress bar fill color
  - [x] 5.5 Update Semantics label: "Round X of Y, SPICY tier, Triple points active"
  - [x] 5.6 Respect `animationsEnabled` — skip pulse when reduced motion is on (show static "3X" badge instead)

- [x] Task 6: Client — Triple Points activation overlay (AC: #5)
  - [x] 6.1 Create `triple_points_overlay.dart` in `features/game/view/widgets/` — full-screen overlay with "TRIPLE POINTS" text (Oswald Bold 42dp, gold #FFD700) and "3X" (Oswald Bold 64dp, gold)
  - [x] 6.2 Use The Eruption animation pattern: scale 1.0 -> 1.4 -> 1.0 (300ms) on the "3X" text, with gold radial glow
  - [x] 6.3 Auto-dismiss after 2-second hold (no user interaction required)
  - [x] 6.4 Trigger in `game_page.dart`: add a `BlocListener<GameBloc, GameState>` (currently only uses `BlocBuilder`). Use `listenWhen: (prev, curr) => prev is GameActive && curr is GameActive && !prev.isTriplePoints && curr.isTriplePoints` to detect the transition. In the listener callback, show the overlay via `showGeneralDialog` or an `OverlayEntry`. Alternative: add a transient `triplePointsJustActivated` bool to `GameActive` that is true for exactly one emission, then auto-cleared on the next event.
  - [x] 6.5 This is a "Full-Screen Transition (major moment)" per UX spec — reserve for max 1-2 per game
  - [x] 6.6 Respect `animationsEnabled` — show static overlay with shorter hold when reduced motion is on

- [x] Task 7: Tests (all ACs)
  - [x] 7.1 Go unit tests for `IsTriplePoints()` boundary cases (10 rounds: R8=true, R7=false; 5 rounds: R3=true, R2=false; 15 rounds: R13=true, R12=false; 3 rounds: R1=true — ALL rounds triple)
  - [x] 7.2 Go unit tests for triple scoring: 3x base (9 pts), 3x streak bonuses, 3x combined
  - [x] 7.3 Go unit tests for `TriplePointsActivated` — fires on first triple-point turn only, not subsequent
  - [x] 7.4 Go engine test: chain sets `CascadeProfile = "triple_points"` on activation turn
  - [x] 7.5 Dart `GameBloc` tests: `isTriplePoints` state transitions
  - [x] 7.6 Dart widget test: `ProgressTierBar` renders "3X" badge when `isTriplePoints: true`
  - [x] 7.7 Dart widget test: `ProgressTierBar` tier badge animates on tier change
  - [x] 7.8 Dart widget test: `TriplePointsOverlay` renders and auto-dismisses
  - [x] 7.9 Dart widget test: reduced motion — static badge, no pulse

## Dev Notes

### Architecture Compliance

- **Server-authoritative**: Triple-point detection and score multiplication MUST happen server-side in `game_state.go`. The client receives the already-tripled `pointsAwarded` and `newScore` — it does NOT multiply locally.
- **Consequence chain**: The `ShotResultStep` handles scoring via `ProcessShot()`. Triple-point logic belongs in `ProcessShot()`, not a separate chain step. The activation detection (`TriplePointsActivated`) belongs in `ShotResultStep.Execute()` since it needs pre/post comparison.
- **Triple points vs tier**: `isTriplePoints` is a SEPARATE boolean from `EscalationTier`. Triple points overlap with the Spicy tier (final 30% vs final 3 rounds) but they are orthogonal concepts: tier = visual theme, triple = scoring multiplier. Do NOT add a new enum value to `EscalationTier`.
- **AdvanceTurn() timing — two separate concerns**: (1) **Scoring correctness**: The `IsTriplePoints()` check inside `ProcessShot()` naturally executes BEFORE `AdvanceTurn()` since the scoring code (line 173-176) precedes `gs.AdvanceTurn()` (line 187). No special ordering needed — just add `if gs.IsTriplePoints() { points *= 3 }` between the points calculation and `player.Score += points`. (2) **Activation detection**: In `ShotResultStep.Execute()`, capture `preShotTriple` BEFORE calling `ProcessShot()`, then compare with `postShotTriple` after. After `ProcessShot()`, `CurrentRound` may have advanced into triple territory. This is the desired behavior — activation fires at the START of the first triple-point round. See Task 1.5.
- **Tier is client-derived — no server changes needed for tier**: `computeTier()` in `game_tier.dart` derives tier from `currentRound/roundCount` client-side. Do NOT add tier fields to the wire protocol. Only `isTriplePoints` and `triplePointsActivated` are new server fields.
- **Protocol sync**: Go `protocol/messages.go` is canonical. Dart `core/protocol/messages.dart` mirrors it with `// SYNC WITH:` header. Add fields to both.
- **Sealed state pattern**: `GameActive` uses `copyWith()` with Equatable props. New `isTriplePoints` field must be in both.
- **Bloc event naming**: Server events use past tense. `GameTurnCompleted` already exists — just add fields.

### Key Files to Modify

**Server (Go):**
| File | Change |
|------|--------|
| `rackup-server/internal/game/game_state.go` | Add `IsTriplePoints()`, modify `ProcessShot()` for 3x multiplier, add `IsTriplePoints` to `TurnResult` |
| `rackup-server/internal/game/engine.go` | Add `TriplePointsActivated` to `ChainContext`, update `ShotResultStep` |
| `rackup-server/internal/protocol/messages.go` | Add `IsTriplePoints` and `TriplePointsActivated` to `TurnCompletePayload` |
| `rackup-server/internal/room/room.go` | Map new fields from `chainCtx` to `TurnCompletePayload` |
| `rackup-server/internal/game/game_state_test.go` | Triple scoring + boundary tests |
| `rackup-server/internal/game/engine_test.go` | Activation flag + cascade profile tests |

**Client (Flutter/Dart):**
| File | Change |
|------|--------|
| `rackup/lib/core/protocol/messages.dart` | Add `isTriplePoints`, `triplePointsActivated` to `TurnCompletePayload` |
| `rackup/lib/features/game/bloc/game_event.dart` | Add `isTriplePoints`, `triplePointsActivated` to `GameTurnCompleted` |
| `rackup/lib/features/game/bloc/game_state.dart` | Add `isTriplePoints` to `GameActive` |
| `rackup/lib/features/game/bloc/game_bloc.dart` | Pass `isTriplePoints` through in `_onGameTurnCompleted` |
| `rackup/lib/core/websocket/game_message_listener.dart` | Map new fields from payload to event |
| `rackup/lib/core/cascade/cascade_timing.dart` | Add `"triple_points"` profile |
| `rackup/lib/features/game/view/widgets/progress_tier_bar.dart` | Add `isTriplePoints` param, pulsing "3X" badge, animated tier transitions, gold accent |
| `rackup/lib/features/game/view/widgets/triple_points_overlay.dart` | **NEW** — full-screen Eruption overlay |
| `rackup/lib/features/game/view/game_page.dart` | Add `BlocListener` for triple-points activation → show overlay |
| `rackup/lib/features/game/view/player_screen.dart` | Replace static `RackUpColors.canvas` background with `AnimatedContainer` using tier background color |
| `rackup/lib/features/game/view/referee_screen.dart` | Replace static `RackUpColors.canvas` background with `AnimatedContainer` using tier background color |

### Server Scoring Reference

`ProcessShot()` modification in `game_state.go` — insert `if gs.IsTriplePoints() { points *= 3 }` between the points calculation and `player.Score += points`:
```go
if result == "made" {
    player.Streak++
    points = 3 + streakBonus(player.Streak)
    if gs.IsTriplePoints() {
        points *= 3
    }
    player.Score += points
}
```

`IsTriplePoints()` boundary: `CurrentRound > RoundCount - 3`. Examples: 10 rounds → R8-10 triple; 5 rounds → R3-5 triple; RoundCount <= 3 → ALL rounds triple.

### Previous Story Intelligence (Story 3.4)

**Patterns to reuse:**
- `ProgressTierBar` is currently a `StatelessWidget` — MUST become `StatefulWidget` to manage the `AnimationController` for the pulsing "3X" badge
- Story 3.4 established `RepaintBoundary` for animation isolation — consider wrapping the pulsing badge
- `RackUpGameThemeData.animationsEnabled` must be checked — Story 3.4 confirmed this pattern works
- `google_fonts` package: use `GoogleFonts.oswald()` for all text (fontWeight: FontWeight.w700 for Bold, FontWeight.w600 for SemiBold)

**Font fix required:**
- `ProgressTierBar` currently uses `fontFamily: 'Oswald'` inline style (lines 61, 89) which silently falls back to the system font. Story 3.4 identified this as unreliable. While converting to `StatefulWidget`, migrate ALL `TextStyle(fontFamily: 'Oswald', ...)` to `GoogleFonts.oswald(...)` calls.

**Avoid:**
- Don't change existing tier bar layout beyond what's needed — ADD the "3X" badge, animation wrappers, and font migration

### Project Structure Notes

- All new widget files go in `rackup/lib/features/game/view/widgets/`
- All new test files mirror `lib/` under `rackup/test/`
- No cross-feature imports except through `core/`
- Protocol types (payloads) never appear in Bloc states — use domain model fields
- `test/helpers/factories.dart` currently has no game-related factories (only lobby/room helpers). Create inline test data for game tests or add game factories if needed. Do NOT expect existing game factories to exist.
- ADD tests to existing test files (`game_state_test.go`, `engine_test.go`, `game_bloc_test.dart`) — do not create new test files for these
- Update the `CascadeProfile` comment in `engine.go` (line 31) to include `"triple_points"` in the profile list

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.5]
- [Source: _bmad-output/planning-artifacts/architecture.md#Consequence Chain Pipeline]
- [Source: _bmad-output/planning-artifacts/architecture.md#Client Architecture - GameBloc]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Escalation Palette]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Animation Language - The Eruption]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#State Transition Patterns]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Component 16 - Progress/Tier Bar]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Fixed existing test regression: `newTestGameState()` used 3 rounds (all triple territory), updated to 10 rounds
- Fixed pulsing badge test: `pumpAndSettle` times out on repeating animations, replaced with `pump()`
- Added guard in `StreakUpdateStep` to not override `triple_points` cascade profile with `streak_milestone`

### Completion Notes List
- Task 1: Server scoring engine — `IsTriplePoints()`, 3x multiplier in `ProcessShot()`, activation detection in `ShotResultStep`
- Task 2: Wire protocol — `IsTriplePoints` and `TriplePointsActivated` fields on `TurnCompletePayload`, undo path updated
- Task 3: Client protocol/state — fields mirrored in Dart `TurnCompletePayload`, `GameActive`, `GameTurnCompleted`, `GameMessageListener`, `CascadeTiming`
- Task 4: Tier transition animation — `AnimatedContainer` on tier badge, `TweenAnimationBuilder` on progress bar, scaffold background crossfade in player/referee screens
- Task 5: Pulsing 3X badge — `ProgressTierBar` converted to `StatefulWidget` with `AnimationController`, gold badge on red bg, `RepaintBoundary` isolation
- Task 6: Triple Points overlay — Eruption pattern (scale 1.0→1.4→1.0), `BlocListener` in `game_page.dart`, `showGeneralDialog`, auto-dismiss 2s
- Task 7: Full test coverage — 12 boundary/scoring Go tests, 4 activation/cascade engine tests, 2 GameBloc state transition tests, 6 widget tests

### File List

**Server (Go):**
- `rackup-server/internal/game/game_state.go` — Modified: added `IsTriplePoints()`, `IsTriplePoints` on `TurnResult`, 3x multiplier in `ProcessShot()`
- `rackup-server/internal/game/engine.go` — Modified: added `TriplePointsActivated` to `ChainContext`, updated `ShotResultStep.Execute()`, guarded `StreakUpdateStep`
- `rackup-server/internal/protocol/messages.go` — Modified: added `IsTriplePoints`, `TriplePointsActivated` to `TurnCompletePayload`
- `rackup-server/internal/room/room.go` — Modified: wired new fields in `broadcastTurnCompleteLocked` and undo path
- `rackup-server/internal/game/game_state_test.go` — Modified: added triple-point boundary, scoring, and field tests
- `rackup-server/internal/game/engine_test.go` — Modified: added activation, cascade profile, and override tests

**Client (Flutter/Dart):**
- `rackup/lib/core/protocol/messages.dart` — Modified: added `isTriplePoints`, `triplePointsActivated` to `TurnCompletePayload`
- `rackup/lib/features/game/bloc/game_event.dart` — Modified: added fields to `GameTurnCompleted`
- `rackup/lib/features/game/bloc/game_state.dart` — Modified: added `isTriplePoints` to `GameActive` with `copyWith`/`props`
- `rackup/lib/features/game/bloc/game_bloc.dart` — Modified: passes `isTriplePoints` through in `_onGameTurnCompleted`
- `rackup/lib/core/websocket/game_message_listener.dart` — Modified: maps new fields from payload to event
- `rackup/lib/core/cascade/cascade_timing.dart` — Modified: added `triple_points` profile (500ms)
- `rackup/lib/features/game/view/widgets/progress_tier_bar.dart` — Modified: converted to StatefulWidget, AnimatedContainer tier badge, pulsing 3X badge, font migration to GoogleFonts.oswald
- `rackup/lib/features/game/view/widgets/triple_points_overlay.dart` — **NEW**: Eruption overlay with auto-dismiss
- `rackup/lib/features/game/view/game_page.dart` — Modified: added BlocListener for triple-points activation overlay
- `rackup/lib/features/game/view/player_screen.dart` — Modified: AnimatedContainer scaffold background, isTriplePoints pass-through
- `rackup/lib/features/game/view/referee_screen.dart` — Modified: AnimatedContainer scaffold background, isTriplePoints pass-through

**Tests:**
- `rackup/test/features/game/bloc/game_bloc_test.dart` — Modified: added isTriplePoints state transition tests
- `rackup/test/features/game/view/widgets/progress_tier_bar_test.dart` — Modified: added 3X badge, semantics, animation, reduced motion tests
- `rackup/test/features/game/view/widgets/triple_points_overlay_test.dart` — **NEW**: overlay render and auto-dismiss tests
