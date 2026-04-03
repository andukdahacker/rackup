# Story 3.7: Event Feed & Game End

Status: done

## Story

As a player,
I want to see a feed of game events and know when the game ends,
so that I can follow the action and celebrate the conclusion.

## Acceptance Criteria

1. **Given** the game is in progress **When** game events occur (shots, streaks, score changes) **Then** Event Feed Items appear in the Event Feed zone as compact rows **And** each row has a 3dp colored left border: blue for items, red for punishments, gold for streaks, purple for missions, green for scores **And** event text is Barlow 13dp with optional emoji **And** maximum 4 events are visible at a time

2. **Given** events are arriving rapidly (cascade sequence) **When** multiple events arrive in quick succession **Then** each event holds for a minimum of 2 seconds before older events scroll off **And** this ensures readability during rapid cascade sequences

3. **Given** the configured number of rounds has been completed **When** the final turn's consequence chain resolves **Then** the server sends a `game.game_ended` message to all clients (FR17) **And** the system transitions all players to the post-game state **And** no more shots can be confirmed **And** the game flow moves forward (no back navigation to active game)

## Tasks / Subtasks

- [x] Task 1: Create EventFeedCubit and state (AC: #1, #2)
  - [x] 1.1 Create `rackup/lib/features/game/bloc/event_feed_cubit.dart` — lightweight Cubit (not full Bloc) per architecture spec
  - [x] 1.2 Create `rackup/lib/features/game/bloc/event_feed_state.dart` with `EventFeedState` containing a `List<EventFeedItem>` (max 4 items)
  - [x] 1.3 Define `EventFeedItem` model class with fields: `id` (unique String for keying), `text` (String), `category` (enum for border color), `timestamp` (DateTime)
  - [x] 1.4 Define `EventFeedCategory` enum: `score` (green `#22C55E`), `streak` (gold `#FFD700`), `item` (blue `#3B82F6`), `punishment` (red `#EF4444`), `mission` (purple `#A855F7`), `system` (white/neutral for game start/end)
  - [x] 1.5 Implement `addEvent(EventFeedItem)` method: prepends to list, trims to max 4, emits new state
  - [x] 1.6 The cubit does NOT manage 2-second hold timing — that is a UI concern handled by the widget's animation controller. The cubit is a simple list manager

- [x] Task 2: Create EventFeedWidget (AC: #1, #2)
  - [x] 2.1 Create `rackup/lib/features/game/view/widgets/event_feed_widget.dart`
  - [x] 2.2 Use `BlocBuilder<EventFeedCubit, EventFeedState>` to render the event list
  - [x] 2.3 Each event row: compact height (~32dp), 3dp colored left border (color from `EventFeedCategory`), event text in Barlow 13dp off-white (`#F0EDF6`), optional emoji prefix, padding 8dp horizontal
  - [x] 2.4 Use `AnimatedList` with `SlideTransition` for new events and `FadeTransition` for removed events. Animation duration 300ms with `Curves.easeOutCubic`. IMPORTANT: `AnimatedList` requires imperative control — use a `GlobalKey<AnimatedListState>` and drive mutations via `BlocListener<EventFeedCubit, EventFeedState>` (NOT `BlocBuilder`). The listener compares `previous.events` vs `current.events` to call `_listKey.currentState!.insertItem(0)` for new items and `_listKey.currentState!.removeItem(lastIndex, ...)` for overflow removals. Use `BlocBuilder` only for the initial build (empty list → first events)
  - [x] 2.5 Max 4 visible events. When a 5th arrives, the oldest is removed with animation
  - [x] 2.6 2-second minimum hold: implemented via the cubit's event timing — the `GameMessageListener` dispatches events, and the cubit only trims when new events push past max 4. Since turns take >2 seconds naturally (referee must tap, undo window, next turn setup), the 2-second hold is satisfied by game pacing. No artificial timer needed for MVP — the consequence chain resolution + next turn setup inherently provides >2s between event batches
  - [x] 2.7 Small screen adaptation: on screens <375dp wide, show max 3 events instead of 4

- [x] Task 3: Wire EventFeedCubit into game lifecycle (AC: #1)
  - [x] 3.1 In `rackup/lib/core/routing/app_router.dart`, class `_RoomShellState`: add `late final EventFeedCubit _eventFeedCubit;` field (line ~79, next to `_leaderboardBloc`). Initialize in `initState()` (line ~87): `_eventFeedCubit = EventFeedCubit();`. Close in `dispose()` (line ~115): `_eventFeedCubit.close();`
  - [x] 3.2 Add `BlocProvider<EventFeedCubit>.value(value: _eventFeedCubit)` to the `MultiBlocProvider.providers` list (line ~129)
  - [x] 3.3 Pass `_eventFeedCubit` to `GameMessageListener` constructor (line ~101-105): add `eventFeedCubit: _eventFeedCubit` parameter. IMPORTANT: `_handleMessage` is a **static method** (line 30 of `game_message_listener.dart`). You must: (1) add `EventFeedCubit eventFeedCubit` to the constructor parameters, (2) add `eventFeedCubit` to the `_handleMessage` static method signature, (3) pass it in the closure at line 24-26: `_handleMessage(message, gameBloc, leaderboardBloc, eventFeedCubit)`
  - [x] 3.4 In `GameMessageListener._handleMessage`, when processing `Actions.gameTurnComplete`, generate event feed items from the `TurnCompletePayload`:
    - Resolve shooter display name from leaderboard entries: `payload.leaderboard.firstWhere((e) => e.deviceIdHash == payload.shooterHash).displayName`
    - If `result == "made"`: add score event (green) — `"$shooterName scored +$pointsAwarded"` (or `"+$pointsAwarded (3X)"` if `isTriplePoints`)
    - If `result == "missed"`: add score event (green) — `"$shooterName missed"`
    - If `streakMilestone == true`: add streak event (gold) — map `streakLabel`: `"warming_up"` → `"$shooterName is warming up"`, `"on_fire"` → `"$shooterName is ON FIRE 🔥"`, `"unstoppable"` → `"$shooterName is UNSTOPPABLE 💪"`
    - If `triplePointsActivated == true`: add system event (gold) — `"TRIPLE POINTS! All scores 3X"`
    - If `isGameOver == true`: add system event (system) — `"GAME OVER"`
  - [x] 3.5 Add extension point comments for future event sources: item deployments (Epic 5), punishment reveals (Epic 4), mission completions (Epic 6)
  - [x] 3.6 `EventFeedWidget` accesses `EventFeedCubit` via `BlocBuilder` from context (provided by `BlocProvider` in Task 3.2). Do NOT pass `EventFeedCubit` as a constructor parameter to `PlayerScreen`. Note: `LeaderboardBloc` uses a different pattern (constructor injection from `game_page.dart` via `context.read<LeaderboardBloc>()`). For EventFeedWidget, context-based access is cleaner because the widget is self-contained — it owns its own `BlocBuilder` internally, unlike the leaderboard which is built directly by `PlayerScreen`

- [x] Task 4: Replace placeholder in PlayerScreen (AC: #1)
  - [x] 4.1 In `player_screen.dart`, replace the Event Feed region (lines 114-131) — remove the static `Text` placeholder
  - [x] 4.2 Insert `EventFeedWidget` in its place, wrapping with appropriate padding
  - [x] 4.3 Keep the `Expanded(flex: 25)` wrapper — the event feed region stays at ~25% of screen height

- [x] Task 5: Add GameEnded state and handle game end (AC: #3)
  - [x] 5.1 Add `GameEnded` state to `game_state.dart` — a sealed class member carrying final game data: `players` (final scores), `roundCount`, `refereeDeviceIdHash`. This is a terminal state — no more `GameActive` transitions after this
  - [x] 5.2 In `game_bloc.dart` `_onGameTurnCompleted`: after updating scores/round, check `event.isGameOver`. If true, emit `GameEnded` directly (with updated player scores from this final turn) instead of `GameActive`. Do NOT dual-emit `GameActive` then `GameEnded` — `LeaderboardBloc` receives its final update directly from `GameMessageListener` (line 73-78 of `game_message_listener.dart`) via the `LeaderboardUpdated` event, independent of `GameBloc` state. A single `GameEnded` emission with final player data is sufficient
  - [x] 5.3 Handle `Actions.gameEnded` in `GameMessageListener`: add a new case for `game.game_ended`. Since the server sends this AFTER `game.turn_complete`, and `GameBloc` already transitions on `isGameOver: true`, this handler is a safety net. Add a new `GameEndReceived` event to `GameBloc` that transitions to `GameEnded` if not already in that state
  - [x] 5.4 Add `GameEndReceived` event to `game_event.dart` — simple event with no payload (game end confirmation from server)
  - [x] 5.5 In `game_bloc.dart`, add handler `_onGameEndReceived`: if current state is `GameActive`, transition to `GameEnded` using current state data. If already `GameEnded`, no-op

- [x] Task 6: Game end UI handling (AC: #3)
  - [x] 6.1 In `game_page.dart`, add a second `BlocListener<GameBloc, GameState>` for `GameEnded`. The current widget tree is: `PopScope → AudioListener → BlocListener(triple-points) → BlocBuilder`. To add the new listener, wrap both BlocListeners in a `MultiBlocListener` between `AudioListener` and `BlocBuilder`. The result: `PopScope → AudioListener → MultiBlocListener([triplePointsListener, gameEndedListener]) → BlocBuilder`. The `GameEnded` listener should:
    - Call `_wakeLockManager.disable()` — defense-in-depth wake lock release (fulfills the TODO comment at line 141-144)
    - Dismiss triple points overlay if visible (`_triplePointsOverlayVisible`)
    - Use `listenWhen: (prev, curr) => curr is GameEnded` to filter
  - [x] 6.2 In the `BlocBuilder<GameBloc, GameState>` in `game_page.dart`, add a case for `GameEnded`: show a simple "Game Over" screen with the final leaderboard. This is a PLACEHOLDER for Epic 8's full podium ceremony. Display:
    - Dark scaffold with "GAME OVER" text (Oswald Bold 48dp, gold `#FFD700`)
    - Final leaderboard using existing `LeaderboardBloc` state (read-only, no more animations)
    - No action buttons (Epic 8 adds ceremony controls, play again, share)
  - [x] 6.3 On the referee screen: when `GameEnded` fires, the `BlocBuilder` in `game_page.dart` handles it — referee also sees the game over screen. No special referee handling needed since `game_page.dart` routes both roles

- [x] Task 7: Tests (all ACs)
  - [x] 7.1 Unit test `EventFeedCubit`: verify `addEvent` adds items, trims to max 4, emits correct state. Verify ordering (newest first)
  - [x] 7.2 Widget test `EventFeedWidget`: verify renders correct number of rows, correct border colors per category, correct text content. Use `pumpWidget` with mocked cubit state
  - [x] 7.3 Unit test `GameBloc` game end: verify `GameTurnCompleted(isGameOver: true)` results in `GameEnded` state with correct final scores. Verify `GameEndReceived` transitions from `GameActive` to `GameEnded`. Verify `GameEndReceived` is no-op when already `GameEnded`
  - [x] 7.4 Unit test `GameMessageListener` event feed dispatch: verify `game.turn_complete` generates appropriate event feed items (score, streak, triple points, game over). Verify `game.game_ended` dispatches `GameEndReceived`
  - [x] 7.5 Widget test `game_page.dart`: verify `GameEnded` state shows game over screen. Verify wake lock is disabled on game end. NOTE: the existing `_buildTestWidget()` helper in `game_page_test.dart` uses `MultiBlocProvider` with `GameBloc`, `WebSocketCubit`, and `LeaderboardBloc`. You must add `BlocProvider<EventFeedCubit>.value(value: MockEventFeedCubit())` to the providers list for all game_page tests to work after this story
  - [x] 7.6 Widget test `player_screen.dart`: verify `EventFeedWidget` is in the widget tree (replaces placeholder)
  - [x] 7.7 Do NOT test animation timing or visual details of AnimatedList — focus on data flow and state correctness

## Dev Notes

### Architecture Compliance

- **EventFeedCubit is a Cubit, not a Bloc**: Per architecture (`event_feed_cubit.dart` naming), this is a lightweight Cubit managing a list of recent events. No complex event handling needed — just `addEvent()`. This matches the architecture note: "Lightweight cubit (list of recent events), not a full Bloc"
- **Event generation lives in GameMessageListener**: Events are generated when `game.turn_complete` is processed, NOT in the EventFeedCubit itself. The cubit is a dumb list manager; the listener does the smart event extraction from payloads
- **GameEnded is a terminal sealed state**: Once emitted, no more `GameActive` transitions. This enforces "no more shots can be confirmed" at the UI level. Server-side enforcement already exists (`PhaseEnded` blocks `referee.confirm_shot`)
- **No server changes needed**: The Go server already sends `game.game_ended` after the final `game.turn_complete` with `isGameOver: true`. The `PhaseEnded` flag already blocks undo/shots. This story is CLIENT-ONLY
- **Wake lock release on game end**: Fulfills the defense-in-depth TODO at `game_page.dart:141-144`

### Key Existing Code to Understand

| File | Why It Matters |
|------|---------------|
| `rackup/lib/features/game/view/player_screen.dart` | Lines 114-131: placeholder Event Feed region to replace. Lines 56-71: player lookup patterns to reuse |
| `rackup/lib/features/game/view/game_page.dart` | Lines 109-138: BlocBuilder routing. Lines 141-144: wake lock TODO. Lines 70-147: full build method showing widget tree structure |
| `rackup/lib/core/websocket/game_message_listener.dart` | Lines 50-78: `game.turn_complete` handling — add event feed dispatch here. Line 80: default case — add `game.game_ended` handler before this |
| `rackup/lib/features/game/bloc/game_bloc.dart` | Lines 35-63: `_onGameTurnCompleted` — add `GameEnded` emission when `isGameOver`. Line 61: already uses `isGameOver` to suppress triple points |
| `rackup/lib/features/game/bloc/game_state.dart` | Sealed class with `GameInitial` and `GameActive` — add `GameEnded` as third member |
| `rackup/lib/features/game/bloc/game_event.dart` | Lines 48-120: `GameTurnCompleted` event with `isGameOver` field already present. Add `GameEndReceived` event |
| `rackup/lib/core/protocol/actions.dart` | Line 39: `gameEnded = 'game.game_ended'` already defined but not handled in `GameMessageListener` |
| `rackup/lib/core/protocol/messages.dart` | Lines 331-418: `TurnCompletePayload` — all fields needed for event generation already exist (`result`, `pointsAwarded`, `streakLabel`, `streakMilestone`, `triplePointsActivated`, `isGameOver`) |

### Event Feed Color Mapping

| Category | Border Color | Hex | Current Status |
|----------|-------------|-----|----------------|
| `score` | Green | `#22C55E` | Wire NOW — from `game.turn_complete` result/points |
| `streak` | Gold | `#FFD700` | Wire NOW — from `game.turn_complete` streakMilestone |
| `system` | Off-white | `#F0EDF6` | Wire NOW — game over, triple points activation |
| `item` | Blue | `#3B82F6` | EXTENSION POINT — Epic 5 item deployments |
| `punishment` | Red | `#EF4444` | EXTENSION POINT — Epic 4 punishment reveals |
| `mission` | Purple | `#A855F7` | EXTENSION POINT — Epic 6 mission completions |

### Event Generation from TurnCompletePayload

Generate events in this order (maps to consequence chain):
1. **Score event** (always): `"$name scored +$pts"` or `"$name missed"` → category `score`
2. **Streak event** (if `streakMilestone`): `"$name is ON FIRE 🔥"` etc. → category `streak`
3. **Triple points** (if `triplePointsActivated`): `"TRIPLE POINTS! All scores 3X"` → category `system`
4. **Game over** (if `isGameOver`): `"GAME OVER"` → category `system`

Resolve shooter display name from `payload.leaderboard` list (it always contains all players with `displayName`).

### Game End Server Behavior (Already Implemented)

The Go server (`room.go:660-677`):
1. After final shot's consequence chain, sets `GamePhase = PhaseEnded`
2. Broadcasts `game.turn_complete` with `isGameOver: true`
3. Broadcasts `game.game_ended` with `{"gameOver": true}`
4. Blocks all subsequent `referee.confirm_shot` and `referee.undo_shot`

Client receives these two messages in order. The `game.turn_complete` with `isGameOver: true` is the primary trigger; `game.game_ended` is the confirmation/safety net.

### Game End UI Strategy

This story implements a **minimal game-over screen** as a placeholder. The full post-game ceremony (podium reveal, awards, report card, share) is Epic 8. The game-over screen for this story:
- Shows "GAME OVER" with The Eruption feel (gold text, centered)
- Shows final leaderboard (static, no animations)
- No buttons/actions — just a holding state
- Epic 8 will replace this with `CeremonyPage` navigation

### Previous Story Intelligence (Story 3.6)

**Patterns to reuse:**
- `AudioListener` widget wrapping pattern in `game_page.dart` — follow same nesting for any additional `BlocListener`s
- `SoundManager` lifecycle in `initState`/`dispose` — reference for how services are created in game page
- `BlocListener` `listenWhen` pattern for triple points — reuse for game end detection
- Wake lock disable in `dispose()` with `try/finally` — game end handler is the defense-in-depth companion

**Debug lessons from Story 3.6:**
- `pumpAndSettle` times out on repeating animations — use `pump()` in widget tests with `AnimatedList`
- Test factories in `test/helpers/factories.dart` are lobby/room focused — create inline test data or add game-specific factories
- `BlocListener` subscription timing can be tricky — use `StreamController`-based approach in tests

### Git Intelligence (Recent Commits)

Last 5 commits are all Epic 3 stories (3.1-3.6). Patterns:
- Each commit: "Add [feature] with code review fixes (Story X.Y)"
- All stories follow the same file organization patterns
- Tests are co-located under `test/` mirroring `lib/` structure
- Each story adds to existing blocs/widgets rather than replacing

### Files to Create

| File | Purpose |
|------|---------|
| `rackup/lib/features/game/bloc/event_feed_cubit.dart` | EventFeedCubit — manages list of max 4 recent events |
| `rackup/lib/features/game/bloc/event_feed_state.dart` | EventFeedState + EventFeedItem model + EventFeedCategory enum |
| `rackup/lib/features/game/view/widgets/event_feed_widget.dart` | EventFeedWidget — animated compact rows with colored left borders |
| `rackup/test/features/game/bloc/event_feed_cubit_test.dart` | EventFeedCubit unit tests |
| `rackup/test/features/game/view/widgets/event_feed_widget_test.dart` | EventFeedWidget widget tests |
| `rackup/test/features/game/bloc/game_bloc_game_end_test.dart` | GameBloc game end tests (separate file to avoid bloating existing test) |

### Files to Modify

| File | Change |
|------|--------|
| `rackup/lib/features/game/bloc/game_state.dart` | Add `GameEnded` sealed class member |
| `rackup/lib/features/game/bloc/game_event.dart` | Add `GameEndReceived` event |
| `rackup/lib/features/game/bloc/game_bloc.dart` | Add `_onGameEndReceived` handler, modify `_onGameTurnCompleted` to emit `GameEnded` on `isGameOver` |
| `rackup/lib/core/websocket/game_message_listener.dart` | Add `EventFeedCubit` parameter, generate feed events from `turn_complete`, handle `game.game_ended` action |
| `rackup/lib/features/game/view/player_screen.dart` | Replace Event Feed placeholder (lines 114-131) with `EventFeedWidget` |
| `rackup/lib/features/game/view/game_page.dart` | Add `GameEnded` BlocListener for wake lock, add `GameEnded` case to BlocBuilder for game over screen |
| `rackup/lib/core/routing/app_router.dart` | Add `EventFeedCubit` field, init, dispose, `BlocProvider`, and pass to `GameMessageListener` (class `_RoomShellState`, lines 75-134) |

### What NOT to Change

- **Server (Go)**: No changes — game end already fully implemented server-side
- **Existing blocs**: Do NOT modify `LeaderboardBloc`, `RefereeBloc`, or `WebSocketCubit`
- **Referee screen**: No direct changes — game end handled at `game_page.dart` routing level
- **Sound effects**: No new sounds — event feed is visual-only

### Project Structure Notes

- `event_feed_cubit.dart` and `event_feed_state.dart` go in `features/game/bloc/` — same directory as `game_bloc.dart`, `leaderboard_bloc.dart`
- `event_feed_widget.dart` goes in `features/game/view/widgets/` — same directory as `leaderboard_row.dart`, `streak_indicator.dart`
- Tests mirror lib structure under `test/`
- No cross-feature imports except through `core/`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.7]
- [Source: _bmad-output/planning-artifacts/architecture.md#EventFeedCubit - cascade event narration]
- [Source: _bmad-output/planning-artifacts/architecture.md#Consequence Chain Pipeline]
- [Source: _bmad-output/planning-artifacts/architecture.md#Protocol Source of Truth]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Event Feed Item - Component 13]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Player Screen Regions]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow 5 - Game End]
- [Source: rackup-server/internal/room/room.go#handleConfirmShotLocked - game end broadcast]
- [Source: rackup-server/internal/protocol/actions.go#ActionGameEnded]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

No debug issues encountered.

### Completion Notes List

- Task 1: Created `EventFeedCubit` (lightweight cubit) and `EventFeedState` with `EventFeedItem` model and `EventFeedCategory` enum. Max 4 events, newest first. 5 unit tests pass.
- Task 2: Created `EventFeedWidget` using `AnimatedList` with `BlocListener`-driven mutations. `SlideTransition` for inserts, `FadeTransition` for removals. 300ms animations. Small screen adaptation (max 3 events on <375dp). 6 widget tests pass.
- Task 3: Wired `EventFeedCubit` into `_RoomShellState` (app_router.dart) — init, dispose, BlocProvider, and passed to `GameMessageListener`. Added event feed item generation in `_generateEventFeedItems` from `TurnCompletePayload`: score events (made/missed), streak milestones, triple points activation, game over. Added `game.game_ended` handler dispatching `GameEndReceived`.
- Task 4: Replaced static "It's X's turn" placeholder in `PlayerScreen` with `EventFeedWidget`. Removed unused `currentShooterName` variable.
- Task 5: Added `GameEnded` terminal sealed state to `game_state.dart`. Added `GameEndReceived` event to `game_event.dart`. Modified `_onGameTurnCompleted` to emit `GameEnded` directly on `isGameOver: true`. Added `_onGameEndReceived` handler (safety net: transitions `GameActive` → `GameEnded`, no-op if already ended).
- Task 6: Restructured `game_page.dart` widget tree — replaced single `BlocListener` with `MultiBlocListener` (triple points + game end). Game end listener disables wake lock (defense-in-depth) and dismisses triple points overlay. Added `GameEnded` case to `BlocBuilder` rendering placeholder game-over screen (gold "GAME OVER" + static final leaderboard). Epic 8 replaces with full ceremony.
- Task 7: All tests written and passing. 376 total tests, 0 regressions. Updated existing tests (`game_page_test.dart`, `player_screen_test.dart`, `game_message_listener_test.dart`) with `EventFeedCubit` provider.

### Change Log

- 2026-04-03: Implemented Story 3.7 — Event Feed & Game End (all tasks)

### File List

**New files:**
- `rackup/lib/features/game/bloc/event_feed_cubit.dart`
- `rackup/lib/features/game/bloc/event_feed_state.dart`
- `rackup/lib/features/game/view/widgets/event_feed_widget.dart`
- `rackup/test/features/game/bloc/event_feed_cubit_test.dart`
- `rackup/test/features/game/view/widgets/event_feed_widget_test.dart`
- `rackup/test/features/game/bloc/game_bloc_game_end_test.dart`

**Modified files:**
- `rackup/lib/features/game/bloc/game_state.dart` — Added `GameEnded` sealed class member
- `rackup/lib/features/game/bloc/game_event.dart` — Added `GameEndReceived` event
- `rackup/lib/features/game/bloc/game_bloc.dart` — Added `_onGameEndReceived`, modified `_onGameTurnCompleted` for game end
- `rackup/lib/core/websocket/game_message_listener.dart` — Added `EventFeedCubit` param, event feed generation, `game.game_ended` handler
- `rackup/lib/features/game/view/player_screen.dart` — Replaced placeholder with `EventFeedWidget`, removed unused variable
- `rackup/lib/features/game/view/game_page.dart` — `MultiBlocListener`, `GameEnded` listener/builder, game over screen
- `rackup/lib/core/routing/app_router.dart` — Added `EventFeedCubit` lifecycle and `BlocProvider`
- `rackup/test/features/game/view/game_page_test.dart` — Added `EventFeedCubit` provider, game end test
- `rackup/test/features/game/view/player_screen_test.dart` — Added `EventFeedCubit` provider, replaced turn indicator test with EventFeedWidget presence test
- `rackup/test/core/websocket/game_message_listener_test.dart` — Added `EventFeedCubit`, event feed dispatch tests, game.game_ended test
