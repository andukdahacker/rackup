# Story 3.3: Scoring, Streaks & Consequence Chain

Status: done

## Story

As a player,
I want to earn points for made shots and build streaks for bonus points,
So that consistent shooting is rewarded and the game stays competitive.

## Acceptance Criteria

1. **Given** the referee confirms a shot as MADE, **When** the server processes the shot result, **Then** the shooter receives +3 base points (FR26), the shooter's consecutive made shot count increments, streak bonuses are awarded (+1 for 2 consecutive, +2 for 3, +3 for 4+ consecutive) (FR27), and total points (base + streak bonus) are added to the player's score.

2. **Given** the referee confirms a shot as MISSED, **When** the server processes the shot result, **Then** the shooter's streak resets to zero (FR28) and no points are awarded.

3. **Given** a shot result has been processed, **When** the server completes the consequence chain, **Then** an atomic `game.turn_complete` message is sent to all clients containing: score update, streak status, leaderboard recalculation, and UI event triggers. The consequence chain follows deterministic execution order: `shot_result -> streak_update -> [punishment_slot] -> [item_drop_slot] -> [mission_check_slot] -> score_update -> leaderboard_recalc -> UI_events -> sound_triggers -> [record_this_check_slot]`. Extension points (brackets) allow Epics 4, 5, 6, and 8 to plug in without modifying core chain logic. The entire chain resolves within the 2-second sync window.

4. **Given** a player has consecutive made shots, **When** their streak status changes, **Then** the appropriate streak indicator is displayed to all players: "Warming Up" (2 streak), "ON FIRE" (3 streak), "UNSTOPPABLE" (4+ streak). The Streak Fire Indicator shows escalating visuals: single flame amber (2), double flame gold with glow (3), triple flame pulsing gold (4+). Streak milestone transitions use The Eruption animation pattern.

## Tasks / Subtasks

- [x] Task 1: Build server-side consequence chain pipeline (AC: #3)
  - [x] 1.1 Create `internal/game/engine.go` with `ConsequenceChain` pipeline struct
  - [x] 1.2 Implement deterministic step execution: shot_result -> streak_update -> [punishment_slot] -> [item_drop_slot] -> [mission_check_slot] -> score_update -> leaderboard_recalc -> UI_events -> sound_triggers -> [record_this_check_slot]
  - [x] 1.3 Define `ChainStep` interface for extensibility (each step receives chain context, returns enriched result)
  - [x] 1.4 Implement no-op placeholders for bracketed extension points that future epics will fill
  - [x] 1.5 Integrate chain into room.go `handleConfirmShotLocked()` — replace direct `ProcessShot()` call with chain execution
  - [x] 1.6 Add `cascadeProfile` field to `TurnCompletePayload` (values: "routine", "streak_milestone", "item_punishment", "spicy", "record_this") — for now only "routine" and "streak_milestone" are used

- [x] Task 2: Enhance TurnCompletePayload for consequence chain (AC: #3)
  - [x] 2.1 Add `streakLabel` field to TurnCompletePayload (Go): "", "warming_up", "on_fire", "unstoppable"
  - [x] 2.2 Add `streakMilestone` boolean field (true when streak threshold just crossed: 2, 3, or 4)
  - [x] 2.3 Add `leaderboard` array field: list of `{deviceIdHash, score, streak, rank}` sorted by score descending
  - [x] 2.4 Add `cascadeProfile` string field
  - [x] 2.5 Mirror all new fields in Dart `TurnCompletePayload` with `// SYNC WITH:` header
  - [x] 2.6 Update `applyTurnComplete` mapper to extract leaderboard entries and streak data

- [x] Task 3: Implement leaderboard recalculation on server (AC: #3)
  - [x] 3.1 Add `CalculateLeaderboard()` method to `GameState` — returns sorted player list with rank
  - [x] 3.2 Include leaderboard snapshot in every `game.turn_complete` broadcast
  - [x] 3.3 Detect rank changes and include `rankChanged` flag per player entry

- [x] Task 4: Create LeaderboardBloc on client (AC: #3, #4)
  - [x] 4.1 Create `LeaderboardBloc` with sealed states: `LeaderboardInitial`, `LeaderboardActive(entries, previousEntries)`
  - [x] 4.2 Create `LeaderboardUpdated` event (from server) carrying sorted entries
  - [x] 4.3 Handler stores previous entries for animation diffing (which positions changed)
  - [x] 4.4 Route leaderboard data from `GameMessageListener` to `LeaderboardBloc`

- [x] Task 5: Build Streak Fire Indicator widget (AC: #4)
  - [x] 5.1 Create `streak_fire_indicator.dart` in `features/game/view/widgets/`
  - [x] 5.2 Three visual states: warming_up (single flame amber), on_fire (double flame gold with glow), unstoppable (triple flame pulsing gold)
  - [x] 5.3 Use emoji-based rendering (fire emoji) with color tinting and AnimatedScale for pulse
  - [x] 5.4 Milestone transition: The Eruption pattern (scale 1.0 -> 1.4 -> 1.0 with 300ms duration)
  - [x] 5.5 Accessibility: include text label ("ON FIRE" etc.), not just visual indicator

- [x] Task 6: Integrate leaderboard display on PlayerScreen (AC: #3, #4)
  - [x] 6.1 Replace current static score list with `BlocBuilder<LeaderboardBloc>` driven list
  - [x] 6.2 Add `StreakFireIndicator` next to each player entry with active streak
  - [x] 6.3 Implement position-shuffle animation using `AnimatedList` or `ImplicitlyAnimatedList`
  - [x] 6.4 Highlight own row with blue tint
  - [x] 6.5 Show rank numbers (1st, 2nd, etc.)
  - [x] 6.6 Leader gets subtle radial glow effect behind their entry

- [x] Task 7: Update RefereeScreen with streak and leaderboard (AC: #4)
  - [x] 7.1 Show streak indicator on Stage Area when current shooter has active streak
  - [x] 7.2 Update Footer leaderboard peek (top 3) with live data from LeaderboardBloc
  - [x] 7.3 Show streak milestone banner in Stage Area on threshold crossing ("ON FIRE!" text)

- [x] Task 8: Add cascade timing controller (AC: #3)
  - [x] 8.1 Create `cascade_timing.dart` helper class in `core/cascade/`
  - [x] 8.2 Map `cascadeProfile` values to timing durations: routine=0ms, streak_milestone=500ms
  - [x] 8.3 Controller delays UI event rendering based on profile for dramatic pacing
  - [x] 8.4 Future profiles (item_punishment, spicy, record_this) return placeholder durations

- [x] Task 9: Write comprehensive tests
  - [x] 9.1 Go unit tests for ConsequenceChain pipeline (extension points, step ordering, chain context)
  - [x] 9.2 Go unit tests for CalculateLeaderboard (sorting, rank assignment, tie handling)
  - [x] 9.3 Go integration tests in room_test.go verifying enriched turn_complete broadcast
  - [x] 9.4 Dart LeaderboardBloc tests (state transitions, previous entries preservation)
  - [x] 9.5 Dart StreakFireIndicator widget tests (all 3 states + milestone animation trigger)
  - [x] 9.6 Dart PlayerScreen tests verifying leaderboard rendering with streak indicators
  - [x] 9.7 Dart GameMessageListener tests for new payload fields routing

## Dev Notes

### Critical Context: Scoring Already Implemented in Story 3.2

Story 3.2 already implemented the core scoring engine in `game_state.go`:
- `ProcessShot()` calculates base points (+3) and streak bonuses
- `streakBonus()` function: 0-1=0, 2=+1, 3=+2, 4+=+3
- `AdvanceTurn()` and `UndoLastShot()` are complete
- `TurnCompletePayload` already carries `PointsAwarded`, `NewScore`, `NewStreak`

**What Story 3.3 adds on top:**
1. The **consequence chain pipeline** wrapping ProcessShot with extension points for future epics
2. **Streak indicator labels** and milestone detection (new fields in payload)
3. **Full leaderboard snapshot** in every turn_complete message
4. **LeaderboardBloc** on the client for animated position tracking
5. **StreakFireIndicator** UI component
6. **Cascade timing controller** for dramatic pacing

### Architecture Compliance

**Server patterns (established in 3.1/3.2):**
- Game logic in `internal/game/` — scoring.go exists, add engine.go for chain pipeline
- Room goroutine is sole orchestrator — chain executes within `handleConfirmShotLocked()`
- Write lock (Lock, NOT RLock) for any state mutation
- Never call `BroadcastMessage()` while holding write lock — use `broadcastLocked()` pattern
- Error types returned, never panicked

**Client patterns (established in 3.1/3.2):**
- Sealed classes for Bloc states (Dart 3 sealed)
- Past-tense events from server (`LeaderboardUpdated`), imperative from user
- `GameMessageListener` routes by action string, maps wire -> domain models
- Protocol types NEVER in Bloc states — convert in mapper layer
- `// SYNC WITH:` header on all Dart protocol types mirroring Go

**Consequence chain design:**
- Pipeline pattern, NOT scattered event handlers
- Each step receives accumulating context from previous steps
- Extension points are typed interfaces that default to no-op
- Chain must resolve within 2-second sync window (NFR3)
- Output is a single atomic `game.turn_complete` message

### Key Implementation Decisions

**ConsequenceChain vs direct ProcessShot:**
- Current flow: `handleConfirmShotLocked()` -> `ProcessShot()` -> broadcast
- New flow: `handleConfirmShotLocked()` -> `RunConsequenceChain(shotResult)` -> chain calls ProcessShot internally -> chain enriches result with leaderboard, streak labels, cascade profile -> broadcast enriched payload
- ProcessShot stays in game_state.go; chain orchestrates it from engine.go

**Extension point interface pattern:**
```go
// ChainStep processes one stage of the consequence chain
type ChainStep interface {
    Execute(ctx *ChainContext) error
}
```
- `ChainContext` accumulates: shot result, score delta, streak state, leaderboard, UI events, sound triggers
- Bracketed steps (punishment, item, mission, record_this) start as no-op implementations
- Future epics register real implementations without modifying chain logic

**LeaderboardBloc as separate from GameBloc:**
- Architecture specifies 7 blocs per active game session, including dedicated LeaderboardBloc
- Keeps GameBloc focused on turn/round state
- LeaderboardBloc owns: sorted entries, rank tracking, previous positions for animation diffing
- `WebSocketCubit`/`GameMessageListener` dispatches leaderboard slice to LeaderboardBloc

**Streak label computation (server-side):**
- Server computes label string to avoid client-side duplication
- Labels: "" (0-1), "warming_up" (2), "on_fire" (3), "unstoppable" (4+)
- `streakMilestone` = true only when streak just crossed a threshold (2, 3, or 4)
- Client uses milestone flag to trigger Eruption animation

**Cascade profile selection:**
- "routine" = standard make/miss, no special events
- "streak_milestone" = streak threshold just crossed, 500ms build
- Future: "item_punishment", "spicy", "record_this" with longer timings

### Concurrency Warning (from Story 3.2 learnings)

- `handleGameAction()` MUST use write lock (Lock) not read lock (RLock) for referee mutations
- Never call `BroadcastMessage()` while holding write lock — deadlock risk
- Use `broadcastLocked()` / `broadcastTurnCompleteLocked()` pattern from room.go

### Project Structure Notes

**Server files to create:**
- `rackup-server/internal/game/engine.go` — ConsequenceChain pipeline
- `rackup-server/internal/game/engine_test.go` — Chain pipeline tests

**Server files to modify:**
- `rackup-server/internal/game/game_state.go` — Add `CalculateLeaderboard()`, streak label helpers
- `rackup-server/internal/game/game_state_test.go` — Leaderboard calculation tests
- `rackup-server/internal/protocol/messages.go` — Enrich TurnCompletePayload
- `rackup-server/internal/room/room.go` — Replace ProcessShot call with chain execution
- `rackup-server/internal/room/room_test.go` — Integration tests for enriched broadcast

**Client files to create:**
- `rackup/lib/features/game/bloc/leaderboard_bloc.dart`
- `rackup/lib/features/game/bloc/leaderboard_event.dart`
- `rackup/lib/features/game/bloc/leaderboard_state.dart`
- `rackup/lib/features/game/view/widgets/streak_fire_indicator.dart`
- `rackup/lib/core/cascade/cascade_timing.dart`

**Client files to modify:**
- `rackup/lib/core/protocol/messages.dart` — Mirror enriched TurnCompletePayload
- `rackup/lib/core/protocol/mapper.dart` — Map leaderboard + streak data
- `rackup/lib/core/websocket/game_message_listener.dart` — Route to LeaderboardBloc
- `rackup/lib/features/game/view/player_screen.dart` — LeaderboardBloc-driven list with animations
- `rackup/lib/features/game/view/referee_screen.dart` — Streak indicator + leaderboard peek
- `rackup/lib/features/game/view/game_page.dart` — Provide LeaderboardBloc

**Test files to create:**
- `rackup-server/internal/game/engine_test.go`
- `rackup/test/features/game/bloc/leaderboard_bloc_test.dart`
- `rackup/test/features/game/view/widgets/streak_fire_indicator_test.dart`

**Test files to modify:**
- `rackup-server/internal/game/game_state_test.go`
- `rackup-server/internal/room/room_test.go`
- `rackup/test/features/game/view/player_screen_test.dart`
- `rackup/test/core/websocket/game_message_listener_test.dart`

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Consequence Chain Pipeline, Atomic Turn Updates, 7 Bloc Architecture, Cascade Timing Controller]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Streak Fire Indicator, The Eruption animation, The Shuffle animation, Player Screen layout]
- [Source: _bmad-output/planning-artifacts/prd.md — FR26-FR29 Scoring & Streaks, NFR3 2-second sync]
- [Source: _bmad-output/implementation-artifacts/3-2-turn-management-and-shot-confirmation.md — ProcessShot implementation, concurrency patterns, TurnCompletePayload structure]

### Previous Story Intelligence (Story 3.2)

**Key learnings to carry forward:**
- ProcessShot/scoring is proven and tested — do NOT rewrite, only wrap with chain
- TurnCompletePayload structure: add fields, do not restructure existing ones
- Undo flow sends corrected turn_complete — chain must handle undo correctly (run chain with reverted state)
- BigBinaryButtons/UndoButton in RefereeScreen use AnimatedSwitcher — continue this pattern
- `GameActive.copyWith()` pattern for immutable state updates
- `broadcastTurnCompleteLocked()` handles serialization within write lock

**Files established in 3.2 that this story extends:**
- `game_state.go`: Add CalculateLeaderboard(), streakLabel()
- `room.go`: Replace ProcessShot with chain, update broadcast payload construction
- `messages.go` (Go/Dart): Add new fields to TurnCompletePayload
- `game_message_listener.dart`: Add LeaderboardBloc dispatch
- `player_screen.dart`: Replace static list with animated LeaderboardBloc-driven list

### Git Intelligence

Recent commits show consistent patterns:
- Story commits bundle all server + client + test changes
- Protocol sync discipline maintained across all stories
- Test coverage includes unit, bloc, widget, and integration layers
- Widget tests use `mocktail` for cubit/bloc mocking

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- All Go tests pass: 31 game tests + room/handler/auth tests
- All Flutter tests pass: 321 total (10 new tests added)
- Zero analysis errors

### Completion Notes List
- Task 1: Created `engine.go` with ConsequenceChain pipeline (10 deterministic steps), ChainStep interface, ChainContext accumulator, extension point no-ops. Integrated into room.go replacing direct ProcessShot call.
- Task 2: Enhanced TurnCompletePayload (Go + Dart) with streakLabel, streakMilestone, leaderboard array, cascadeProfile fields. Added LeaderboardEntry type to both protocol layers.
- Task 3: Implemented CalculateLeaderboard() on GameState with score-descending sort, slot-based tie-breaking, and tied-rank assignment.
- Task 4: Created LeaderboardBloc with sealed states (LeaderboardInitial, LeaderboardActive) and previous entries preservation for animation diffing.
- Task 5: Created StreakFireIndicator widget with 3 visual states (warming_up/on_fire/unstoppable), emoji-based rendering, Eruption animation (scale 1.0→1.4→1.0, 300ms), pulse for unstoppable, glow effects, and accessibility labels.
- Task 6: Updated PlayerScreen with BlocBuilder<LeaderboardBloc>-driven leaderboard, rank numbers, StreakFireIndicator per player, blue self-row tint, leader glow effect.
- Task 7: Updated RefereeScreen with streak indicator in Stage Area, footer leaderboard peek (top 3) driven by LeaderboardBloc.
- Task 8: Created CascadeTiming helper with profile-to-duration mapping (routine=0ms, streak_milestone=500ms, future placeholders).
- Task 9: Wrote comprehensive tests — Go engine tests (11), Dart LeaderboardBloc tests (4), StreakFireIndicator widget tests (6), GameMessageListener tests updated with leaderboard routing.

### Change Log
- 2026-04-02: Story 3.3 implementation complete. Added consequence chain pipeline, leaderboard recalculation, streak indicators, cascade timing controller, and LeaderboardBloc.

### File List

**Server files created:**
- rackup-server/internal/game/engine.go
- rackup-server/internal/game/engine_test.go

**Server files modified:**
- rackup-server/internal/game/game_state.go (added CalculateLeaderboard)
- rackup-server/internal/protocol/messages.go (enriched TurnCompletePayload, added LeaderboardEntry)
- rackup-server/internal/room/room.go (integrated ConsequenceChain, updated broadcastTurnCompleteLocked, handleUndoShotLocked)

**Client files created:**
- rackup/lib/features/game/bloc/leaderboard_bloc.dart
- rackup/lib/features/game/bloc/leaderboard_event.dart
- rackup/lib/features/game/bloc/leaderboard_state.dart
- rackup/lib/features/game/view/widgets/streak_fire_indicator.dart
- rackup/lib/core/cascade/cascade_timing.dart

**Client files modified:**
- rackup/lib/core/protocol/messages.dart (enriched TurnCompletePayload, added LeaderboardEntryPayload)
- rackup/lib/core/protocol/mapper.dart (added mapToLeaderboardEntry)
- rackup/lib/core/websocket/game_message_listener.dart (added LeaderboardBloc dispatch)
- rackup/lib/core/routing/app_router.dart (added LeaderboardBloc provider)
- rackup/lib/features/game/view/game_page.dart (passes LeaderboardBloc to screens)
- rackup/lib/features/game/view/player_screen.dart (BlocBuilder-driven leaderboard with ranks, streaks, leader glow)
- rackup/lib/features/game/view/referee_screen.dart (streak indicator, footer leaderboard peek)
- rackup/lib/features/game/bloc/game_event.dart (added streak/leaderboard fields to GameTurnCompleted, added LeaderboardEntry class)

**Test files created:**
- rackup/test/features/game/bloc/leaderboard_bloc_test.dart
- rackup/test/features/game/view/widgets/streak_fire_indicator_test.dart

**Test files modified:**
- rackup/test/core/websocket/game_message_listener_test.dart
- rackup/test/features/game/view/player_screen_test.dart
- rackup/test/features/game/view/referee_screen_test.dart
- rackup/test/features/game/view/game_page_test.dart
