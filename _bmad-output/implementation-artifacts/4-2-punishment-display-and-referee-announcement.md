# Story 4.2: Punishment Display & Referee Announcement

Status: done

## Story

As a referee,
I want to see the drawn punishment on my screen and announce it dramatically,
so that punishments become theatrical moments that entertain the group.

## Acceptance Criteria

1. When a punishment has been drawn (turn_complete with non-null punishment), the referee's Action Zone displays:
   - Punishment text as teleprompter-style text (Barlow Condensed Bold, 24-36dp) designed for reading aloud
   - A "THE POOL GODS HAVE SPOKEN" header (Oswald Bold, depersonalizing the source)
   - A Punishment Tier Tag badge: MILD (neutral bg), MEDIUM (amber bg), SPICY (red bg), CUSTOM (purple bg) — always text + color, never color alone
   - The punishment slides into view using The Reveal animation pattern (100-200ms anticipation beat + 200-300ms payoff)
2. When the referee taps the "Delivered" button, the referee screen transitions back to the next turn's MADE/MISSED buttons — the "Delivered" button always exists as an exit path regardless of whether the punishment was actually performed
3. The punishment appears in all players' Event Feed with a red left border (already implemented in Story 4.1)
4. The referee text copy style matches the current tier: neutral tone for Mild, heightened language for Medium, dramatic language for Spicy (FR42 escalation through copy) — this refers to the HEADER copy tone, not the punishment text itself
5. Cascade timing provides a suspense gap before the punishment reveal: mild ~500ms, medium ~1000ms, spicy ~1200ms (already set server-side in Story 4.1 via cascadeProfile)

## Tasks / Subtasks

- [x] Task 1: Extend referee Action Zone state machine for punishment display (AC: #1, #2)
  - [x] 1.1 In `referee_screen.dart:20-21`, extend `_ActionZoneState` enum to add a third state: `punishment` (alongside existing `idle` and `confirmed`)
  - [x] 1.2 **CRITICAL: Fix `didUpdateWidget` race condition.** Currently `referee_screen.dart:98-107` resets `_actionState = idle` whenever shooter/round changes. Since `turn_complete` changes `currentShooter`, this fires immediately and would kill the undo→punishment flow. Fix: in `didUpdateWidget`, if `_actionZoneState == confirmed` (undo running), do NOT reset to idle — the undo/punishment flow is still in progress. Only reset to idle if state is `idle` or `punishment`. Then in `_onUndoExpired` callback, check if the last turn had a punishment — if yes, transition to `punishment` state (after cascade delay per Task 3); if no, transition to `idle` as currently
  - [x] 1.3 In the `AnimatedSwitcher` (lines 200-213), add a third case: when `_actionZoneState == _ActionZoneState.punishment`, show the new `PunishmentAnnouncementCard` widget (Task 2) with key `ValueKey('punishment')`
  - [x] 1.4 Create `_onPunishmentDelivered()` callback that sets state to `idle` — this is the only action the "Delivered" button triggers (pure UI gate, no server message needed; the turn already advanced in turn_complete)
  - [x] 1.5 Add `PunishmentPayload? lastPunishment` and `String lastCascadeProfile` as constructor parameters to `RefereeScreen` (passed from `game_page.dart` via `GameActive` state — see Task 4). In `_RefereeScreenState`, capture `widget.lastPunishment` into a local `_pendingPunishment` field in `didUpdateWidget` when a turn arrives with punishment (so it survives prop changes on next turn). Clear `_pendingPunishment` when transitioning back to idle after delivery

- [x] Task 2: Create PunishmentAnnouncementCard widget (AC: #1, #4)
  - [x] 2.1 Create `rackup/lib/features/game/view/widgets/punishment_announcement_card.dart` — new widget for the referee's punishment display
  - [x] 2.2 Layout structure (top to bottom within Action Zone ~35% of screen):
    - **Header:** "THE POOL GODS HAVE SPOKEN" (Oswald Bold 18dp, uppercase, off-white/gold tint). Tier-aware copy variants:
      - Mild: "THE POOL GODS HAVE SPOKEN" (neutral, lowercase feel)
      - Medium: "THE POOL GODS HAVE SPOKEN!" (with exclamation)
      - Spicy: "THE POOL GODS DEMAND SACRIFICE" (dramatic override)
      - Custom: "THE POOL GODS HAVE SPOKEN" (default, purple accent)
    - **Tier Tag Badge:** Compact badge (horizontal pill shape) showing tier text (UPPERCASE) with background color. Note: `PunishmentPayload.tier` stores lowercase ("mild", "medium", "spicy", "custom") — use `.toUpperCase()` for display label:
      - MILD: background `Colors.grey[700]`, text off-white
      - MEDIUM: background `Color(0xFFF59E0B)` (amber), text dark
      - SPICY: background `Color(0xFFEF4444)` (red), text white
      - CUSTOM: background `Color(0xFFA855F7)` (purple), text white
    - **Punishment Text:** The actual punishment text in Barlow Condensed Bold, 24dp minimum. Use `FittedBox` with `BoxConstraints(maxHeight: ...)` to auto-size down if text overflows, but set minimum font size to 18dp by checking text length and switching font size manually (short text = 24dp, long text = 18dp, threshold ~80 chars). Do NOT add `auto_size_text` package. Centered, max 3 lines. This is the teleprompter text the referee reads aloud
    - **"Delivered" Button:** Full-width button at bottom, Oswald SemiBold 16dp, "PUNISHMENT DELIVERED" text, subtle border, muted color (not competing with punishment text). Uses same button styling pattern as BigBinaryButtons but less prominent
  - [x] 2.3 The Reveal animation: Widget enters with a 100-200ms anticipation pause (slight scale down to 0.95) followed by a 200-300ms scale-up to 1.0 with easeOutBack curve. Use `AnimationController` in a StatefulWidget, auto-play on mount
  - [x] 2.4 Accept `PunishmentPayload` and `onDelivered` VoidCallback as constructor parameters

- [x] Task 3: Integrate cascade timing for punishment reveal delay (AC: #5)
  - [x] 3.1 The cascade timing delay is already handled server-side via `cascadeProfile` in the turn_complete payload (Story 4.1 set this up). The client's `CascadeTiming.delayFor()` already maps profiles to delays. The punishment card should respect this by delaying its reveal animation start
  - [x] 3.2 In `referee_screen.dart`, when transitioning to punishment state after undo expires, use `Future.delayed(CascadeTiming.delayFor(cascadeProfile))` before setting `_actionZoneState = _ActionZoneState.punishment`. This creates the suspense gap before the punishment reveal. **IMPORTANT:** Add `if (!mounted) return;` after the `await Future.delayed(...)` before calling `setState` — the widget could be disposed during the delay (user navigates away, game ends)
  - [x] 3.3 The cascadeProfile is available from the latest `GameTurnCompleted` event data — store it alongside the punishment payload

- [x] Task 4: Wire punishment data through GameBloc to RefereeScreen props (AC: #1)
  - [x] 4.1 **CRITICAL: `GameTurnCompleted` event does NOT currently carry punishment data.** Add `PunishmentPayload? punishment` field to the `GameTurnCompleted` event class in `game_event.dart` (line 48-119). The `cascadeProfile` field already exists (line 61/99). Punishment was NOT wired through in Story 4.1 (it was only used for event feed and sound in `GameMessageListener`, never dispatched to GameBloc). Add `punishment` to the `props` list too
  - [x] 4.2 In `game_message_listener.dart` (lines 72-86), update the `GameTurnCompleted` event dispatch to pass `payload.punishment` as the new field
  - [x] 4.3 Add `PunishmentPayload? lastPunishment` and `String lastCascadeProfile` fields to `GameActive` state (`game_state.dart`). **ALSO add both to the `props` list** (`game_state.dart:92-103`) — without this, Bloc's Equatable comparison won't detect punishment changes and BlocBuilder won't rebuild. **CRITICAL `copyWith` fix:** In `_onGameTurnCompleted` (`game_bloc.dart:67-75`), do NOT use `current.copyWith(...)` because the `?? this.field` pattern cannot set a nullable field to null (e.g., `null ?? this.lastPunishment` keeps the old value). Instead, construct `GameActive(...)` directly with all fields explicit, so `lastPunishment: event.punishment` correctly sets null on MADE shots. Other handlers (`_onRecordThisReceived`, `_onRecordThisDismissed`) can keep using `copyWith` since they don't touch punishment — the `??` pattern correctly preserves the existing punishment value
  - [x] 4.4 In `game_page.dart` (line 249-257), pass `state.lastPunishment` and `state.lastCascadeProfile` as new props to `RefereeScreen`. Add these as constructor parameters on `RefereeScreen`

- [x] Task 5: Handle edge cases (AC: #2)
  - [x] 5.1 **No punishment (MADE shot):** Action Zone transitions idle → confirmed (undo) → idle as currently. No change needed
  - [x] 5.2 **Undo during punishment display:** If somehow the state is `punishment` and an undo event arrives (unlikely since undo window expired first), reset to `idle`
  - [x] 5.3 **Game over with punishment:** If `isGameOver` is true in turn_complete AND a punishment was drawn, still show the punishment card. After "Delivered" tap, do NOT transition to idle — instead let the existing `GameEnded` BlocListener in `game_page.dart` handle navigation to the post-game screen. Set a `_gameOverPending` flag when game-over + punishment coincide; after Delivered tap, the game-over navigation fires
  - [x] 5.4 **Rapid turns:** Ensure that if a new turn_complete arrives while punishment is displayed (edge case with concurrent play), the punishment card dismisses and resets properly

- [x] Task 6: Tests (AC: all)
  - [x] 6.1 Widget test for `PunishmentAnnouncementCard`: renders header, tier badge (all 4 tiers), punishment text, and Delivered button. Verify tier-specific header copy and badge colors
  - [x] 6.2 Widget test for referee_screen Action Zone: verify state transitions idle → confirmed → punishment → idle when turn_complete has a punishment
  - [x] 6.3 Widget test for referee_screen: verify idle → confirmed → idle when turn_complete has NO punishment (regression test — existing behavior preserved)
  - [x] 6.4 Widget test for Delivered button: tapping transitions back to idle state with MADE/MISSED buttons visible
  - [x] 6.5 Widget test for The Reveal animation: verify animation controller fires on mount
  - [x] 6.6 Widget test for cascade delay: verify punishment card appearance is delayed by cascade profile duration
  - [x] 6.7 Dart: Test `GameTurnCompleted` event carries punishment field; test `GameBloc._onGameTurnCompleted` correctly sets `lastPunishment` on GameActive (non-null for missed, null for made); test that `copyWith` in other handlers preserves existing `lastPunishment`
  - [x] 6.8 Widget test for `didUpdateWidget` race condition: verify that when turn changes while in `confirmed` state (undo running), the Action Zone does NOT reset to idle — it stays in `confirmed` until undo expires

## Dev Notes

### Existing Code to Reuse (DO NOT Reinvent)

**Punishment data already flows end-to-end (Story 4.1):**
- Server draws punishment in consequence chain → included in `game.turn_complete` payload
- `PunishmentPayload` class exists at `messages.dart:329-349` with `text` and `tier` fields
- `TurnCompletePayload.punishment` (nullable) at `messages.dart:370`
- `GameMessageListener` already processes punishment: triggers sound + adds to event feed (`game_message_listener.dart:99-102, 181-189`)
- `EventFeedCategory.punishment` with RED color already defined (`event_feed_state.dart:15`)
- `GameSound.punishmentReveal` already preloaded and triggered (`sound_manager.dart:10`)

**Referee screen scaffolding already in place:**
- `referee_screen.dart` — Action Zone with `AnimatedSwitcher` at lines 196-215
- `_ActionZoneState` enum at line 20-21 (currently: idle, confirmed)
- `BigBinaryButtons` widget at `big_binary_buttons.dart` (MADE/MISSED)
- `UndoButton` widget at `undo_button.dart` with `onExpired` callback
- `_onShotConfirmed()` and `_onUndo()` callbacks already wired

**Theme and color infrastructure:**
- `RackUpColors` at `rackup_colors.dart` — tier colors, missedRed, streakGold, missionPurple
- `RackUpGameThemeData` at `game_theme.dart` — tier-aware theme with `tierForProgression()`
- `EscalationTier` enum: lobby, mild, medium, spicy

**Cascade timing already mapped (Story 4.1):**
- `CascadeTiming.delayFor()` at `cascade_timing.dart:10-21`
- Server sets cascadeProfile based on punishment tier: mild→streak_milestone(500ms), medium→item_punishment(1000ms), spicy→spicy(1200ms)

**Animation patterns in codebase:**
- `AnimatedSwitcher` pattern in referee Action Zone (300ms, fade+scale)
- `AnimatedScale` pattern in BigBinaryButtons for press feedback
- Undo countdown ring animation in UndoButton

### Architecture Compliance

**This story is CLIENT-ONLY.** No server changes needed. The punishment data already flows in `game.turn_complete` from Story 4.1. The "Delivered" button is a pure UI gate — it does NOT send a server message. The turn has already advanced when turn_complete was broadcast.

**Bloc pattern:** Add `punishment` field to `GameTurnCompleted` event AND `lastPunishment`/`lastCascadeProfile` to `GameActive` state. Do NOT create a separate PunishmentBloc. In `_onGameTurnCompleted`, construct `GameActive(...)` directly (not via `copyWith`) so nullable `lastPunishment` is correctly set to null on MADE shots. Other handlers keep using `copyWith` (they don't touch punishment, and `??` correctly preserves it). Data flows: GameBloc → GameActive → game_page.dart → RefereeScreen props → local `_pendingPunishment`.

**Widget placement:** New `punishment_announcement_card.dart` goes in `features/game/view/widgets/` alongside `big_binary_buttons.dart` and `undo_button.dart` — these are all Action Zone content widgets.

**No cross-feature imports.** PunishmentAnnouncementCard only imports from `core/` (protocol, theme, colors) and accepts data via constructor.

### Flow Diagram

```
Referee taps MISSED
  → sends referee.confirm_shot
  → Action Zone: idle → confirmed (shows UndoButton)

Server processes consequence chain (punishment drawn)
  → broadcasts game.turn_complete with punishment payload
  → GameMessageListener dispatches GameTurnCompleted (now with punishment field)
  → GameBloc emits GameActive with lastPunishment set (direct constructor, not copyWith)
  → game_page.dart rebuilds RefereeScreen with lastPunishment prop
  → All player screens update (event feed, leaderboard, sound)
  → Referee screen: didUpdateWidget captures _pendingPunishment from prop
  → didUpdateWidget does NOT reset to idle (confirmed state preserved during undo)

Undo expires (5 seconds)
  → Check: lastPunishment != null?
    YES → Wait cascadeProfile delay → Action Zone: confirmed → punishment
         (PunishmentAnnouncementCard slides in with The Reveal)
    NO  → Action Zone: confirmed → idle (next turn MADE/MISSED buttons)

Referee reads punishment aloud, taps "PUNISHMENT DELIVERED"
  → Action Zone: punishment → idle (next turn buttons appear)
```

### Typography Spec

| Element | Font | Weight | Size | Color |
|---------|------|--------|------|-------|
| Header | Oswald | Bold 700 | 18dp | Off-white with slight gold tint for spicy |
| Tier Badge | Barlow | SemiBold 600 | 12dp | Per-tier (see Task 2.2) |
| Punishment Text | Barlow Condensed | Bold 700 | 24dp (auto-size to 18dp min) | White |
| Delivered Button | Oswald | SemiBold 600 | 16dp | Muted off-white |

### Tier Badge Colors

| Tier | Background | Text | Border |
|------|-----------|------|--------|
| MILD | `Colors.grey[700]` (#616161) | Off-white | None |
| MEDIUM | `Color(0xFFF59E0B)` (amber) | Dark (#1A1832) | None |
| SPICY | `Color(0xFFEF4444)` (red) | White | None |
| CUSTOM | `Color(0xFFA855F7)` (purple) | White | None |

### The Reveal Animation Spec

```dart
// Anticipation beat: 100-200ms, scale 1.0 → 0.95
// Payoff: 200-300ms, scale 0.95 → 1.0, Curves.easeOutBack
// Total: ~400-500ms
// Auto-plays on widget mount via controller.forward()
```

### Cascade Delay Timing Note

The cascade delay fires AFTER the 5-second undo window. Total referee wait: 5s (undo) + cascade delay (0.5-1.2s) before punishment card appears. This is intentional — the undo window is for correction, the cascade delay is for suspense. For spicy tier, total wait is ~6.2s which is appropriate for dramatic build-up. The punishment reveal sound already fired immediately on turn_complete (Story 4.1), creating a "something is coming" signal during the undo window.

### What This Story Does NOT Include (Future Scope)

- Particle system escalation during punishment reveal (Epic 3 visual polish)
- Punishment history or tracking beyond event feed
- Player-side punishment card (players see punishment in event feed only, not a full card)
- Server-side delivery confirmation action (not needed — "Delivered" is UI-only)
- Item drop display on referee screen (separate story scope)

### Project Structure Notes

- New file: `rackup/lib/features/game/view/widgets/punishment_announcement_card.dart`
- New test: `rackup/test/features/game/view/widgets/punishment_announcement_card_test.dart`
- Modified: `rackup/lib/features/game/view/referee_screen.dart` (Action Zone state machine, BlocListener, didUpdateWidget fix)
- Modified: `rackup/lib/features/game/bloc/game_event.dart` (add punishment to GameTurnCompleted)
- Modified: `rackup/lib/features/game/bloc/game_state.dart` (add lastPunishment + lastCascadeProfile to GameActive)
- Modified: `rackup/lib/features/game/bloc/game_bloc.dart` (_onGameTurnCompleted uses direct constructor instead of copyWith)
- Modified: `rackup/lib/features/game/view/game_page.dart` (pass lastPunishment + lastCascadeProfile props to RefereeScreen)
- Modified: `rackup/lib/core/websocket/game_message_listener.dart` (pass punishment to GameTurnCompleted dispatch)
- Modified test: `rackup/test/features/game/view/referee_screen_test.dart`
- Modified test: `rackup/test/features/game/bloc/game_bloc_test.dart` (event + state field tests)

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 4, Story 4.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Bloc Architecture, WebSocket Protocol, Cascade Controller]
- [Source: _bmad-output/planning-artifacts/prd.md — FR41, FR42, FR43, FR44]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Punishment Reveal, The Reveal animation, Tier Tags, Cascade Timing, Typography]
- [Source: _bmad-output/implementation-artifacts/4-1-punishment-draw-and-tier-escalation.md — Previous story learnings]
- [Source: rackup/lib/features/game/view/referee_screen.dart — Action Zone AnimatedSwitcher, state machine]
- [Source: rackup/lib/features/game/view/widgets/big_binary_buttons.dart — Button styling pattern]
- [Source: rackup/lib/features/game/view/widgets/undo_button.dart — Countdown animation pattern, onExpired callback]
- [Source: rackup/lib/core/protocol/messages.dart:329-349 — PunishmentPayload class]
- [Source: rackup/lib/core/cascade/cascade_timing.dart — CascadeTiming.delayFor()]
- [Source: rackup/lib/core/theme/rackup_colors.dart — Color constants]
- [Source: rackup/lib/core/theme/game_theme.dart — EscalationTier, tierForProgression()]
- [Source: rackup/lib/core/websocket/game_message_listener.dart:99-102 — Punishment sound trigger]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- No debug issues encountered.

### Completion Notes List
- Task 1: Extended `_ActionZoneState` enum with `punishment` state. Fixed `didUpdateWidget` race condition — confirmed state is now preserved when turn changes during undo window. Added `_pendingPunishment`, `_pendingCascadeProfile`, `_gameOverPending` fields. Created `_onPunishmentDelivered()` and async `_onUndoExpired()` with cascade delay. Updated AnimatedSwitcher to three-way switch expression.
- Task 2: Created `PunishmentAnnouncementCard` widget with tier-aware header copy (mild/medium/spicy/custom), tier badge with per-tier colors, teleprompter punishment text (24dp/18dp auto-size at 80 char threshold), "PUNISHMENT DELIVERED" button, and The Reveal animation (TweenSequence: 150ms anticipation to 0.95, 250ms easeOutBack payoff to 1.0).
- Task 3: Cascade timing integrated in `_onUndoExpired()` via `CascadeTiming.delayFor()` with mounted guard after await.
- Task 4: Added `PunishmentPayload? punishment` to `GameTurnCompleted` event and props. Added `lastPunishment`/`lastCascadeProfile` to `GameActive` state, copyWith, and props. Changed `_onGameTurnCompleted` to use direct `GameActive(...)` constructor instead of `copyWith` so nullable punishment correctly clears to null on MADE shots. Wired punishment through `GameMessageListener` dispatch. Passed props from `game_page.dart` to `RefereeScreen`.
- Task 5: Edge cases handled — no-punishment MADE flow unchanged, undo clears pending punishment, game-over with punishment sets `_gameOverPending` flag, rapid turn change during punishment resets properly via `didUpdateWidget`.
- Task 6: 20 new tests (7 PunishmentAnnouncementCard widget tests, 5 GameBloc punishment tests, 8 referee_screen punishment flow tests). Full regression suite: 418/418 pass.

### Change Log
- 2026-04-03: Implemented Story 4.2 — Punishment Display & Referee Announcement

### File List
- rackup/lib/features/game/view/widgets/punishment_announcement_card.dart (NEW)
- rackup/test/features/game/view/widgets/punishment_announcement_card_test.dart (NEW)
- rackup/lib/features/game/view/referee_screen.dart (MODIFIED)
- rackup/lib/features/game/bloc/game_event.dart (MODIFIED)
- rackup/lib/features/game/bloc/game_state.dart (MODIFIED)
- rackup/lib/features/game/bloc/game_bloc.dart (MODIFIED)
- rackup/lib/features/game/view/game_page.dart (MODIFIED)
- rackup/lib/core/websocket/game_message_listener.dart (MODIFIED)
- rackup/test/features/game/view/referee_screen_test.dart (MODIFIED)
- rackup/test/features/game/bloc/game_bloc_test.dart (MODIFIED)
