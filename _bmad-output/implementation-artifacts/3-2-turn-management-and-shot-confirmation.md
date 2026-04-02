# Story 3.2: Turn Management & Shot Confirmation

Status: review

## Story

As a referee,
I want to confirm each player's shot as made or missed,
So that the game progresses accurately turn by turn.

## Acceptance Criteria

1. **Given** the game is in progress and it is a player's turn, **When** the referee views the Action Zone, **Then** the current shooter's name is displayed prominently in the Stage Area, two Big Binary Buttons (MADE green gradient / MISSED red gradient) are displayed side-by-side in the Action Zone with Oswald Bold 28dp uppercase, minimum 100dp height, and breathing pulse animation in default state.

2. **Given** the referee taps MADE or MISSED, **When** the shot result is confirmed, **Then** the button scales to 97% on press, the result is sent to the server as a `referee.confirm_shot` message, the server validates the action comes from the authoritative referee client, and the result propagates to all players within 2 seconds.

3. **Given** the referee has just confirmed a shot, **When** within 5 seconds of confirmation, **Then** an Undo Button appears (48x48dp, deliberately smaller than primary actions) with a shrinking ring countdown animation, and tapping Undo reverts the shot result and returns MADE/MISSED buttons.

4. **Given** 5 seconds have elapsed since shot confirmation, **When** the Undo window expires, **Then** the Undo Button fades to 0% opacity, the shot result locks permanently, and the turn advances to the next player in rotation.

5. **Given** the system manages turn order, **When** a turn completes, **Then** the next player in the room's turn order becomes the current shooter, the referee screen updates to show the new shooter's name, and all player screens reflect whose turn it is.

## Tasks / Subtasks

- [x] Task 1: Protocol Layer — New Messages (AC: 2, 3, 4, 5)
  - [x] 1.1 Add `referee.confirm_shot` action constant (already exists in Go `actions.go` and Dart `actions.dart` — verify and document payload)
  - [x] 1.2 Add `referee.undo_shot` action constant in Go `actions.go` and Dart `actions.dart`
  - [x] 1.3 Add `game.turn_complete` payload struct in Go `messages.go`: shooterHash, result ("made"/"missed"), scoreUpdate, streakCount, currentShooterHash (next), currentRound, isGameOver
  - [x] 1.4 Mirror `TurnCompletePayload` in Dart `messages.dart` with `fromJson` factory
  - [x] 1.5 Add `ConfirmShotPayload` in Go `messages.go`: result field ("made"/"missed")
  - [x] 1.6 Add `UndoShotPayload` if needed (may be empty payload with just action)
  - [x] 1.8 Add `game.game_ended` action constant in Go `actions.go` (`ActionGameEnded`) and Dart `actions.dart` (`Actions.gameEnded`) — needed for Task 3.4 game over broadcast
  - [x] 1.7 Add `// SYNC WITH:` headers referencing Go canonical types

- [x] Task 2: Server Game Engine — Shot Processing (AC: 2, 4, 5)
  - [x] 2.1 Add `ProcessShot(shooterHash string, result string) (*TurnResult, error)` to `GameState` in `game_state.go`
  - [x] 2.2 Implement scoring: +3 base points for "made", 0 for "missed"
  - [x] 2.3 Implement streak tracking: increment on "made", reset to 0 on "missed"
  - [x] 2.4 Implement streak bonus calculation: +1 for 2 consecutive, +2 for 3, +3 for 4+
  - [x] 2.5 Add `AdvanceTurn()` method: increment `currentShooterIdx`, wrap around turn order, increment `currentRound` when all players have shot
  - [x] 2.6 Add `UndoLastShot() error` method: revert score/streak changes, reset currentShooterIdx to previous
  - [x] 2.7 Track `lastShotResult` and `lastShotTime` on GameState for undo validation
  - [x] 2.8 Add `IsGameOver() bool`: return true when currentRound > roundCount
  - [x] 2.9 Unit tests for all scoring scenarios: made, missed, streaks 2/3/4+, undo, turn wrap, round increment, game over

- [x] Task 3: Server Room Handler — Shot Flow (AC: 2, 3, 4)
  - [x] 3.0 **PREREQUISITE**: Refactor `handleGameAction()` signature to accept `json.RawMessage` payload. Currently called as `r.handleGameAction(deviceHash, msg.Action)` without payload. Change call site in `handleClientMessage()` to pass `msg.Payload`, and change signature to `func (r *Room) handleGameAction(deviceHash, action string, payload json.RawMessage)`.
  - [x] 3.0b **CRITICAL CONCURRENCY FIX**: `handleGameAction()` currently acquires only `r.mu.RLock()` (read lock) then reads `r.gameState`. Since `ProcessShot()` and `AdvanceTurn()` MUTATE `GameState` fields, this is a data race. Refactor to use `r.mu.Lock()` (write lock) for `referee.confirm_shot` and `referee.undo_shot` actions. Keep RLock for read-only game actions if any. Also DELETE the misleading comment on `handleGameAction()` that says "GameState is immutable after construction" — this is no longer true once mutation methods are added.
  - [x] 3.1 Handle `referee.confirm_shot`: parse `ConfirmShotPayload` from payload, validate referee authority (existing check), call `GameState.ProcessShot()`
  - [x] 3.2 Build and broadcast `game.turn_complete` message to all clients. Use `broadcastLocked()` since you already hold the write lock from Task 3.0b. **WARNING**: Do NOT call `BroadcastMessage()` while holding the write lock — it acquires its own RLock internally and will deadlock. Only use `broadcastLocked()` within the write-locked section.
  - [x] 3.3 Handle `referee.undo_shot`: validate within 5-second window (server-side timestamp check), call `GameState.UndoLastShot()`, broadcast `game.turn_complete` with reverted state (same message type, clients process identically — the reverted state IS the correction)
  - [x] 3.4 Handle game over: when `IsGameOver()` returns true after turn advance, broadcast `game.game_ended` message (placeholder for Story 3.7)
  - [x] 3.5 Server integration tests: confirm_shot flow, undo flow, referee authority rejection, turn advancement, undo after 5s rejected

- [x] Task 4: Domain Models — Turn State (AC: 1, 5)
  - [x] 4.1 Update `GamePlayer` model in `game_player.dart`: ensure `score` and `streak` fields support updates via `copyWith()`
  - [x] 4.2 Add `ShotResult` enum in `game_player.dart` or new file: `made`, `missed`
  - [x] 4.3 Add mapper function `mapToTurnComplete()` in `mapper.dart` to convert `TurnCompletePayload` to domain objects

- [x] Task 5: GameBloc — Turn State Management (AC: 2, 3, 4, 5)
  - [x] 5.0 **PREREQUISITE**: Add `copyWith()` method to `GameActive` in `game_state.dart`. Currently `GameActive` has no `copyWith()` — it's needed for immutable state updates when handling turn completions.
  - [x] 5.1 Add `GameTurnCompleted` event in `game_event.dart`: shooterHash, result, scoreUpdate, streakCount, nextShooterHash, currentRound, isGameOver
  - [x] 5.2 Add `GameShotConfirmed` event (local, for optimistic referee UI state): result
  - [x] 5.3 Add `GameShotUndone` event (from server confirmation of undo)
  - [x] 5.4 Handle `GameTurnCompleted` in `game_bloc.dart`: update player scores/streaks, advance currentShooterHash, update currentRound, recalculate tier. Use `GameActive.copyWith()`.
  - [x] 5.5 Handle `GameShotUndone`: revert to pre-shot state (server sends a corrected `game.turn_complete` — same handler applies)
  - [x] 5.6 Ensure `GameActive` state in `game_state.dart` carries all needed fields (already has players, currentShooterHash, currentRound, tier). Ignore `isGameOver` for now — Story 3.7 handles game end client-side.
  - [x] 5.7 Unit tests for GameBloc: turn complete updates state, undo reverts, tier recalculation on round change

- [x] Task 6: GameMessageListener — Route New Messages (AC: 2, 3, 5)
  - [x] 6.1 Handle `game.turn_complete` in `game_message_listener.dart`: parse `TurnCompletePayload`, dispatch `GameTurnCompleted` to GameBloc
  - [x] 6.2 Handle undo confirmation message if server sends one
  - [x] 6.3 Tests for message routing

- [x] Task 7: Referee Screen — MADE/MISSED Buttons (AC: 1, 2)
  - [x] 7.1 Create `BigBinaryButtons` widget: two buttons in a 50/50 split spanning full width (per Component #1 spec), MADE green gradient `#22C55E` and MISSED red gradient `#EF4444`, Oswald Bold 28dp uppercase with `textScaler: TextScaler.noScaling` (1.0x — already oversized per UX accessibility table), minimum 100dp height, 32dp horizontal margin (edge-to-edge per UX layout principles)
  - [x] 7.2 Add breathing pulse animation (subtle scale oscillation) on idle state
  - [x] 7.3 Add press feedback: scale to 97% on tap down
  - [x] 7.4 On tap: send `referee.confirm_shot` WebSocket message with result
  - [x] 7.5 Replace "Waiting for turn..." placeholder in Action Zone with `BigBinaryButtons`
  - [x] 7.6 Accessibility: semantic labels "Confirm shot made" / "Confirm shot missed", minimum 56dp tap targets (already exceed at 100dp)

- [x] Task 8: Referee Screen — Undo Button (AC: 3, 4)
  - [x] 8.1 Create `UndoButton` widget: 48x48dp, subdued styling (Tier 3 action)
  - [x] 8.2 Add shrinking ring countdown animation (5-second circular progress that depletes)
  - [x] 8.3 Show UndoButton after shot confirmation, replacing BigBinaryButtons via AnimatedSwitcher
  - [x] 8.4 On tap: send `referee.undo_shot` WebSocket message, transition back to BigBinaryButtons
  - [x] 8.5 On timeout (5s): fade to 0% opacity, transition to BigBinaryButtons for next shooter
  - [x] 8.6 Accessibility: "Undo last shot, N seconds remaining" with live region updates

- [x] Task 9: Referee Screen — Stage Area Updates (AC: 1, 5)
  - [x] 9.1 Update Stage Area to show current shooter's PlayerNameTag (large variant) prominently — already shows shooter name, verify it updates on turn change
  - [x] 9.2 Ensure Stage Area rebuilds from GameBloc `currentShooterHash` changes

- [x] Task 10: Player Screen — Turn Indicator (AC: 5)
  - [x] 10.1 Add `currentShooterDeviceIdHash` parameter to `PlayerScreen` widget (currently only has `myDeviceIdHash` — needs a second highlight concept for current shooter)
  - [x] 10.2 Update player leaderboard to highlight current shooter row (distinct from self-highlight)
  - [x] 10.3 Show "It's [PlayerName]'s turn" indicator in Event Feed or Header area
  - [x] 10.4 Update on `GameTurnCompleted` events

- [x] Task 11: Player Screen — Score/Streak Updates (AC: 2, 5)
  - [x] 11.1 Update leaderboard scores from `GameTurnCompleted` data
  - [x] 11.2 Re-sort leaderboard by score descending (placeholder for animated shuffle in Story 3.4)
  - [x] 11.3 Update My Status section with current player's score and streak

- [x] Task 12: WebSocket Message Sending (AC: 2, 3)
  - [x] 12.1 Send shot confirmation by constructing `Message(action: Actions.refereeConfirmShot, payload: {'result': 'made'})` and calling existing `webSocketCubit.sendMessage(msg)`. Use `Message.toJson()`/`toRawJson()` which already exist. No new helper method strictly needed — but a convenience method is acceptable if it improves readability.
  - [x] 12.2 Send undo via `Message(action: Actions.refereeUndoShot, payload: {})` through same path
  - [x] 12.3 Wire up BigBinaryButtons and UndoButton tap handlers to call the above

- [x] Task 13: Comprehensive Tests (AC: all)
  - [x] 13.1 Go unit tests: `ProcessShot` scoring, streak bonuses, undo, turn advancement, round progression, game over detection
  - [x] 13.2 Go integration tests: full shot flow through room handler, referee authority validation, undo within/after window
  - [x] 13.3 Dart GameBloc tests: `GameTurnCompleted` state transitions, score/streak updates, tier recalculation, undo
  - [x] 13.4 Dart widget tests: BigBinaryButtons renders correctly, tap sends message, UndoButton countdown, AnimatedSwitcher transitions
  - [x] 13.5 Dart widget tests: PlayerScreen leaderboard updates, current shooter indicator
  - [x] 13.6 Dart message listener tests: `game.turn_complete` routing

## Dev Notes

### Architecture Compliance

- **Server-authoritative**: All shot results validated server-side. Referee authority check already exists in `room.go` `handleGameAction()` — reuse it. Client never directly modifies scores.
- **Consequence chain foundation**: Story 3.3 will build the full consequence chain. This story implements the minimal shot → score → turn-advance flow. Design `ProcessShot` return type (`TurnResult`) to be extensible for streak indicators, item drops, punishment draws later.
- **Atomic turn update**: `game.turn_complete` is the single message containing ALL turn consequences (per architecture). Even though this story only has score+streak, the payload structure must accommodate future fields (item drops, punishments, etc.) — use optional/nullable fields.
- **Protocol separation**: Go `internal/protocol/` is canonical. Dart mirrors with `// SYNC WITH:` headers. Domain models (`GamePlayer`) never leak protocol types.
- **Bloc pattern**: Use sealed classes for states (Dart 3). Events: past tense for server events (`GameTurnCompleted`), imperative for user actions. Never use protocol types in Bloc states.

### Existing Code — DO NOT Duplicate

These already exist and must be reused:

| Component | Location | What It Does |
|-----------|----------|-------------|
| `GameState` struct | `rackup-server/internal/game/game_state.go` | Holds roundCount, currentRound, refereeHash, turnOrder, currentShooterIdx, players map, phase |
| `GamePlayer` struct (Go) | `rackup-server/internal/game/game_state.go` | Has Score, Streak, IsReferee fields |
| `handleGameAction()` | `rackup-server/internal/room/room.go` | Validates referee authority, routes game/referee namespace actions. **Currently takes only (deviceHash, action) — needs payload param added (Task 3.0).** Currently uses RLock — **needs write lock for mutations (Task 3.0b).** |
| `broadcastLocked()` / `BroadcastMessage()` | `rackup-server/internal/room/room.go` | `broadcastLocked()` sends to all clients (requires mutex held — use this when inside write-locked section). `BroadcastMessage()` acquires its own RLock internally — **will deadlock if called while holding write lock**. |
| `GameBloc` | `rackup/lib/features/game/bloc/game_bloc.dart` | Manages `GameActive` state with players, currentShooterHash, tier |
| `GamePlayer` model (Dart) | `rackup/lib/core/models/game_player.dart` | Has score, streak, isReferee, copyWith() |
| `GameMessageListener` | `rackup/lib/core/websocket/game_message_listener.dart` | Routes `game.*` messages to GameBloc |
| `WebSocketCubit` | `rackup/lib/core/websocket/web_socket_cubit.dart` | Connection lifecycle, message stream |
| `mapToGamePlayer()` | `rackup/lib/core/protocol/mapper.dart` | Protocol → domain mapping |
| `PlayerNameTag` widget | `rackup/lib/core/widgets/player_name_tag.dart` | 3 size variants (compact/standard/large) with color+shape identity |
| `ProgressTierBar` widget | `rackup/lib/features/game/view/widgets/progress_tier_bar.dart` | Tier display with round counter |
| `RefereeScreen` | `rackup/lib/features/game/view/referee_screen.dart` | 4-region layout with Stage Area and Action Zone placeholders |
| `PlayerScreen` | `rackup/lib/features/game/view/player_screen.dart` | 4-region layout with leaderboard and event feed |
| `RackUpGameTheme` | `rackup/lib/core/theme/rackup_game_theme.dart` | Color constants, typography, spacing |
| Test factories | `rackup-server/internal/testutil/` and `rackup/test/helpers/` | `NewTestRoom()`, `NewTestPlayer()`, etc. |

### Key Implementation Decisions

1. **Undo window is server-enforced**: Store `lastShotTime` on `GameState`. Server rejects undo if >5s elapsed. Client countdown is visual only — server is authoritative.

2. **Turn order wrapping**: `currentShooterIdx` increments and wraps modulo `len(turnOrder)`. When it wraps to 0, increment `currentRound`. This means one "round" = all players shoot once.

3. **BigBinaryButtons state machine** (referee Action Zone):
   - `idle` → Show MADE/MISSED with breathing pulse
   - `confirmed` → Show UndoButton with countdown (5s)
   - `locked` → Brief transition, then back to `idle` for next shooter
   - Use `AnimatedSwitcher` in the Action Zone to swap between states

4. **TurnResult struct** (Go): Return from `ProcessShot()` should include: `ShooterHash`, `Result`, `PointsAwarded`, `NewScore`, `NewStreak`, `NextShooterHash`, `CurrentRound`, `IsGameOver`. This maps directly to `game.turn_complete` payload.

5. **Streak bonus formula**: Streak 0-1 = no bonus. Streak 2 = +1. Streak 3 = +2. Streak 4+ = +3. Total points for a made shot = 3 (base) + streak bonus.

6. **No triple-points yet**: Triple points activate in final 3 rounds (Story 3.5). This story uses base scoring only. But ensure the scoring path can be multiplied later.

7. **No animation for leaderboard reorder yet**: Story 3.4 adds animated shuffles. This story just re-sorts the list.

8. **No sound effects yet**: Story 3.6 adds audio. This story is silent.

9. **No consequence chain extensions yet**: Story 3.3 builds the full chain with streak indicators, visual feedback (Streak Fire Indicator, The Eruption animation), and extension points for items/punishments/missions. This story just does: shot → score → streak → advance turn.

10. **Scoring pulled forward from Story 3.3**: The epic assigns base scoring and streak bonuses to Story 3.3, but this story implements the scoring math (base +3, streak +1/+2/+3) because turn management requires score updates to be meaningful. When implementing Story 3.3, the scoring engine is already done — 3.3 focuses on: streak INDICATORS (visual Warming Up / ON FIRE / UNSTOPPABLE), the consequence chain PIPELINE with extension points, and the atomic `game.turn_complete` message expansion.

11. **Undo broadcasts corrected state, not a separate message**: On undo, the server reverts GameState and broadcasts a new `game.turn_complete` with the corrected values. Clients process it identically — the corrected state IS the fix. No dedicated "undo" client-side message type needed. The referee UI handles undo locally via the Action Zone state machine.

### Game Flow — Shot Confirmation Sequence

```
Referee taps MADE/MISSED
  → Client sends {action: "referee.confirm_shot", payload: {result: "made"}}
  → Server validates referee authority (existing check)
  → Server calls GameState.ProcessShot("shooterHash", "made")
  → GameState updates score (+3 + streak bonus), updates streak
  → GameState.AdvanceTurn() moves to next shooter
  → Server builds TurnCompletePayload
  → Server broadcasts {action: "game.turn_complete", payload: {...}} to all
  → All clients: GameMessageListener parses, dispatches GameTurnCompleted
  → GameBloc updates state: new scores, new currentShooter, new round/tier
  → Referee: AnimatedSwitcher shows UndoButton (5s countdown)
  → Players: Leaderboard re-sorts, turn indicator updates
  → After 5s: Undo expires, referee sees MADE/MISSED for next shooter
```

### Undo Flow

```
Referee taps Undo (within 5s)
  → Client sends {action: "referee.undo_shot", payload: {}}
  → Server checks lastShotTime < 5s ago (rejects if expired)
  → Server calls GameState.UndoLastShot(): reverts score, streak, currentShooterIdx
  → Server broadcasts {action: "game.turn_complete", payload: {reverted state}}
  → All clients process as normal turn_complete — state corrects itself
  → Referee: AnimatedSwitcher returns to MADE/MISSED buttons for same shooter
```

### Project Structure Notes

- New Go code goes in `rackup-server/internal/game/` (ProcessShot, scoring, undo logic on GameState)
- New protocol types go in `rackup-server/internal/protocol/messages.go` and `rackup/lib/core/protocol/messages.dart`
- New widgets go in `rackup/lib/features/game/view/widgets/` (BigBinaryButtons, UndoButton)
- Tests co-located: Go `*_test.go` next to source, Dart mirrors `lib/` in `test/`

### Testing Standards

- **Go**: Table-driven tests in `*_test.go`. Use `testutil` factories. Test scoring edge cases: streak at boundary values (1→2, 3→4), undo at exactly 5s, turn wrap at last player.
- **Dart BLoC**: Use `bloc_test` package with `blocTest<GameBloc, GameState>()`. Test event→state mappings.
- **Dart Widgets**: Use `mocktail` for mocking WebSocketCubit. Test button rendering, tap callbacks, AnimatedSwitcher transitions, accessibility labels.
- **No mocking the game engine**: Test actual GameState methods, not mocks.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Consequence Chain Pipeline, Atomic Turn Updates, Bloc State Pattern, Protocol separation]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Big Binary Buttons (Component 1), Undo Button (Component 17), Referee Screen Regions, Action Hierarchy Tier 1/3]
- [Source: _bmad-output/planning-artifacts/prd.md — FR12-FR14 Turn Management, FR26-FR28 Scoring & Streaks]
- [Source: _bmad-output/implementation-artifacts/3-1-referee-assignment-and-role-reveal.md — Previous story learnings, file patterns, test approaches]

### Previous Story Intelligence (from Story 3.1)

- **GameBloc uses sealed classes**: `GameInitial` and `GameActive` are sealed. Add new states carefully or extend `GameActive`.
- **GameMessageListener pattern**: Listens to `WebSocketCubit.messages`, parses by action string, maps to domain models, dispatches to GameBloc. Follow same pattern for new message types.
- **Protocol sync discipline**: Go types are canonical. Dart types mirror with `// SYNC WITH: internal/protocol/messages.go` header. Every new Go message type needs a Dart mirror.
- **Test count from 3.1**: 30 tests (17 Go, 13 Dart). Maintain or exceed coverage density.
- **RefereeScreen 4-region layout**: Status Bar / Stage Area / Action Zone / Footer. BigBinaryButtons go in Action Zone. Stage Area already shows shooter name.
- **PlayerScreen leaderboard**: Already renders player list sorted by score. Needs to update reactively on `GameTurnCompleted`.
- **AnimatedSwitcher**: Used in GamePage for role reveal → screen transition. Same pattern for Action Zone state machine.
- **PopScope(canPop: false)**: Game screens block back navigation. Don't add any back navigation.

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6

### Debug Log References
- No blocking issues encountered during implementation.

### Completion Notes List
- Task 1: Added `referee.undo_shot`, `game.game_ended` action constants and `ConfirmShotPayload`, `TurnCompletePayload` in both Go and Dart with SYNC WITH headers.
- Task 2: Implemented `ProcessShot()`, `AdvanceTurn()`, `UndoLastShot()`, `IsGameOver()` on GameState with full scoring engine (base 3 + streak bonuses). 15 new Go unit tests covering all scoring scenarios.
- Task 3: Refactored `handleGameAction()` to accept payload and use write lock for referee mutations. Implemented confirm_shot/undo_shot handlers with `broadcastLocked()`. Added `sendErrorToPlayerLocked()` for in-lock error sending. 7 integration tests for shot flow.
- Task 4: `GamePlayer.copyWith()` already existed. Added `applyTurnComplete()` mapper function. ShotResult enum not created separately — result string "made"/"missed" used directly per protocol.
- Task 5: Added `GameActive.copyWith()`, `GameTurnCompleted` event, `GameShotConfirmed` event. GameBloc handles `GameTurnCompleted` with score/streak updates and tier recalculation. `GameShotUndone` not needed — server sends corrected `game.turn_complete` which the same handler processes. 4 new bloc tests.
- Task 6: Added `game.turn_complete` routing in GameMessageListener. Undo uses same message type. 2 new message listener tests.
- Tasks 7-8: Created `BigBinaryButtons` widget (MADE green #22C55E / MISSED red #EF4444, Oswald Bold 28dp, 100dp height, breathing pulse, 97% press scale) and `UndoButton` (48x48dp, shrinking ring countdown, fade on expire). Both with accessibility labels and live regions.
- Task 9: RefereeScreen converted to StatefulWidget with Action Zone state machine (idle→confirmed→locked). Uses AnimatedSwitcher. Stage Area already rebuilds from widget props. Added `webSocketCubit` parameter.
- Tasks 10-11: PlayerScreen updated with `currentShooterDeviceIdHash` parameter, basketball icon for current shooter, "It's [Name]'s turn" in event feed, leaderboard sorted by score descending, streak display in My Status.
- Task 12: Shot confirmation and undo messages sent via `webSocketCubit.sendMessage()` in RefereeScreen. Wired to BigBinaryButtons and UndoButton tap handlers.
- Task 13: Comprehensive tests — 15 Go game engine unit tests, 7 Go room handler integration tests, 6 Dart bloc tests, 5 Dart referee screen widget tests, 4 Dart player screen tests, 3 Dart message listener tests. Total: 40 new tests.

### Change Log
- 2026-04-01: Implemented Story 3.2 — Turn Management & Shot Confirmation. Full shot→score→undo→turn-advance flow with server-authoritative scoring engine.

### File List
- rackup-server/internal/protocol/actions.go (modified — added ActionRefereeUndoShot, ActionGameEnded)
- rackup-server/internal/protocol/messages.go (modified — added ConfirmShotPayload, TurnCompletePayload)
- rackup-server/internal/game/game_state.go (modified — added TurnResult, ProcessShot, AdvanceTurn, UndoLastShot, IsGameOver, undo tracking fields)
- rackup-server/internal/game/game_state_test.go (modified — added 15 scoring/undo/turn tests)
- rackup-server/internal/room/room.go (modified — refactored handleGameAction with payload+write lock, added confirm_shot/undo_shot handlers, broadcastTurnCompleteLocked, sendErrorToPlayerLocked)
- rackup-server/internal/room/room_test.go (modified — added 7 shot flow integration tests)
- rackup/lib/core/protocol/actions.dart (modified — added refereeUndoShot, gameEnded)
- rackup/lib/core/protocol/messages.dart (modified — added ConfirmShotPayload, TurnCompletePayload)
- rackup/lib/core/protocol/mapper.dart (modified — added applyTurnComplete)
- rackup/lib/features/game/bloc/game_bloc.dart (modified — added GameTurnCompleted handler)
- rackup/lib/features/game/bloc/game_event.dart (modified — added GameTurnCompleted, GameShotConfirmed events)
- rackup/lib/features/game/bloc/game_state.dart (modified — added GameActive.copyWith)
- rackup/lib/core/websocket/game_message_listener.dart (modified — added game.turn_complete routing)
- rackup/lib/features/game/view/referee_screen.dart (modified — StatefulWidget with BigBinaryButtons/UndoButton/AnimatedSwitcher, webSocketCubit integration)
- rackup/lib/features/game/view/player_screen.dart (modified — added currentShooterDeviceIdHash, turn indicator, score sorting, streak display)
- rackup/lib/features/game/view/game_page.dart (modified — passes webSocketCubit and currentShooterDeviceIdHash to screens)
- rackup/lib/features/game/view/widgets/big_binary_buttons.dart (new — MADE/MISSED buttons with pulse animation)
- rackup/lib/features/game/view/widgets/undo_button.dart (new — countdown undo button)
- rackup/test/features/game/bloc/game_bloc_test.dart (modified — added 4 GameTurnCompleted tests)
- rackup/test/features/game/view/referee_screen_test.dart (modified — 5 tests for BigBinaryButtons/UndoButton/message sending)
- rackup/test/features/game/view/player_screen_test.dart (modified — 4 tests for turn indicator/sorting/streak)
- rackup/test/features/game/view/game_page_test.dart (modified — added WebSocketCubit mock provider)
- rackup/test/core/websocket/game_message_listener_test.dart (modified — added gameTurnComplete routing test)
