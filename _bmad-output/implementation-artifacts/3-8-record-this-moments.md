# Story 3.8: "RECORD THIS" Moments

Status: done

## Story

As a player,
I want to be alerted before shareable moments happen during gameplay,
So that I can start recording and capture the best parts of the game.

## Acceptance Criteria

1. **AC 1: Alert Trigger & Target Exclusion** — When the server identifies a shareable moment in the consequence chain (via `record_this_check_slot`), a "RECORD THIS" alert fires on all players' screens 3-5 seconds BEFORE the reveal. The alert is NOT shown to the target player (to preserve surprise).

2. **AC 2: Alert Visual Design & Storm Pause** — The alert displays: camera emoji (80dp with pulsing border), "RECORD THIS" text (Oswald Bold 36dp, red), descriptive subtext explaining what's about to happen, and a tier badge. The storm pause mechanic activates: screen dims, screen-edge red pulse fires once (brief flash of red glow around phone border). The visual stillness serves as the alert cue.

3. **AC 3: Reveal & Eruption** — When the alert auto-dismisses and the reveal begins, the reveal hits with The Eruption pattern at full intensity. The timestamp of the moment is recorded for the Best Moments list.

4. **AC 4: Auto-Dismiss (Non-Blocking)** — The alert auto-dismisses without requiring any user interaction. Gameplay is never blocked by the alert (no modal dialogs, no OK buttons).

5. **AC 5: Cascade Timing** — The RECORD THIS path gets ~8-12 seconds total (3-5s storm pause + reveal). The `cascadeProfile` is set to `"record_this"` by the server.

## Tasks / Subtasks

- [x] Task 1: Implement `RecordThisCheckStep` in Go server (AC: 1, 5)
  - [x] 1.1 Create `record_this_step.go` in `rackup-server/internal/game/`
  - [x] 1.2 Implement `RecordThisCheckStep` that evaluates triggers: check `ctx.ShotResult == "missed"` AND `ctx.gameState.lastStreakBefore >= 4` (streak break). `lastStreakBefore` is already saved by `ProcessShot` at `game_state.go:168` — no need to modify `ShotResultStep`
  - [x] 1.3 Add `RecordThis` bool, `RecordThisSubtext` string, and `TargetPlayerHash` string fields to `ChainContext`
  - [x] 1.4 When triggered: set `ctx.RecordThis = true`, `ctx.TargetPlayerHash = ctx.ShooterHash`, `ctx.RecordThisSubtext` with shooter's display name, and `ctx.CascadeProfile = "record_this"` (overrides all lower profiles)
  - [x] 1.5 Wire step into chain via `ReplaceStep("record_this_check_slot", &RecordThisCheckStep{})` in `NewConsequenceChain()` or room initialization
  - [x] 1.6 Write tests in `record_this_step_test.go`

- [x] Task 2: Add `recordThis` fields to protocol (AC: 1)
  - [x] 2.1 Add `RecordThis bool`, `RecordThisSubtext string`, `RecordThisTargetHash string` to Go `TurnCompletePayload`
  - [x] 2.2 Populate from `ChainContext` in the room broadcast logic
  - [x] 2.3 Add matching fields to Dart `TurnCompletePayload` with `fromJson` deserialization
  - [x] 2.4 Update Dart `SYNC WITH:` header comment

- [x] Task 3: Update `CascadeTiming` delay for `record_this` (AC: 5)
  - [x] 3.1 Change `record_this` duration from 1500ms to `Duration(milliseconds: 4000)` (mid-range of 3-5s)
  - [x] 3.2 Update tests if any exist for cascade timing

- [x] Task 4: Create `RecordThisOverlay` widget (AC: 2, 3, 4)
  - [x] 4.1 Create `record_this_overlay.dart` in `rackup/lib/features/game/view/widgets/`
  - [x] 4.2 Implement full-screen overlay following `TriplePointsOverlay` pattern (StatefulWidget + SingleTickerProviderStateMixin)
  - [x] 4.3 Visual layout: camera emoji 80dp with pulsing border animation, "RECORD THIS" Oswald Bold 36dp red (#EF4444), descriptive subtext (Barlow 16dp off-white), tier badge
  - [x] 4.4 Storm pause: dim background (canvas 0.85 alpha), screen-edge red pulse (single 600ms red glow around border using `BoxDecoration` with animated red `Border`)
  - [x] 4.5 Eruption on dismiss: scale 1.0 → 1.3 → 0 (300ms) with fade-out
  - [x] 4.6 Respect reduced motion: skip pulse/scale animations, show static overlay briefly, red edge still fires as brief color flash
  - [x] 4.7 Auto-dismiss after ~4 seconds (matching cascade timing), call `onDismissed` callback
  - [x] 4.8 Accept `subtext` and `tierLabel` parameters

- [x] Task 5: Wire overlay into `GamePage` and `GameMessageListener` (AC: 1, 4)
  - [x] 5.1 Add `String localDeviceIdHash` parameter to `GameMessageListener` constructor; update `app_router.dart` to pass it from `RoomBloc` state
  - [x] 5.2 In `GameMessageListener`, extract `recordThis`, `recordThisSubtext`, `recordThisTargetHash` from `TurnCompletePayload`
  - [x] 5.3 Add `RecordThisReceived` event to `GameBloc` with subtext, targetHash fields
  - [x] 5.4 In `GameBloc`, handle event — emit flag on `GameActive` state (add `showRecordThis` bool + `recordThisSubtext` string)
  - [x] 5.5 In `GameMessageListener`, only dispatch `RecordThisReceived` if `recordThis == true` AND `localDeviceIdHash != recordThisTargetHash` AND `isGameOver == false`
  - [x] 5.6 In `GamePage`, add `BlocListener` for `showRecordThis` change — show `RecordThisOverlay` via `showGeneralDialog` (same pattern as `TriplePointsOverlay`). Overlay shows on both PlayerScreen and RefereeScreen since it's at the `GamePage` level above both.
  - [x] 5.7 On overlay dismiss, reset `showRecordThis` flag in GameBloc

- [x] Task 6: Add event feed entry for RECORD THIS moments (AC: 3)
  - [x] 6.1 In `GameMessageListener._generateEventFeedItems`, add RECORD THIS event when `recordThis == true`
  - [x] 6.2 Use `EventFeedCategory.system` (off-white) with camera emoji and subtext
  - [x] 6.3 Record timestamp for Best Moments list (store in event payload for future use)

- [x] Task 7: Tests (AC: all)
  - [x] 7.1 `record_this_step_test.go` — Go: streak break triggers (lastStreakBefore >= 4 + missed), non-trigger scenarios (streak < 4, made shot), cascade profile override, target hash and subtext set correctly
  - [x] 7.2 `record_this_overlay_test.dart` — Widget: renders content, auto-dismisses, reduced motion, calls onDismissed
  - [x] 7.3 `game_bloc_record_this_test.dart` — Bloc: RecordThisReceived event handling, state flag set/reset
  - [x] 7.4 Update `game_message_listener_test.dart` — target exclusion logic, recordThis dispatch, game-over guard (no dispatch when isGameOver)
  - [x] 7.5 Update `game_page_test.dart` — overlay shown/hidden on state change
  - [x] 7.6 Verify zero regressions on all existing 376 tests

## Dev Notes

### Architecture Compliance

- **Server-authoritative:** The server determines `recordThis` in the consequence chain — clients only render.
- **Atomic turn update:** `recordThis`, `recordThisSubtext`, and `recordThisTargetHash` are included in the single `game.turn_complete` message. No separate WebSocket message.
- **Consequence chain extension:** Use existing `ReplaceStep("record_this_check_slot", ...)` — do NOT modify the chain step ordering.
- **Cascade profile priority:** `record_this` overrides `streak_milestone` and `triple_points`. Check: if `RecordThis` is true, always set `CascadeProfile = "record_this"` regardless of other profiles.
- **Protocol sync:** Both Go and Dart `TurnCompletePayload` must stay in sync. Update the `SYNC WITH:` comment in Dart.
- **Bloc pattern:** Use existing sealed state pattern. Add fields to `GameActive` state — do NOT create a new state class for this.
- **Overlay pattern:** Follow `TriplePointsOverlay` pattern exactly — `StatefulWidget` + `SingleTickerProviderStateMixin`, `onDismissed` callback, shown via `showGeneralDialog` in `GamePage` (not a Stack child). This ensures the overlay renders above both `PlayerScreen` and `RefereeScreen`.

### MVP Trigger Logic (Server)

For Story 3.8, only one trigger is available since punishments (Epic 4) and items (Epic 5) aren't implemented yet:

- **Streak break (4+ → 0):** When a player with `unstoppable` streak (4+) misses a shot, target = that player. Subtext: "[PlayerName]'s streak just got broken!"
- **Future triggers (NOT in this story):** Spicy punishment reveal (Epic 4), Blue Shell deployment (Epic 5). These will be wired when those epics implement their `punishment_slot` and `item_drop_slot` steps.

**Pre-shot streak access:** `ProcessShot` already saves `gs.lastStreakBefore = player.Streak` at `game_state.go:168` before resetting. Since `RecordThisCheckStep` is in the same `game` package, read `ctx.gameState.lastStreakBefore` directly. No need to modify `ShotResultStep` or add a `PreviousStreak` field to `ChainContext`. To get the shooter's display name for subtext, read `ctx.gameState.Players[ctx.ShooterHash].DisplayName`.

### Visual Implementation Details

**Screen-edge red pulse:** Use a `Container` with `BoxDecoration` and animated `Border.all(color: red, width: 4)` that fades from 0 → full opacity → 0 over 600ms. Layer this behind the overlay content using a `Stack`. Only fires once (not repeating).

**Camera emoji pulsing:** Use `ScaleTransition` with a repeating controller (1.0 → 1.15 → 1.0, 800ms loop) on a `Text('📷', style: TextStyle(fontSize: 80))`.

**Tier badge:** Read current tier from `ProgressTierBar` state or pass the current tier (Mild/Medium/Spicy) as a parameter. Display as small colored badge (teal/amber/red with Barlow 12dp text).

**Reduced motion:** Check `WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations`. If true: no camera pulse, no scale eruption, static overlay shows for 1s then dismisses. Red edge pulse still fires as brief color flash (instant border show/hide).

### Cascade Timing Update

The current `CascadeTiming.delayFor('record_this')` returns 1500ms. This was a placeholder. Update to 4000ms (4 seconds) to match the 3-5 second pre-alert window. This delay controls how long the leaderboard shuffle animation waits before rendering — giving the RECORD THIS overlay time to display.

### Event Feed Integration

Add a `recordThis` event in `_generateEventFeedItems` BEFORE the score event:
```dart
if (payload.recordThis) {
  eventFeedCubit.addEvent(EventFeedItem(
    text: '📷 ${payload.recordThisSubtext}',
    category: EventFeedCategory.system,
  ));
}
```

### Project Structure Notes

**New files to create:**
- `rackup-server/internal/game/record_this_step.go`
- `rackup-server/internal/game/record_this_step_test.go`
- `rackup/lib/features/game/view/widgets/record_this_overlay.dart`
- `rackup/test/features/game/view/widgets/record_this_overlay_test.dart`
- `rackup/test/features/game/bloc/game_bloc_record_this_test.dart`

**Files to modify:**
- `rackup-server/internal/game/engine.go` — Add `RecordThis` bool, `RecordThisSubtext` string, `TargetPlayerHash` string to `ChainContext`
- `rackup-server/internal/protocol/messages.go` — Add `RecordThis`, `RecordThisSubtext`, `RecordThisTargetHash` to `TurnCompletePayload`
- `rackup-server/internal/room/room.go` — In `broadcastTurnCompleteLocked` (line ~729), add `RecordThis`, `RecordThisSubtext`, `RecordThisTargetHash` from `ChainContext` to `TurnCompletePayload` struct literal
- `rackup/lib/core/protocol/messages.dart` — Add fields to Dart `TurnCompletePayload`
- `rackup/lib/core/cascade/cascade_timing.dart` — Update `record_this` delay to 4000ms
- `rackup/lib/core/websocket/game_message_listener.dart` — Extract recordThis fields, target exclusion, dispatch
- `rackup/lib/features/game/bloc/game_event.dart` — Add `RecordThisReceived` event
- `rackup/lib/features/game/bloc/game_state.dart` — Add `showRecordThis`, `recordThisSubtext` to `GameActive`
- `rackup/lib/features/game/bloc/game_bloc.dart` — Handle `RecordThisReceived`
- `rackup/lib/features/game/view/game_page.dart` — Add RECORD THIS `BlocListener` + overlay stack
- `rackup/lib/core/routing/app_router.dart` — Pass `localDeviceIdHash` to `GameMessageListener` constructor
- `rackup/lib/features/game/bloc/event_feed_state.dart` — No changes (uses existing `system` category)

### Previous Story Intelligence (Story 3.7)

- `EventFeedCubit` is a lightweight Cubit, not full Bloc — keep it simple
- `GameMessageListener` extracts events from `TurnCompletePayload` in `_generateEventFeedItems` — add recordThis event there
- `GameEnded` is a terminal state — RECORD THIS should NOT fire if `isGameOver` is true
- `MultiBlocListener` pattern used in `game_page.dart` — add RECORD THIS listener to it
- `BlocProvider` for `EventFeedCubit` lives in `app_router.dart` `_RoomShellState`
- Widget tests use `pump()` not `pumpAndSettle()` for repeating animations (learned in 3.6)
- Total tests: 376 passing, zero regressions expected

### Git Intelligence

Recent commits follow pattern: "Add [feature description] and code review fixes (Story X.Y)"
- Story 3.7 (0bf4dad): Event feed + game end — established `EventFeedCubit`, `_generateEventFeedItems`, `GameEnded` state
- Story 3.6 (fc7efc3): Sound effects + wake lock — established `AudioListener`, `SoundManager`, reduced motion patterns
- Story 3.5 (2d9067b): Game progression + triple points — established `TriplePointsOverlay`, cascade timing, `GameActive` state extensions
- Story 3.3 (5cc4d12): Consequence chain — established `engine.go`, extension points, `ChainContext`, `CascadeProfile`

### Key Patterns to Reuse

| Pattern | Source | Reuse For |
|---------|--------|-----------|
| `TriplePointsOverlay` animation structure | `triple_points_overlay.dart` | `RecordThisOverlay` widget |
| Reduced motion check | `triple_points_overlay.dart:34-51` | `RecordThisOverlay` accessibility |
| `MultiBlocListener` in `game_page.dart` | `game_page.dart` | Adding RECORD THIS listener |
| `_generateEventFeedItems` dispatch | `game_message_listener.dart` | Adding recordThis event feed entry |
| `ReplaceStep` extension mechanism | `engine.go:84-91` | Wiring `RecordThisCheckStep` |
| `CascadeProfile` override logic | `engine.go:144-146` (triple points) | `record_this` profile override |
| `ChainContext` field addition pattern | `engine.go:30-34` | Adding RecordThis fields |
| `showGeneralDialog` overlay display | `game_page.dart` (triple points listener) | Showing RecordThisOverlay |
| `lastStreakBefore` pre-shot state | `game_state.go:168` | Detecting streak break in RecordThisCheckStep |

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.8]
- [Source: _bmad-output/planning-artifacts/architecture.md — Consequence Chain Pipeline, Cascade Timing, Protocol Types]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — "RECORD THIS" Alert Component, Storm Pause, The Eruption Pattern, Reduced Motion]
- [Source: _bmad-output/planning-artifacts/prd.md — FR54, FR55, Journey 2 (Maya Viral Loop)]
- [Source: rackup-server/internal/game/engine.go — ConsequenceChain, record_this_check_slot extension point]
- [Source: rackup-server/internal/protocol/messages.go — TurnCompletePayload]
- [Source: rackup/lib/core/protocol/messages.dart — Dart TurnCompletePayload]
- [Source: rackup/lib/core/cascade/cascade_timing.dart — CascadeTiming.delayFor]
- [Source: rackup/lib/core/websocket/game_message_listener.dart — GameMessageListener dispatch]
- [Source: rackup-server/internal/room/room.go:729 — broadcastTurnCompleteLocked builds TurnCompletePayload from ChainContext]
- [Source: rackup-server/internal/game/game_state.go:168 — lastStreakBefore saved by ProcessShot before streak reset]
- [Source: rackup/lib/core/routing/app_router.dart:104 — GameMessageListener instantiation in _RoomShellState]
- [Source: rackup/lib/features/game/view/widgets/triple_points_overlay.dart — Overlay animation pattern]
- [Source: _bmad-output/implementation-artifacts/3-7-event-feed-and-game-end.md — Previous story learnings]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Fixed app_router_test.dart: added `getHashedDeviceId()` mock after `GameMessageListener` gained `localDeviceIdHash` param
- Fixed event feed test: recordThis event is index [1] (newest-first ordering — score event added after recordThis)
- Overlay auto-dismiss test: uses full 4000ms animation duration (platform dispatcher `disableAnimations` not settable in test)

### Completion Notes List
- Task 1: `RecordThisCheckStep` in Go server — triggers on missed shot with lastStreakBefore >= 4, sets RecordThis/TargetPlayerHash/Subtext/CascadeProfile on ChainContext. Wired via ReplaceStep in room.go. 6 unit tests.
- Task 2: Protocol sync — added RecordThis, RecordThisSubtext, RecordThisTargetHash to Go TurnCompletePayload, room broadcast, and Dart TurnCompletePayload.fromJson.
- Task 3: Updated CascadeTiming record_this delay from 1500ms → 4000ms.
- Task 4: RecordThisOverlay widget — full-screen storm-pause overlay with camera emoji pulse, red edge glow, eruption dismiss animation. Reduced motion support. Auto-dismiss after 4s.
- Task 5: Wired overlay into GamePage via BlocListener pattern (same as TriplePointsOverlay). Added RecordThisReceived/RecordThisDismissed events to GameBloc, showRecordThis/recordThisSubtext to GameActive state. GameMessageListener filters by target exclusion and game-over guard. Passed localDeviceIdHash from DeviceIdentityService.
- Task 6: Event feed entry added before score event in _generateEventFeedItems with camera emoji and system category.
- Task 7: 13 new tests (6 Go + 5 Dart widget/bloc + 4 Dart listener). All 389 Flutter tests + all Go tests pass with zero regressions.

### Change Log
- 2026-04-03: Implemented Story 3.8 — RECORD THIS moments (all 7 tasks)

### File List
- `rackup-server/internal/game/record_this_step.go` (new)
- `rackup-server/internal/game/record_this_step_test.go` (new)
- `rackup-server/internal/game/engine.go` (modified — added RecordThis fields to ChainContext)
- `rackup-server/internal/protocol/messages.go` (modified — added RecordThis fields to TurnCompletePayload)
- `rackup-server/internal/room/room.go` (modified — ReplaceStep + broadcast fields)
- `rackup/lib/core/cascade/cascade_timing.dart` (modified — record_this 1500→4000ms)
- `rackup/lib/core/protocol/messages.dart` (modified — added recordThis fields to Dart TurnCompletePayload)
- `rackup/lib/core/websocket/game_message_listener.dart` (modified — localDeviceIdHash param, recordThis dispatch + event feed)
- `rackup/lib/core/routing/app_router.dart` (modified — pass localDeviceIdHash)
- `rackup/lib/features/game/bloc/game_event.dart` (modified — RecordThisReceived, RecordThisDismissed)
- `rackup/lib/features/game/bloc/game_state.dart` (modified — showRecordThis, recordThisSubtext on GameActive)
- `rackup/lib/features/game/bloc/game_bloc.dart` (modified — handle RecordThisReceived/Dismissed)
- `rackup/lib/features/game/view/game_page.dart` (modified — BlocListener for RECORD THIS overlay)
- `rackup/lib/features/game/view/widgets/record_this_overlay.dart` (new)
- `rackup/test/features/game/view/widgets/record_this_overlay_test.dart` (new)
- `rackup/test/features/game/bloc/game_bloc_record_this_test.dart` (new)
- `rackup/test/core/websocket/game_message_listener_test.dart` (modified — localDeviceIdHash + 4 recordThis tests)
- `rackup/test/core/routing/app_router_test.dart` (modified — added getHashedDeviceId mock)
