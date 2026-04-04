# Story 5.1: Item Drop & Inventory

Status: done

## Story

As a player,
I want to receive power-up items when I miss a shot,
so that misses feel like opportunities rather than pure punishment.

## Acceptance Criteria

1. When the referee confirms a shot as MISSED and the server processes the consequence chain, there is a 50% default probability of the player receiving an item (FR32). The item drop check is part of the atomic `game.turn_complete` message
2. When a player in last place draws an item, they draw from the full 10-item deck including Blue Shell (FR33). The item drop is framed as empowering ("The pool gods smile upon you"), not consolation
3. When a player in first place draws an item, they are excluded from Blue Shell draws and draw from the remaining 9 items (FR33)
4. When a player receives an item, the Item Card component displays in the My Status zone: dark card with electric blue (#3B82F6) 2dp border, 36dp item icon with accent color background, Oswald SemiBold 14dp item name, and "TAP TO DEPLOY" affordance text. The card has a faint glow in default state
5. When a player already holds an item and receives a new item, the new item replaces the current item with no recovery (use-it-or-lose-it, FR34)
6. When a player does not hold an item, the Item Card zone shows a 30% opacity placeholder (Empty state)
7. When a MADE shot is processed, no item drop check occurs — item drops are MISSED-only
8. When an item drops, it appears in all players' Event Feed with a blue left border, and the referee sees an announcement line for the item drop

## Tasks / Subtasks

- [x] Task 1: Define item types and deck on the server (AC: #2, #3)
  - [x] 1.1 Create `rackup-server/internal/game/item_effect.go` with the `ItemType` string constants for all 10 items: `blue_shell`, `shield`, `score_steal`, `streak_breaker`, `double_up`, `trap_card`, `reverse`, `immunity`, `mulligan`, `wildcard`. Define an `ItemEffect` interface (`Execute`, `RequiresTarget`, `RequiresVote`) — leave implementations empty for now (Stories 5.3/5.4). Define an `ItemRegistry` map from `ItemType` string to metadata (name, description, accent color hex). Define `FullDeck` (all 10 items) and `DeckWithoutBlueshell` (9 items) as slices
  - [x] 1.2 Implement `DrawItem(isLastPlace bool, isFirstPlace bool) *string` function in `item_effect.go`. If `isFirstPlace`, draw from `DeckWithoutBlueshell`. If `isLastPlace`, draw from `FullDeck` (ensuring Blue Shell is possible). Otherwise draw from `FullDeck`. Returns a random item type string, or nil if no drop (50% probability check happens in the caller step, not here — this function always returns an item)
  - [x] 1.3 Add `HeldItem *string` field to `GamePlayer` struct in `game_state.go`. When a new item is assigned, overwrite `HeldItem` unconditionally (use-it-or-lose-it). Add a `ClearItem()` method that sets `HeldItem = nil` (for future deployment in Story 5.2)

- [x] Task 2: Implement ItemDropStep in the consequence chain (AC: #1, #2, #3, #7)
  - [x] 2.1 Create an `ItemDropStep` struct in `rackup-server/internal/game/item_drop_step.go` implementing the `ChainStep` interface. The step:
    - Only runs if `ctx.ShotResult == "missed"` (skip entirely for MADE shots)
    - Rolls 50% probability (use `rand.Float64() < 0.5`)
    - If item drops: determines player rank from `ctx.Leaderboard` (isFirstPlace = rank 1, isLastPlace = rank == len(players who are not referee))
    - Calls `DrawItem(isLastPlace, isFirstPlace)` to select item
    - Assigns item to `player.HeldItem` (overwrites any existing)
    - Stores item drop result in `ctx.ItemDrop` (new field, see Task 2.2)
  - [x] 2.2 Add `ItemDrop *ItemDropResult` field to `ChainContext` struct in `engine.go`. Define `ItemDropResult` struct: `ItemType string`, `ReplacedItem *string` (the previous item lost, if any, for future analytics). The consequence chain accumulates this data for the turn_complete broadcast
  - [x] 2.3 In `room.go`'s `handleConfirmShotLocked()`, replace the `item_drop_slot` NoOpStep with the new `ItemDropStep`: `chain.ReplaceStep("item_drop_slot", &ItemDropStep{})`. This is the same pattern used for PunishmentStep and RecordThisCheckStep
  - [x] 2.4 Update cascade profile logic: if an item drops, upgrade cascade profile to `"item_punishment"` (priority 3, already defined in `cascadePriority` map in `punishment_step.go`). Add this upgrade check at the end of `ItemDropStep.Execute()` by comparing `cascadePriority[ctx.CascadeProfile]` vs `cascadePriority["item_punishment"]` and upgrading if item_punishment has higher priority — replicate the inline pattern from `PunishmentStep.Execute()` at `punishment_step.go:46-52`

- [x] Task 3: Add item drop to turn_complete protocol (AC: #1, #8)
  - [x] 3.1 **Server protocol** (`rackup-server/internal/protocol/messages.go`): Add `ItemDrop *ItemDropPayload` field to `TurnCompletePayload` struct (JSON tag: `"itemDrop,omitempty"`). Define `ItemDropPayload` struct with fields: `Item string` (the item type), `PlayerID string` (who received it). This matches the architecture's documented wire format: `"itemDrop": {"item": "blue_shell"}`
  - [x] 3.2 In `room.go`'s `broadcastTurnCompleteLocked()`, populate `payload.ItemDrop` from `chainCtx.ItemDrop` if non-nil
  - [x] 3.3 **Client protocol** (`rackup/lib/core/protocol/messages.dart`): Add `ItemDropPayload` class with `item` (String) and `playerId` (String) fields, `fromJson` factory. Add `ItemDropPayload? itemDrop` field to `TurnCompletePayload` with `fromJson` parsing. Add `// SYNC WITH: rackup-server/internal/protocol/messages.go` header per protocol sync convention
  - [x] 3.4 **Server action constants** (`actions.go`): No new actions needed — item drop is part of `game.turn_complete`, not a separate message. (Item deployment `item.deploy` / `item.deployed` / `item.fizzled` are Story 5.2 scope)

- [x] Task 4: Create Item domain model and ItemBloc on the client (AC: #4, #5, #6)
  - [x] 4.1 Create `rackup/lib/core/models/item.dart` — `Item` class with `type` (String), `displayName` (String), `accentColorHex` (String), `iconCodePoint` (int, for Material icon or custom). Include a static `Map<String, Item> registry` with all 10 items' metadata (name, color, icon). Item accent colors must be distinct from Made green, Missed red, Streak gold, and Mission purple per UX spec
  - [x] 4.2 Create `rackup/lib/features/game/bloc/item_event.dart` with events: `ItemReceived({required Item item, Item? replacedItem})`, `ItemCleared()` (for future deployment). Keep events minimal for Story 5.1 scope
  - [x] 4.3 Create `rackup/lib/features/game/bloc/item_state.dart` — sealed class: `ItemEmpty` (no item held), `ItemHeld({required Item item})`. Do NOT add deployment states yet (Story 5.2)
  - [x] 4.4 Create `rackup/lib/features/game/bloc/item_bloc.dart` — receives `ItemReceived` → emits `ItemHeld(item)`. Receives `ItemCleared` → emits `ItemEmpty`. Simple state machine for now
  - [x] 4.5 Add `mapper.dart` conversion: `ItemDropPayload` → `Item` domain model lookup via `Item.registry[payload.item]`

- [x] Task 5: Wire item drop through GameMessageListener (AC: #1, #4, #8)
  - [x] 5.1 In `game_message_listener.dart`, extract `itemDrop` from `TurnCompletePayload`. If non-null AND `payload.itemDrop.playerId == currentDeviceIdHash`, dispatch `ItemReceived` event to `ItemBloc` with the mapped `Item` domain model
  - [x] 5.2 If item drop is non-null (regardless of which player received it), add an Event Feed entry via `EventFeedCubit`: blue left border using `EventFeedCategory.item` (already exists in `event_feed_state.dart:11` with blue color), text: "[PlayerName] received [ItemName]!"
  - [x] 5.3 Add item drop sound effect: `GameSound.itemDrop` — add to `core/audio/sound_manager.dart` sound registry (note: path is `core/audio/`, not `core/sound/`). The `GameSound` enum starts at line 7. Play on item drop for ALL players (it's a communal moment). Use a positive, empowering tone (not consolation)
  - [x] 5.4 Register `ItemBloc` as a `BlocProvider` — NOTE: existing game Blocs (GameBloc, LeaderboardBloc) are NOT provided in `game_page.dart` itself; they are provided upstream in the widget tree. Find where the existing `MultiBlocProvider` or `BlocProvider` wraps the game feature and add `ItemBloc` there alongside the others. `game_page.dart` accesses blocs via `context.read<GameBloc>()` etc.

- [x] Task 6: Create ItemCard widget (AC: #4, #5, #6)
  - [x] 6.1 Create `rackup/lib/features/game/view/widgets/item_card.dart` — Widget that displays the held item. Layout (compact, fits in My Status zone ~15% of screen height):
    - Dark card background with electric blue border (#3B82F6, 2dp, `BorderRadius.circular(8)`)
    - Item icon (36dp) with accent color circular background
    - Item name (Oswald SemiBold 14dp, off-white)
    - "TAP TO DEPLOY" text (Barlow 10dp, muted lavender #8B85A1) — tapping does nothing in Story 5.1 (deployment is Story 5.2). Show the affordance text but ignore taps
    - Deploy arrow icon right-aligned (per UX spec Item Card anatomy: "Deploy arrow right-aligned") — visual affordance only, non-functional in Story 5.1
    - Card height: 56dp (UX spec Held variant). Faint glow effect: `BoxShadow` with electric blue at 15-20% opacity, blur 8dp
  - [x] 6.2 Create empty state: when no item is held, show a 30% opacity placeholder card with same dimensions but no content (or a subtle "EMPTY" text). Use `AnimatedOpacity` for transitions between empty and held states
  - [x] 6.3 Item appear animation: use The Reveal pattern — 100-200ms anticipation (scale 0.95) + 200-300ms payoff (scale 1.0 with easeOutBack). Auto-plays when transitioning from `ItemEmpty` → `ItemHeld`. Use `BlocListener<ItemBloc, ItemState>` to trigger animation controller
  - [x] 6.4 Item replacement animation: when receiving a new item while holding one, play a quick swap animation — old item fades/scales out (150ms), new item scales in with The Reveal (300ms). The `ItemReceived` event carries `replacedItem` to differentiate first-time receive from replacement

- [x] Task 7: Integrate ItemCard into PlayerScreen My Status zone (AC: #4, #6)
  - [x] 7.1 In `player_screen.dart` (lines 147-155), replace the `Text('No items', ...)` placeholder with a `BlocBuilder<ItemBloc, ItemState>` that renders the `ItemCard` widget. The ItemCard should be right-aligned in the My Status Row, taking approximately 120dp width
  - [x] 7.2 Ensure the My Status zone layout doesn't break — the existing Row has PlayerNameTag (Expanded), score Text, streak indicator, and now ItemCard. ItemCard should be a fixed-width widget (not Expanded) to avoid layout overflow

- [x] Task 8: Add referee item drop announcement (AC: #8)
  - [x] 8.1 The referee sees item drops via the Event Feed (same as players). The `EventFeedCubit` already runs on the referee screen. When `GameMessageListener` adds the item drop event feed entry (Task 5.2), it appears on the referee screen automatically. No new referee Action Zone state needed for item drops — the event feed handles narration. Referee reads: "[Player] receives: [ItemName]!" from the event feed
  - [x] 8.2 Announcement ordering when both punishment AND item drop occur on same MISSED shot: the punishment announcement flow completes first (referee reads punishment aloud → taps "Punishment Delivered" → returns to idle per Story 4.2). The item drop event feed entry is visible throughout this flow. After delivering the punishment, the referee reads the item drop from the event feed. No special sequencing code needed — the event feed entry persists for at least 2 seconds (existing EventFeedCubit hold timer)

- [x] Task 9: Tests (AC: all)
  - [x] 9.1 **Server — item_effect_test.go:** Test `DrawItem()` returns an item from full deck when last place, never Blue Shell when first place, returns from full deck for middle positions. Test item type constants are all defined
  - [x] 9.2 **Server — item_drop_step_test.go:** Test step skips on MADE shot. Test 50% probability (seed random, run multiple times, verify ~50% drop rate). Test item assigned to player.HeldItem. Test use-it-or-lose-it replacement. Test cascade profile upgrade to "item_punishment" when both item and punishment present
  - [x] 9.3 **Server — integration:** Test full consequence chain with ItemDropStep plugged in: MISSED shot → verify ChainContext.ItemDrop populated. Test MADE shot → verify ChainContext.ItemDrop is nil
  - [x] 9.4 **Server — protocol:** Test TurnCompletePayload JSON serialization includes itemDrop when present, omits when nil
  - [x] 9.5 **Client — item_bloc_test.dart:** Test ItemReceived → ItemHeld state. Test ItemCleared → ItemEmpty. Test replacement: ItemHeld → ItemReceived → new ItemHeld (previous item gone)
  - [x] 9.6 **Client — item_card_test.dart:** Widget test renders item name, icon, border color, "TAP TO DEPLOY" text. Test empty state shows placeholder. Test The Reveal animation fires on item receive
  - [x] 9.7 **Client — game_message_listener_test.dart:** Test itemDrop in turn_complete dispatches ItemReceived to ItemBloc for matching player. Test non-matching player does NOT dispatch ItemReceived. Test event feed entry created for all players on item drop
  - [x] 9.8 **Client — player_screen_test.dart:** Test ItemCard appears in My Status zone when ItemHeld. Test empty placeholder when ItemEmpty. Test layout doesn't overflow with item card present

## Dev Notes

### Existing Code to Reuse (DO NOT Reinvent)

**Consequence chain pipeline (engine.go):**
- `ConsequenceChain` struct with `ReplaceStep("item_drop_slot", step)` at `engine.go:73-89`
- `item_drop_slot` is currently `NoOpStep{}` at `engine.go:80` — replace with `ItemDropStep`
- `ChainContext` struct at `engine.go:12-47` — add `ItemDrop` field here
- Same pattern used for `PunishmentStep` and `RecordThisCheckStep` — follow their structure exactly

**Cascade profile system (punishment_step.go):**
- `cascadePriority` map at `punishment_step.go:1-12` already defines `"item_punishment": 3`
- There is NO standalone `upgradeCascadeProfile()` helper function — the cascade upgrade logic is done **inline** in `PunishmentStep.Execute()` at `punishment_step.go:46-52` (compares `cascadePriority[current]` vs `cascadePriority[new]` and upgrades if higher). Either extract this into a shared helper function to reuse in both steps, or duplicate the inline pattern in `ItemDropStep`
- Item drop + punishment → cascade profile upgrades to `"item_punishment"` automatically

**Player state (game_state.go):**
- `GamePlayer` struct at `game_state.go:16-23` — add `HeldItem *string` field
- `ProcessShot()` at `game_state.go:148-204` — do NOT modify this; item logic is in the chain step
- `CalculateLeaderboard()` at `engine.go:224-278` — use this to determine player rank for rubber banding

**Turn complete broadcast (room.go):**
- `broadcastTurnCompleteLocked()` at `room.go:737-793` — add itemDrop to payload here
- `handleConfirmShotLocked()` at `room.go:649-689` — add `chain.ReplaceStep("item_drop_slot", ...)` here alongside existing PunishmentStep replacement

**Client protocol (messages.dart):**
- `TurnCompletePayload` at `messages.dart:359-471` — add `ItemDropPayload? itemDrop` field
- Follow existing `PunishmentPayload` pattern at `messages.dart:329-349` for the new payload class
- `fromJson` factory pattern at `messages.dart:385-416` — add itemDrop parsing

**Client message dispatch (game_message_listener.dart):**
- `_handleMessage()` at `game_message_listener.dart:66-113` — add itemDrop extraction here
- Follow the punishment dispatch pattern: extract from payload, dispatch to relevant blocs
- `EventFeedCubit` already exists for narration events — add item category

**Player screen My Status zone (player_screen.dart):**
- Lines 147-155: `Text('No items', ...)` placeholder — replace with ItemCard widget
- My Status zone is `Expanded(flex: 15, ...)` in a Column layout

**Sound system (core/audio/sound_manager.dart):**
- `GameSound` enum at `sound_manager.dart:7` — add `itemDrop` variant
- Follow existing pattern for `punishmentReveal` sound registration
- NOTE: file path is `core/audio/sound_manager.dart`, NOT `core/sound/`

**Event feed (event_feed_state.dart):**
- `EventFeedCategory.item` ALREADY EXISTS at `event_feed_state.dart:11` with blue color `Color(0xFF3B82F6)` — do NOT add it again
- Existing categories: `.score`, `.streak`, `.item`, `.punishment`, `.mission`, `.system`

**Theme and colors (rackup_colors.dart):**
- `RackUpColors.itemBlue` ALREADY EXISTS at `rackup_colors.dart:23` as `Color(0xFF3B82F6)` — do NOT add it again
- Muted lavender: `RackUpColors.textSecondary` = `Color(0xFF8B85A1)` — already exists

**Animation patterns in codebase:**
- The Reveal: 100-200ms anticipation (scale 0.95) + 200-300ms payoff (easeOutBack to 1.0)
- Used in `PunishmentAnnouncementCard` (Story 4.2) — follow same `TweenSequence` + `AnimationController` pattern
- `AnimatedSwitcher` pattern used throughout game widgets

### Architecture Compliance

**This story is FULL-STACK.** Server changes: item drop logic in consequence chain, GamePlayer inventory field, protocol payload extension. Client changes: ItemBloc, ItemCard widget, protocol parsing, event feed integration, sound.

**Bloc pattern:** Create a NEW `ItemBloc` (architecture specifies 7 Blocs per game session — ItemBloc is #7). Do NOT put item state in GameBloc. ItemBloc receives events from `GameMessageListener` (via `WebSocketCubit` dispatch). State: sealed class `ItemEmpty | ItemHeld(item)`.

**Protocol sync:** Go structs in `internal/protocol/messages.go` are canonical. Dart classes in `core/protocol/messages.dart` mirror Go field-for-field. Add `// SYNC WITH:` header to new Dart types.

**Feature boundary:** ItemBloc and ItemCard live in `features/game/` (not a separate feature). Item domain model lives in `core/models/`. No cross-feature imports — ItemCard only imports from `core/` and receives data via constructor/BlocBuilder.

**Consequence chain extension:** Use the existing `ReplaceStep` mechanism. Do NOT modify the chain step ordering in `NewConsequenceChain()`. The step runs in its designated slot between punishment and mission_check. All existing PunishmentStep, RecordThisCheckStep, and NoOpStep behaviors must continue to pass all existing tests unchanged — run the full server test suite to verify no regressions.

**Wire format:** `game.turn_complete` payload gets a new optional `itemDrop` field. No new WebSocket action types for Story 5.1. `item.deploy`, `item.deployed`, `item.fizzled` are Story 5.2 scope.

### Item Deck Reference (Full 10 Items)

| Item | Type Key | Requires Target | Accent Color | Icon Suggestion |
|------|----------|----------------|--------------|-----------------|
| Blue Shell | `blue_shell` | Yes (auto: 1st place) | Electric Blue #3B82F6 | target/crosshair |
| Shield | `shield` | No (self) | Teal #14B8A6 | shield |
| Score Steal | `score_steal` | Yes | Coral #FF6B6B | swap_horiz |
| Streak Breaker | `streak_breaker` | Yes | Orange #F97316 | flash_off |
| Double Up | `double_up` | No (self) | Gold #FFD700 | double_arrow |
| Trap Card | `trap_card` | No (delayed) | Dark Red #DC2626 | warning |
| Reverse | `reverse` | Yes | Violet #8B5CF6 | swap_vert |
| Immunity | `immunity` | No (self) | Mint #10B981 | health_and_safety |
| Mulligan | `mulligan` | No (group vote) | Sky Blue #60A5FA | refresh |
| Wildcard | `wildcard` | No (custom rule) | Gold #EAB308 | star |

**NOTE:** Story 5.1 only defines the deck and implements drop + inventory display. Item effects (Execute method implementations) are Stories 5.3 and 5.4. The ItemEffect interface and per-item files (`items/blue_shell.go`, etc.) are Story 5.3/5.4 scope — do NOT create them now. Only define the item type constants, registry metadata, and drop logic in `item_effect.go`.

### Rubber Banding Logic

The rubber banding is intentionally simple:
- **Last place:** Draws from full 10-item deck (Blue Shell available = catch-up mechanic)
- **First place:** Draws from 9-item deck (no Blue Shell = can't self-protect with it)
- **Everyone else:** Draws from full 10-item deck (same as last place — rubber banding only restricts first place)

There is no weighted probability per item — all items in the applicable deck are equally likely. The 50% base probability of getting ANY item is the same for all players regardless of position.

### Cascade Profile Interaction

When a MISSED shot produces BOTH a punishment AND an item drop:
- PunishmentStep sets cascade profile based on tier (e.g., `"streak_milestone"` for mild, `"item_punishment"` for medium, `"spicy"` for spicy)
- ItemDropStep checks: if item dropped AND current cascade profile priority < `"item_punishment"` priority (3), upgrade to `"item_punishment"`
- This means: mild punishment + item drop → cascade profile becomes `"item_punishment"` (1s build instead of 500ms)
- Spicy punishment + item drop → stays `"spicy"` (spicy has higher priority)
- The cascade timing for `"item_punishment"` profile is already mapped: `CascadeTiming.delayFor("item_punishment")` returns ~1000ms

### What This Story Does NOT Include (Future Scope)

- Item deployment / targeting (Story 5.2)
- Item effect execution — Blue Shell, Shield, etc. (Stories 5.3 and 5.4)
- `item.deploy`, `item.deployed`, `item.fizzled` WebSocket messages (Story 5.2)
- Per-item Go files in `internal/game/items/` directory (Stories 5.3/5.4)
- Targeting overlay UI (Story 5.2)
- Item effects on leaderboard/score (Stories 5.3/5.4)
- Fizzle animation (Story 5.2)
- Mid-game join consolation item (FR6 — Epic 9 scope)

### Previous Story Intelligence

**From Story 4.2 (most recent completed):**
- `didUpdateWidget` race condition pattern: when server state changes trigger widget rebuilds during active animations, guard state transitions. Apply same thinking if ItemCard animation is in progress when a replacement item arrives
- Direct `GameActive(...)` constructor vs `copyWith` for nullable fields: since ItemBloc is separate from GameBloc, this specific pattern doesn't apply, but the principle does — be careful with nullable field handling in Equatable states
- `mounted` guard after `await Future.delayed()`: apply this pattern in any async animation sequencing in ItemCard
- Test count reference: Story 4.2 had 20 new tests, total suite at 418. Expect ~15-20 new tests for this story

**From Story 4.1 (punishment draw):**
- PunishmentStep implementation is the direct template for ItemDropStep — same struct pattern, same ChainStep interface, same ReplaceStep wiring in room.go
- PunishmentPayload/TurnCompletePayload extension pattern is the template for ItemDropPayload

### Git Intelligence

Recent commits follow pattern: `Add [feature description] and code review fixes (Story X.Y)`. Last 5 commits are Stories 4.2, 4.1, 3.8, 3.7, 3.6 — all following the same convention of server+client changes in single commits.

### Project Structure Notes

**New server files:**
- `rackup-server/internal/game/item_effect.go` (item types, registry, DrawItem, ItemEffect interface)
- `rackup-server/internal/game/item_drop_step.go` (ChainStep implementation)
- `rackup-server/internal/game/item_effect_test.go`
- `rackup-server/internal/game/item_drop_step_test.go`

**New client files:**
- `rackup/lib/core/models/item.dart` (Item domain model with registry)
- `rackup/lib/features/game/bloc/item_bloc.dart`
- `rackup/lib/features/game/bloc/item_event.dart`
- `rackup/lib/features/game/bloc/item_state.dart`
- `rackup/lib/features/game/view/widgets/item_card.dart`
- `rackup/test/features/game/bloc/item_bloc_test.dart`
- `rackup/test/features/game/view/widgets/item_card_test.dart`

**Modified server files:**
- `rackup-server/internal/game/engine.go` (ChainContext: add ItemDrop field)
- `rackup-server/internal/game/game_state.go` (GamePlayer: add HeldItem field)
- `rackup-server/internal/protocol/messages.go` (TurnCompletePayload: add ItemDrop, ItemDropPayload struct)
- `rackup-server/internal/room/room.go` (ReplaceStep + broadcast wiring)

**Modified client files:**
- `rackup/lib/core/protocol/messages.dart` (TurnCompletePayload: add itemDrop, ItemDropPayload class)
- `rackup/lib/core/protocol/mapper.dart` (ItemDropPayload → Item conversion)
- `rackup/lib/core/theme/rackup_colors.dart` (add itemBlue constant)
- `rackup/lib/core/websocket/game_message_listener.dart` (dispatch itemDrop to ItemBloc + EventFeed)
- `rackup/lib/core/audio/sound_manager.dart` (add itemDrop sound)
- `rackup/lib/features/game/bloc/event_feed_state.dart` (add .item category)
- `rackup/lib/features/game/view/game_page.dart` (provide ItemBloc)
- `rackup/lib/features/game/view/player_screen.dart` (replace "No items" with ItemCard)

**Modified test files:**
- `rackup/test/features/game/view/player_screen_test.dart`
- `rackup/test/features/game/bloc/game_message_listener_test.dart` (or equivalent)

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 5, Story 5.1, lines 1098-1138]
- [Source: _bmad-output/planning-artifacts/architecture.md — Consequence Chain Pipeline, lines 71-73, 748-750]
- [Source: _bmad-output/planning-artifacts/architecture.md — ItemEffect Interface, lines 698-714]
- [Source: _bmad-output/planning-artifacts/architecture.md — Atomic Turn Updates, lines 213, 218]
- [Source: _bmad-output/planning-artifacts/architecture.md — ItemBloc, line 238]
- [Source: _bmad-output/planning-artifacts/architecture.md — Item Deployment Data Flow, lines 783-796]
- [Source: _bmad-output/planning-artifacts/architecture.md — Client Bloc Architecture, lines 232-242]
- [Source: _bmad-output/planning-artifacts/architecture.md — Server Game Structure, lines 485-512]
- [Source: _bmad-output/planning-artifacts/architecture.md — Client Feature Structure, lines 574-585]
- [Source: _bmad-output/planning-artifacts/architecture.md — Protocol Sync Convention, lines 221, 349-352]
- [Source: _bmad-output/planning-artifacts/prd.md — FR32-FR36j, lines 668-684]
- [Source: _bmad-output/planning-artifacts/prd.md — FR15 Consequence Chain, line 644]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Item Card Component, lines 1065-1070]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Electric Blue Color, line 614]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — My Status Zone, lines 695-704]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Item Drop in Cascade, lines 546-558]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Cascade Timing, lines 565-578]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — The Reveal Animation, line 414]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Typography System, lines 636-660]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Color System, lines 591-634]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Item Deployment Flow, lines 924-956]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Event Feed Item, lines 1115-1120]
- [Source: _bmad-output/implementation-artifacts/4-2-punishment-display-and-referee-announcement.md — Previous story learnings]
- [Source: _bmad-output/implementation-artifacts/4-1-punishment-draw-and-tier-escalation.md — PunishmentStep pattern reference]
- [Source: rackup-server/internal/game/engine.go — ConsequenceChain, item_drop_slot NoOpStep, ChainContext]
- [Source: rackup-server/internal/game/game_state.go — GamePlayer struct]
- [Source: rackup-server/internal/game/punishment_step.go — cascadePriority map, upgradeCascadeProfile]
- [Source: rackup-server/internal/protocol/messages.go — TurnCompletePayload]
- [Source: rackup-server/internal/room/room.go — handleConfirmShotLocked, broadcastTurnCompleteLocked]
- [Source: rackup/lib/core/protocol/messages.dart — TurnCompletePayload, PunishmentPayload pattern]
- [Source: rackup/lib/core/websocket/game_message_listener.dart — turn_complete dispatch]
- [Source: rackup/lib/features/game/view/player_screen.dart — My Status zone, "No items" placeholder]
- [Source: rackup/lib/core/sound/sound_manager.dart — GameSound enum]
- [Source: rackup/lib/features/game/bloc/event_feed_state.dart — EventFeedCategory]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Fixed ItemCard layout overflow by using FittedBox for text scaling in compact 56dp card
- Updated sound_manager_test to use dynamic GameSound.values.length instead of hardcoded 5
- Added ItemBloc to game_page_test and player_screen_test provider trees

### Completion Notes List
- Task 1: Created item_effect.go with 10 item type constants, ItemRegistry, FullDeck/DeckWithoutBlueshell, DrawItem function, ItemEffect interface, HeldItem field on GamePlayer
- Task 2: Created ItemDropStep implementing ChainStep — 50% drop on missed, rubber banding (no Blue Shell for 1st place), use-it-or-lose-it replacement, cascade profile upgrade to "item_punishment"
- Task 3: Added ItemDropPayload to both server (messages.go) and client (messages.dart) protocol, wired into broadcastTurnCompleteLocked
- Task 4: Created Item domain model with registry, ItemBloc (ItemEmpty/ItemHeld states), ItemEvent (ItemReceived/ItemCleared), mapper conversion
- Task 5: Wired item drop through GameMessageListener — dispatches to ItemBloc for local player, adds event feed entry for all players, plays itemDrop sound, registered ItemBloc in app_router.dart provider tree
- Task 6: Created ItemCard widget with empty state placeholder (30% opacity), held state with electric blue border, FittedBox text layout, The Reveal animation on receive, AnimatedSwitcher for transitions
- Task 7: Replaced "No items" placeholder in player_screen.dart with ItemCard widget
- Task 8: Referee sees item drops via existing EventFeedCubit — no additional code needed
- Task 9: 24 new tests total — 8 server item_effect tests, 9 server item_drop_step tests, 2 server protocol tests, 4 client ItemBloc tests, 4 client ItemCard widget tests, 5 client game_message_listener tests, 2 client protocol deserialization tests

### File List
**New server files:**
- rackup-server/internal/game/item_effect.go
- rackup-server/internal/game/item_drop_step.go
- rackup-server/internal/game/item_effect_test.go
- rackup-server/internal/game/item_drop_step_test.go
- rackup-server/internal/protocol/messages_test.go

**Modified server files:**
- rackup-server/internal/game/engine.go (ChainContext: added ItemDrop field)
- rackup-server/internal/game/game_state.go (GamePlayer: added HeldItem field, ClearItem method)
- rackup-server/internal/protocol/messages.go (added ItemDropPayload, TurnCompletePayload.ItemDrop)
- rackup-server/internal/room/room.go (ReplaceStep item_drop_slot, broadcastTurnCompleteLocked itemDrop)

**New client files:**
- rackup/lib/core/models/item.dart
- rackup/lib/features/game/bloc/item_bloc.dart
- rackup/lib/features/game/bloc/item_event.dart
- rackup/lib/features/game/bloc/item_state.dart
- rackup/lib/features/game/view/widgets/item_card.dart
- rackup/test/features/game/bloc/item_bloc_test.dart
- rackup/test/features/game/view/widgets/item_card_test.dart

**Modified client files:**
- rackup/lib/core/protocol/messages.dart (added ItemDropPayload, TurnCompletePayload.itemDrop)
- rackup/lib/core/protocol/mapper.dart (added mapToItem conversion)
- rackup/lib/core/audio/sound_manager.dart (added GameSound.itemDrop)
- rackup/lib/core/websocket/game_message_listener.dart (item drop dispatch + event feed)
- rackup/lib/core/routing/app_router.dart (ItemBloc provider)
- rackup/lib/features/game/view/player_screen.dart (replaced "No items" with ItemCard)

**Modified test files:**
- rackup/test/core/websocket/game_message_listener_test.dart (added ItemBloc, 5 new item tests)
- rackup/test/core/audio/sound_manager_test.dart (updated player count assertion)
- rackup/test/features/game/view/player_screen_test.dart (added ItemBloc provider, updated assertion)
- rackup/test/features/game/view/game_page_test.dart (added ItemBloc provider, updated assertion)

## Change Log
- 2026-04-04: Implemented Story 5.1 — Item Drop & Inventory (full-stack: server item types/deck/drop logic, protocol extension, client ItemBloc/ItemCard/event feed/sound)
