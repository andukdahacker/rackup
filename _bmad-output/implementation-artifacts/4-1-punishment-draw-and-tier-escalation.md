# Story 4.1: Punishment Draw & Tier Escalation

Status: done

## Story

As a player,
I want missed shots to trigger punishments that escalate as the game progresses,
so that the stakes rise naturally and the game gets wilder over time.

## Acceptance Criteria

1. When referee confirms a shot as MISSED, system draws a punishment from the punishment deck and includes it in the atomic `game.turn_complete` WebSocket message
2. Tier progression based on game state percentage:
   - First 30% of rounds: "mild" tier
   - 30-70% of rounds: "medium" tier
   - Final 30% of rounds: "spicy" tier
3. Custom punishments (submitted during pre-game lobby) shuffled into ALL tiers with "custom" tier tag
4. Punishment deck recycling: deck never runs out; recently drawn punishments deprioritized to avoid immediate repeats
5. Punishment data appears in all players' Event Feed with red left border (EventFeedCategory.punishment)
6. Punishment reveal sound effect triggers on punishment events
7. Cascade timing uses appropriate profile based on punishment tier

## Tasks / Subtasks

- [x] Task 1: Implement server-side punishment deck and draw logic (AC: #1, #2, #3, #4)
  - [x] 1.1 Create `PunishmentDeck` struct in `rackup-server/internal/game/punishments.go` with built-in punishment entries organized by tier (mild/medium/spicy). Include ~10-15 built-in punishments per tier. Tone: mild = lighthearted/silly (e.g., "speak in an accent for the next round"), medium = escalated/challenging (e.g., "let the group choose your next drink"), spicy = dramatic/intense (e.g., "call someone in your contacts and sing happy birthday"). Hardcode in Go source as string slices — no external data file needed.
  - [x] 1.2 Add `NewPunishmentDeck(customPunishments []string)` constructor that accepts custom punishments from lobby and shuffles them into all tiers
  - [x] 1.3 Implement `Draw(tier string)` method: selects from tier pool, deprioritizes recently drawn (track last N drawn), recycles if tier exhausted
  - [x] 1.4 Implement `TierForProgression(currentRound, totalRounds int) string` — returns "mild" (0-30%), "medium" (30-70%), "spicy" (70-100%) using same percentage logic as `game_theme.dart:tierForProgression()`
  - [x] 1.5 Write comprehensive tests in `punishments_test.go`
- [x] Task 2: Implement punishment consequence chain step (AC: #1)
  - [x] 2.1 Create `PunishmentStep` struct implementing `ChainStep` interface in `rackup-server/internal/game/punishment_step.go`
  - [x] 2.2 Step logic: if shot result is MISSED → draw punishment from deck using current tier → set `ctx.Punishment` fields
  - [x] 2.3 If shot is MADE → no-op (skip punishment draw)
  - [x] 2.4 Register step in engine.go replacing the `punishment_slot` NoOpStep via `ReplaceStep("punishment_slot", punishmentStep)`
  - [x] 2.5 Write tests in `punishment_step_test.go`
- [x] Task 3: Update protocol messages (AC: #1)
  - [x] 3.1 Add nested `Punishment` struct to `TurnCompletePayload` in `rackup-server/internal/protocol/messages.go` — use nested object per architecture spec: `"punishment": {"text": "...", "tier": "SPICY"}`. Define `PunishmentPayload` struct with `Text string` and `Tier string` fields. Use `json:"punishment,omitempty"` so field is absent (not null) when no punishment drawn.
  - [x] 3.2 Add matching `PunishmentPayload` class and `punishment` field to Dart `TurnCompletePayload` in `rackup/lib/core/protocol/messages.dart` — nullable field, parse from nested JSON object, default to null when absent
  - [x] 3.3 Add `Punishment string` and `PunishmentTier string` fields to `ChainContext` in `engine.go` (flat fields here — only the protocol payload uses the nested object)
- [x] Task 4: Wire punishment deck into room lifecycle (AC: #3)
  - [x] 4.1 In `room.go`, collect all submitted custom punishments from `r.punishments` map values into a `[]string` slice
  - [x] 4.2 Store `PunishmentDeck` on the room struct (alongside `gameState`) so it persists across turns
  - [x] 4.3 At the chain construction site (`room.go:651-658`, where `NewConsequenceChain()` and `ReplaceStep` calls happen), construct `PunishmentStep` with the deck reference and register it: `chain.ReplaceStep("punishment_slot", &game.PunishmentStep{Deck: r.punishmentDeck})`
  - [x] 4.4 Handle edge case: if `r.punishments` map is empty (all players timed out without submitting), construct deck with empty custom list — deck uses built-ins only
- [x] Task 5: Update client to handle punishment in turn_complete (AC: #5, #6, #7)
  - [x] 5.1 Update `GameMessageListener._generateEventFeedItems()` to add punishment event when `payload.punishment` is non-null — insert AFTER the "missed" score event and BEFORE streak events. Use `EventFeedCategory.punishment` (red), format: "🎯 {shooterName}: {punishmentText}" (shooter = person who missed)
  - [x] 5.2 Trigger punishment reveal sound directly in `GameMessageListener` (where turn_complete is processed, around line 62-103) — when `payload.punishment != null`, call `soundManager.play(GameSound.punishmentReveal)`. Do NOT use AudioListener BlocListener pattern (no PunishmentBloc exists). Update the extension point comment at `audio_listener.dart:29-32` to note sound is triggered from GameMessageListener instead.
  - [x] 5.3 Cascade profile is set server-side and already flows through `payload.cascadeProfile` — no client-side upgrade logic needed. Verify `cascade_timing.dart` mappings work correctly with the new profiles the server sends.
- [x] Task 6: Tests (AC: all)
  - [x] 6.1 Go: punishment deck unit tests (tier selection, custom mixing, recycling, deprioritization)
  - [x] 6.2 Go: punishment step tests (missed → draws, made → skips, tier calculation)
  - [x] 6.3 Go: integration test — full consequence chain with punishment step producing correct TurnCompletePayload
  - [x] 6.4 Dart: protocol deserialization test for punishment fields in TurnCompletePayload
  - [x] 6.5 Dart: event feed generation test for punishment events
  - [x] 6.6 Dart: cascade timing test for punishment profiles

## Dev Notes

### Existing Code to Reuse (DO NOT Reinvent)

**Server-side scaffolding already in place:**
- `room.go:52` — `punishments map[string]string` already stores player-submitted custom punishments (deviceIdHash → text)
- `room.go:413-439` — Submission handler validates, stores, updates player status
- `room.go:524-531` — Game start already validates all punishments submitted or timeout elapsed
- `engine.go:75` — `punishment_slot` placeholder is `NoOpStep()` ready for `ReplaceStep()`
- `engine.go:12-43` — `ChainContext` already has `CascadeProfile` field
- `protocol/actions.go:8` — `ActionLobbyPunishmentSubmitted` already defined

**Client-side scaffolding already in place:**
- `punishment_deck.dart` — 30 built-in punishments with `randomPunishment()` (for lobby UI only, NOT for game-time draw — server draws from its own deck)
- `punishment_input.dart` — Complete lobby submission UI (rotating placeholders, Random button, submit flow)
- `event_feed_state.dart:15` — `EventFeedCategory.punishment` with RED color (#EF4444) already defined
- `cascade_timing.dart` — `item_punishment` (1000ms) and `spicy` (1200ms) profiles already mapped
- `sound_manager.dart:10` — `GameSound.punishmentReveal` already defined and preloaded
- `audio_listener.dart:29-32` — Extension point comment marks exact location for punishment sound trigger
- `game_message_listener.dart:208-211` — Extension point comment marks location for punishment event feed items

### Architecture Compliance

**Server-authoritative:** ALL punishment logic (deck management, tier calculation, draw selection) runs on the Go server. Client never selects punishments — it only receives and displays them.

**Atomic turn updates:** Punishment MUST be included in the single `game.turn_complete` message alongside all other consequences. Never send punishment as a separate message.

**Consequence chain pipeline order:**
```
shot_result → streak_update → [punishment_slot] → [item_drop_slot] → [mission_check_slot] → score_update → leaderboard_recalc → UI_events → sound_triggers → [record_this_check_slot]
```
Punishment step runs AFTER streak_update and BEFORE item_drop_slot.

**Protocol structure:** Punishment uses a nested object in the JSON payload per architecture spec: `"punishment": {"text": "...", "tier": "SPICY"}`. Use `omitempty` in Go / nullable in Dart so the field is absent when no punishment is drawn (on MADE shots). Go `messages.go` and Dart `messages.dart` must stay in sync (see comment at messages.dart:1).

### Tier Calculation

Tier boundaries use the SAME percentage logic as the client theme system (`game_theme.dart:tierForProgression()`):
- `currentRound / totalRounds <= 0.3` → mild
- `currentRound / totalRounds <= 0.7` → medium
- `currentRound / totalRounds > 0.7` → spicy

This ensures server tier selection matches client visual tier (background colors already transition at same thresholds).

### Custom Punishment Mixing

Custom punishments submitted in lobby are tagged with tier "custom" and shuffled into ALL tier pools. When drawing from mild/medium/spicy pool, there's a chance of drawing a "custom" entry instead. The tier tag in the protocol message should reflect "custom" (not the pool tier) so the client can display the purple CUSTOM badge in Story 4.2. For the event feed in this story, the tier is not displayed — just the punishment text.

### Deck Recycling & Deprioritization

- Maintain a "recently drawn" list (last 5-10 entries)
- When drawing, prefer punishments NOT in recently-drawn list
- If all punishments in a tier are recently-drawn, reset and draw any
- Deck never exhausts — it recycles
- Edge case: if zero custom punishments submitted (all players timed out), deck operates with built-ins only — no error, no special handling needed

### Cascade Profile Upgrade Logic

Server sets `cascadeProfile` in `ChainContext`. When punishment is drawn, upgrade based on tier:
- Mild punishment: upgrade to "streak_milestone" (500ms) — lightweight reveal
- Medium punishment: upgrade to "item_punishment" (1000ms) — moderate build
- Spicy punishment: upgrade to "spicy" (1200ms) — dramatic build
- Never downgrade an already-higher profile. Priority order: record_this (4000ms) > spicy (1200ms) > item_punishment (1000ms) > triple_points (500ms) > streak_milestone (500ms) > routine (0ms)

These values align with UX spec cascade timing: mild ~2s total, medium ~4s total, spicy ~5-8s total (the cascade delay is only the pre-reveal build; total includes animation rendering time on client).

### Pattern Reference: record_this_step.go

Follow the same pattern as `record_this_step.go` for implementing `PunishmentStep`:
- Implement `ChainStep` interface with `Execute(ctx *ChainContext) error`
- Check preconditions (shot must be MISSED)
- Set context fields (Punishment, PunishmentTier)
- Optionally upgrade cascade profile
- Return nil on success

### File Naming Convention

Follow existing patterns:
- Go: `punishment_step.go` / `punishment_step_test.go` (in `internal/game/`)
- Go: `punishments.go` / `punishments_test.go` (in `internal/game/`)
- Tests co-located with source files

### What This Story Does NOT Include (Story 4.2 Scope)

- Referee screen punishment display (teleprompter-style text, "THE POOL GODS HAVE SPOKEN" header)
- Tier tag badge visual component on referee screen
- "Delivered" button on referee screen
- Cascade reveal animation timing on referee screen
- Copy escalation (language intensity by tier)

This story focuses ONLY on the server-side draw logic, protocol integration, event feed, and sound trigger. The visual referee announcement is Story 4.2.

### Project Structure Notes

- Server punishment files go in `rackup-server/internal/game/` alongside existing chain steps
- No new Dart files needed — only modifications to existing listeners and protocol
- Test factories in `rackup-server/internal/testutil/factories.go` for Go test helpers

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 4, Story 4.1]
- [Source: _bmad-output/planning-artifacts/architecture.md — Consequence Chain Pipeline, Protocol Messages]
- [Source: _bmad-output/planning-artifacts/prd.md — FR41, FR42, FR43, FR44]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR2, UX-DR5, UX-DR80]
- [Source: rackup-server/internal/game/engine.go — ChainContext, punishment_slot]
- [Source: rackup-server/internal/game/record_this_step.go — Pattern reference for chain step]
- [Source: rackup-server/internal/room/room.go — Punishment storage and submission handling]
- [Source: rackup/lib/core/audio/audio_listener.dart:29-32 — Extension point for punishment sound]
- [Source: rackup/lib/core/websocket/game_message_listener.dart:208-211 — Extension point for event feed]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- All Go tests pass: `go test ./...` — game, handler, room, auth packages
- All Dart tests pass: `flutter test` — 400 tests, 0 failures
- Flutter analyze: only pre-existing info-level lints, no errors/warnings

### Completion Notes List
- Task 1: Created `PunishmentDeck` with 12 built-in punishments per tier (mild/medium/spicy), custom mixing into all pools, Draw() with deprioritization (last 8), tier recycling, and `TierForProgression()` matching client theme thresholds
- Task 2: Created `PunishmentStep` implementing `ChainStep` — draws punishment on missed shots, skips on made. Cascade profile upgrade logic: mild→streak_milestone, medium→item_punishment, spicy→spicy. Never downgrades existing higher profile
- Task 3: Added `PunishmentPayload` struct (Go) and class (Dart) with `text`/`tier` fields. Go uses `omitempty` pointer, Dart uses nullable. Added `Punishment`/`PunishmentTier` flat fields to `ChainContext`
- Task 4: Room constructs `PunishmentDeck` at game start from `r.punishments` map. Deck stored on room struct. PunishmentStep registered via `ReplaceStep("punishment_slot", ...)` in chain construction. Empty custom list handled gracefully
- Task 5: Added punishment event feed item (red, EventFeedCategory.punishment) after score event. Sound triggered via `SoundManager.play(GameSound.punishmentReveal)` directly in `GameMessageListener`. Created SoundManager at `_RoomShell` level for listener access. Updated extension point comments in `audio_listener.dart`
- Task 6: 17 Go tests (11 unit + 3 integration + 3 existing pattern), 4 new Dart tests (punishment event feed, no-punishment, deserialization, cascade timing). All 400 Dart tests pass, all Go tests pass

### Change Log
- 2026-04-03: Implemented Story 4.1 — punishment draw and tier escalation (all 6 tasks)

### File List
**New files:**
- `rackup-server/internal/game/punishments.go` — PunishmentDeck, tier constants, Draw(), TierForProgression()
- `rackup-server/internal/game/punishments_test.go` — 11 unit tests for deck logic
- `rackup-server/internal/game/punishment_step.go` — PunishmentStep chain step, cascade priority
- `rackup-server/internal/game/punishment_step_test.go` — 8 unit tests for step logic
- `rackup/test/core/cascade/cascade_timing_test.dart` — 4 cascade timing tests

**Modified files:**
- `rackup-server/internal/game/engine.go` — Added Punishment/PunishmentTier fields to ChainContext
- `rackup-server/internal/game/engine_test.go` — Added 3 punishment integration tests
- `rackup-server/internal/protocol/messages.go` — Added PunishmentPayload struct, Punishment field on TurnCompletePayload
- `rackup-server/internal/room/room.go` — Added punishmentDeck to Room struct, deck construction at game start, PunishmentStep registration in chain, punishment payload in broadcast
- `rackup/lib/core/protocol/messages.dart` — Added PunishmentPayload class, punishment field on TurnCompletePayload
- `rackup/lib/core/websocket/game_message_listener.dart` — Added SoundManager param, punishment event feed item, punishment sound trigger
- `rackup/lib/core/audio/audio_listener.dart` — Updated extension point comment
- `rackup/lib/core/routing/app_router.dart` — Added SoundManager creation and disposal, passed to GameMessageListener
- `rackup/test/core/websocket/game_message_listener_test.dart` — Added SoundManager mock, 4 new punishment tests
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — Story status updated
