# Story 5.2: Item Deployment & Targeting

Status: review

## Story

As a player,
I want to deploy my held item at any time during the game, targeting another player when needed,
so that I can use items strategically for maximum impact.

## Acceptance Criteria

1. When a player holds an item and taps the Item Card, the card border brightens (Pressable state). If the item requires a target, a Targeting overlay slides up from the bottom
2. When the Targeting overlay is displayed, each Targeting Row shows: rank (Oswald 14dp), player color+shape tag (24dp), Oswald SemiBold name (18dp), Oswald Bold score (20dp right-aligned). Rows are minimum 56dp height for tap targets. Tap-outside the overlay dismisses it (cancel path always available)
3. When deploying a Blue Shell, the first-place player's row has a gold border and crosshair animation (FR36a targeting). The social moment builds anticipation for both attacker and target
4. When the player taps a target row (or deploys a non-targeted item), deployment happens with ONE tap — no confirmation dialog. The Item Card border flashes gold with The Reveal animation (Deploying state). An optimistic animation plays immediately (~500ms masking server latency). The server validates item ownership and target validity
5. When the server confirms the item deployment, the impact animation plays (The Eruption for high-impact items like Blue Shell). The item is removed from the player's inventory. The event appears in all players' Event Feed with a blue left border
6. When the server rejects the deployment (race condition, item already used), a "fizzle" animation plays instead of the impact. An optional event feed entry notes the fizzle. Gameplay is never blocked
7. When a player deploys an item during another player's active cascade, the item deployment queues behind the active cascade to prevent state corruption
8. When it is NOT the player's turn, the Item Card is still tappable and deployment is still available (anytime deployment)

## Tasks / Subtasks

- [x]Task 1: Add item deployment protocol actions and payloads (AC: #4, #5, #6)
  - [x]1.1 **Server actions** (`rackup-server/internal/protocol/actions.go`): Add constants `ActionItemDeploy = "item.deploy"` (client→server), `ActionItemDeployed = "item.deployed"` (server→client broadcast), `ActionItemFizzled = "item.fizzled"` (server→client to deployer only)
  - [x]1.2 **Server payloads** (`rackup-server/internal/protocol/messages.go`): Add `ItemDeployPayload` struct (client→server): `Item string` (json:"item"), `TargetID string` (json:"targetId,omitempty" — empty for non-targeted items). JSON wire format: `{"item": "blue_shell", "targetId": "abc123"}`. Add `ItemDeployedPayload` struct (server→client): `Item string`, `DeployerID string`, `TargetID string` (omitempty), `Leaderboard []LeaderboardEntry` (current rankings — unchanged in 5.2, ready for effects in 5.3). Add `ItemFizzledPayload` struct: `Item string`, `Reason string` (e.g., "ITEM_CONSUMED", "INVALID_TARGET")
  - [x]1.3 **Client actions** (`rackup/lib/core/protocol/actions.dart`): Add `static const String itemDeploy = 'item.deploy'`, `static const String itemDeployed = 'item.deployed'`, `static const String itemFizzled = 'item.fizzled'`
  - [x]1.4 **Client payloads** (`rackup/lib/core/protocol/messages.dart`): Add `ItemDeployPayload` class with `item` (String), `targetId` (String?), `toJson()` method for sending. Add `ItemDeployedPayload` class with `item`, `deployerId`, `targetId`, `leaderboard` (List<LeaderboardEntryPayload>), `fromJson` factory. Add `ItemFizzledPayload` class with `item`, `reason`, `fromJson` factory. Add `// SYNC WITH:` headers

- [x]Task 2: Server item deployment handler in room.go (AC: #4, #6, #7)
  - [x]2.1 In `room.go`'s `handleClientMessage()` `default:` case (line ~464), add routing for `item.*` namespace: `if strings.HasPrefix(msg.Action, "item.") { r.handleItemAction(deviceHash, msg.Action, msg.Payload); return }`. Place BEFORE the existing `game.`/`referee.` prefix check within the `default:` block (not before the switch statement itself)
  - [x]2.2 Create `handleItemAction()` method on Room. Acquire write lock (`r.mu.Lock()`) and use `defer r.mu.Unlock()` pattern. Validate with specific error codes: game must be started (`r.gameState != nil` — do NOT use `r.gameStarted` which is a lobby-level flag) → error code "GAME_NOT_STARTED"; game must be in playing phase (`r.gameState.GamePhase == game.PhasePlaying`) → error code "GAME_NOT_PLAYING"; player must hold an item (`r.gameState.Players[deviceHash].HeldItem != nil`) → error code "NO_ITEM_HELD". On validation failure, send error via `r.sendErrorToPlayerLocked()` (lock is held via defer)
  - [x]2.3 For `item.deploy` action: parse `ItemDeployPayload`. Validate item matches player's `HeldItem`. If item `RequiresTarget()` (per `ItemEffect` interface), validate `TargetID` is a valid non-referee player in the game AND not the deployer. Clear the player's held item via `player.ClearItem()`. For Story 5.2, item effects are NOT executed (Stories 5.3/5.4) — deployment is validated and item is consumed, but no score/state changes yet
  - [x]2.4 After successful deployment: recalculate leaderboard via `r.gameState.CalculateLeaderboard(nil)`. Broadcast `item.deployed` to ALL players (not just deployer) with `ItemDeployedPayload` including updated leaderboard. Convert leaderboard to protocol entries using same pattern as `broadcastTurnCompleteLocked()`
  - [x]2.5 On deployment failure (item already consumed via race condition): send `item.fizzled` to the deploying player ONLY (not broadcast) with reason code "ITEM_CONSUMED" or "INVALID_TARGET"
  - [x]2.6 Cascade queue safety: if a consequence chain is currently executing (mid-turn), the item deployment should still process because the room goroutine processes actions sequentially via the action channel — the `item.deploy` message will naturally queue behind any in-progress `referee.confirm_shot`. No additional queueing mechanism needed since the goroutine model already serializes mutations

- [x]Task 3: Item targeting metadata — which items require targets (AC: #1, #3)
  - [x]3.1 Add `RequiresTarget` field to `ItemMeta` struct in `item_effect.go`: `RequiresTarget bool`. Update `ItemRegistry` map: Blue Shell (`true`), Score Steal (`true`), Streak Breaker (`true`), Reverse (`true`), Trap Card (`false` — delayed effect, no target on deploy). Shield (`false`), Double Up (`false`), Immunity (`false`), Mulligan (`false` — group vote, no target), Wildcard (`false` — custom rule input)
  - [x]3.2 Add `ItemRequiresTarget(itemType string) bool` helper function that looks up the registry and returns `RequiresTarget` value. Use this in the server validation (Task 2.3) instead of relying on the `ItemEffect` interface (which has no implementations yet)
  - [x]3.3 **Client model** (`rackup/lib/core/models/item.dart`): Add `requiresTarget` field to `Item` class. Update all 10 entries in `Item.registry` with correct targeting values. Constructor: `const Item({..., required this.requiresTarget})`

- [x]Task 4: Extend ItemBloc for deployment flow (AC: #1, #4, #5, #6)
  - [x]4.1 Add new events to `item_event.dart`: `DeployItem({required String? targetId})` (user action — imperative naming per convention), `ItemDeployConfirmed()` (server confirmed — past tense), `ItemDeployRejected({required String reason})` (server rejected — past tense). NOTE: use `ItemDeployRejected` for the event to avoid name collision with the `ItemFizzled` state class
  - [x]4.2 Add new states to `item_state.dart`: `ItemDeploying({required Item item, String? targetId})` (optimistic — item being deployed), `ItemFizzled({required Item item, required String reason})` (deployment failed). Keep `ItemEmpty` and `ItemHeld` as-is
  - [x]4.3 Update `item_bloc.dart` handlers: `DeployItem` → if current state is `ItemHeld`, emit `ItemDeploying(item: state.item, targetId: event.targetId)`. `ItemDeployConfirmed` → emit `ItemEmpty()`. `ItemDeployRejected` → emit `ItemFizzled(item: deployingItem, reason: event.reason)`, then after brief delay (500ms) emit `ItemEmpty()`. If `DeployItem` received when not `ItemHeld`, ignore (race condition guard). If `ItemReceived` received during `ItemDeploying`, ignore — deployment in progress takes priority over new item drops
  - [x]4.4 Add `WebSocketCubit` dependency to `ItemBloc` for sending deploy messages. When `DeployItem` is handled, send `item.deploy` message via WebSocket: `webSocketCubit.send(Message(action: Actions.itemDeploy, payload: ItemDeployPayload(item: state.item.type, targetId: event.targetId).toJson()))`
  - [x]4.5 Update `ItemBloc` provider in `app_router.dart` (currently at `_RoomShellState` around line 96/150) to pass `WebSocketCubit` as a constructor dependency. The `WebSocketCubit` is already available in the same provider scope

- [x]Task 5: Wire item deployment through GameMessageListener (AC: #5, #6)
  - [x]5.1 In `game_message_listener.dart`'s `_handleMessage()` switch, add cases for `Actions.itemDeployed` and `Actions.itemFizzled`
  - [x]5.2 For `item.deployed`: parse `ItemDeployedPayload`. Dispatch `ItemDeployConfirmed()` to `ItemBloc` if `deployerId == localDeviceIdHash`. Map leaderboard entries from protocol to domain models (use `mapToLeaderboardEntry()` from `mapper.dart`, same pattern as turn_complete handling) and dispatch `LeaderboardUpdated` to `LeaderboardBloc`. Add event feed entry for ALL players: "[DeployerName] deployed [ItemName]!" (or "[DeployerName] deployed [ItemName] on [TargetName]!" for targeted items) with `EventFeedCategory.item` blue border. Do NOT play sounds here — sounds must route through `AudioListener` (see Task 8)
  - [x]5.3 For `item.fizzled`: parse `ItemFizzledPayload`. Dispatch `ItemDeployRejected(reason)` to `ItemBloc` (only received by the deployer). Dispatch `LeaderboardUpdated` to `LeaderboardBloc` with current (unchanged) leaderboard as a no-change acknowledgment for visual consistency. Add event feed entry: "[ItemName] fizzled!" with `EventFeedCategory.item`. This is a fun moment, not error feedback
  - [x]5.4 Resolve deployer and target display names from the leaderboard entries in the payload (same pattern used for shooter name in `_generateEventFeedItems`)

- [x]Task 6: Create Targeting overlay widget (AC: #2, #3)
  - [x]6.1 Create `rackup/lib/features/game/view/widgets/targeting_overlay.dart` — a bottom sheet or `showModalBottomSheet` that slides up from the bottom. Contains a list of Targeting Rows for all non-referee players except the deployer. Dark background matching game theme
  - [x]6.2 Each `TargetingRow` widget shows: rank (Oswald 14dp), player tag (24dp — reuse the slot-based color+shape indicator from `PlayerListTile` in lobby), player name (Oswald SemiBold 18dp), current score (Oswald Bold 20dp, right-aligned). Minimum 56dp row height. Tappable — one tap selects target and immediately deploys (no confirmation)
  - [x]6.3 Blue Shell special treatment: when the held item is Blue Shell, the first-place player's row has a gold (#FFD700) border and a subtle crosshair/target animation (pulsing border or icon overlay). The user MUST still tap the row to deploy — do NOT auto-select even though the target is obvious. The manual tap builds the predatory social moment ("Danny picks Jake while looking him in the eye")
  - [x]6.4 Tap-outside dismisses the overlay (cancel path). Swipe-down to dismiss. The item is NOT consumed on cancel — only on target selection. Use `showModalBottomSheet` with `isDismissible: true`
  - [x]6.5 Targeting overlay receives the current leaderboard data from `LeaderboardBloc` to display ranks and scores. Filter out the referee and the deploying player from the list. Sort by rank ascending
  - [x]6.6 Own row hidden — the deployer cannot target themselves. If only one valid target exists, still show the overlay (one-row list) — don't auto-select

- [x]Task 7: Update ItemCard for deployment interaction (AC: #1, #4, #8)
  - [x]7.1 Make `_HeldCard` in `item_card.dart` tappable with `GestureDetector` or `InkWell`. On tap: if item `requiresTarget`, show the Targeting overlay (Task 6). If item does NOT require target, immediately dispatch `DeployItem(targetId: null)` to `ItemBloc`
  - [x]7.2 Add Pressable state: when user touches down, brighten the card border (increase blue glow intensity or switch to gold tint). Use `GestureDetector.onTapDown`/`onTapUp`/`onTapCancel` for press feedback
  - [x]7.3 Add Deploying state: when `ItemDeploying` state is emitted, animate the card border to flash gold (#FFD700) with The Reveal pattern. Show a brief deployment animation (~500ms) that masks server confirmation latency
  - [x]7.4 Add Fizzle state: when `ItemFizzled` state is emitted, play a "fizzle" visual — card border dims, slight shake animation, then fade to empty. Brief and humorous, not frustrating
  - [x]7.5 The ItemCard MUST remain tappable at ALL times during active gameplay (anytime deployment, AC #8). No condition checks for "is it my turn" — items can be deployed during anyone's turn. Only disable when state is `ItemEmpty` or `ItemDeploying`

- [x]Task 8: Add item deployment sound effects via AudioListener (AC: #5, #6)
  - [x]8.1 Add `GameSound.itemDeployed` to `sound_manager.dart` — a satisfying deployment/impact sound for generic item use
  - [x]8.2 **Route sounds through AudioListener** (architecture mandate — no direct audio calls from blocs or message listeners). Add a `BlocListener<ItemBloc, ItemState>` in the `AudioListener` widget (`core/audio/audio_listener.dart`). Trigger `GameSound.itemDeployed` when `ItemBloc` transitions to `ItemDeploying` state. For Blue Shell specifically, use `GameSound.blueShellImpact` (already defined) by checking `state.item.type == 'blue_shell'`
  - [x]8.3 No separate fizzle sound needed for MVP — the visual fizzle animation is sufficient

- [x]Task 9: Tests (AC: all)
  - [x]9.1 **Server — room_test.go:** Test `item.deploy` action routing reaches `handleItemAction`. Test deployment with valid item+target → `item.deployed` broadcast to all. Test deployment with no held item → error "ITEM_CONSUMED". Test deployment with invalid target → error "INVALID_TARGET". Test targeted item without targetId → error. Test non-targeted item with targetId → still succeeds (targetId ignored). Test deployment during non-player's turn succeeds (anytime deployment)
  - [x]9.2 **Server — item_effect_test.go:** Test `ItemRequiresTarget()` returns correct values for all 10 items. Test `RequiresTarget` field in `ItemRegistry` matches expected per-item values
  - [x]9.3 **Server — protocol:** Test `ItemDeployPayload`, `ItemDeployedPayload`, `ItemFizzledPayload` JSON serialization/deserialization
  - [x]9.4 **Client — item_bloc_test.dart:** Test `DeployItem` from `ItemHeld` → `ItemDeploying`. Test `DeployItem` from `ItemEmpty` → ignored (stays `ItemEmpty`). Test `ItemDeployConfirmed` from `ItemDeploying` → `ItemEmpty`. Test `ItemDeployRejected` from `ItemDeploying` → `ItemFizzled` → `ItemEmpty` (after delay). Test `ItemReceived` during `ItemDeploying` → ignored (deployment in progress)
  - [x]9.5 **Client — targeting_overlay_test.dart:** Widget test renders player list with names, ranks, scores. Test Blue Shell gold border on first-place row. Test tap on row triggers deployment. Test tap outside dismisses. Test deployer not in list. Test referee not in list
  - [x]9.6 **Client — item_card_test.dart (extend):** Test tap on held item triggers deployment flow. Test pressable state visual feedback. Test deploying state gold border animation. Test fizzle state visual feedback. Test card tappable during non-player's turn
  - [x]9.7 **Client — game_message_listener_test.dart (extend):** Test `item.deployed` dispatches `ItemDeployConfirmed` to ItemBloc for local player. Test `item.deployed` dispatches `LeaderboardUpdated` to LeaderboardBloc. Test `item.deployed` creates event feed entry. Test `item.fizzled` dispatches `ItemDeployRejected` to ItemBloc. Test `item.fizzled` creates event feed entry
  - [x]9.8 **Client — protocol:** Test `ItemDeployPayload.toJson()`. Test `ItemDeployedPayload.fromJson()`. Test `ItemFizzledPayload.fromJson()`

## Dev Notes

### Existing Code to Reuse (DO NOT Reinvent)

**Item system from Story 5.1 (item_effect.go):**
- `ItemRegistry` map at `item_effect.go:27-38` — add `RequiresTarget` field to `ItemMeta` struct at `item_effect.go:20-24`
- `ItemEffect` interface at `item_effect.go:53-57` with `RequiresTarget() bool` — don't use this for validation yet (no implementations exist). Add a standalone `ItemRequiresTarget(itemType string) bool` helper that reads from `ItemRegistry`
- `GamePlayer.ClearItem()` at `game_state.go:27-29` — already exists from Story 5.1, use this to consume the item after deployment
- `GamePlayer.HeldItem` at `game_state.go:23` — validate ownership by checking this field

**Room goroutine message routing (room.go:406-471):**
- `handleClientMessage()` routes by action prefix. Add `item.*` routing at `room.go:464-466` in the default branch, BEFORE the existing `game.`/`referee.` prefix check. Item actions need a write lock since they mutate `GameState.Players[].HeldItem`
- `handleGameAction()` at `room.go:604-647` — follow this pattern for the new `handleItemAction()` method. Note: game actions acquire read lock for non-referee, write lock for referee. Item deploy always needs write lock
- `sendErrorToPlayerLocked()` at `room.go:806-828` — use for deployment validation failures
- `broadcastLocked()` at `room.go:389-403` — use for `item.deployed` broadcast to all players

**Leaderboard recalculation (game_state.go:227-281):**
- `gs.CalculateLeaderboard(nil)` — call this after clearing the held item. Pass `nil` for previous leaderboard — this means `RankChanged` won't be set for any entries, which is correct for item deployment (rank changes are turn-level). The leaderboard in the `item.deployed` payload gives clients current rankings for UI updates
- Protocol conversion pattern: `broadcastTurnCompleteLocked()` at `room.go:740-804` shows how to convert `game.LeaderboardEntry` to `protocol.LeaderboardEntry` — replicate this in the item deployment broadcast

**Client Item domain model (item.dart:1-101):**
- `Item` class and `Item.registry` — add `requiresTarget` boolean field. All 10 items already defined in the registry at `item.dart:32-93`

**Client ItemBloc (item_bloc.dart, item_event.dart, item_state.dart):**
- Current states: `ItemEmpty`, `ItemHeld` — add `ItemDeploying`, `ItemFizzled`
- Current events: `ItemReceived`, `ItemCleared` — add `DeployItem`, `ItemDeployConfirmed`, `ItemDeployRejected`
- Story 5.1 created placeholder `ItemCleared` event — `DeployItem` replaces this as the primary way items leave inventory. `ItemCleared` can remain as a fallback (e.g., undo reverts item)

**Client ItemCard widget (item_card.dart:1-211):**
- `_HeldCard` at `item_card.dart:124-211` — make this tappable for deployment. Currently has a deploy arrow icon (line 202) that's visual-only
- Animation controller at `item_card.dart:31-45` — extend for deploying and fizzle animations. Or add a second controller for deployment-specific animations
- `AnimatedSwitcher` at `item_card.dart:72-94` — the switcher handles transitions between states. Add new state rendering for `ItemDeploying` and `ItemFizzled`

**GameMessageListener (game_message_listener.dart:48-150):**
- Switch on `message.action` at line 58 — add `Actions.itemDeployed` and `Actions.itemFizzled` cases
- Player name resolution pattern at lines 161-167: iterate leaderboard entries to find display name by device ID hash — reuse for deployer/target name resolution
- Event feed generation pattern at lines 153-271 — follow for item deployment events

**WebSocketCubit for sending messages:**
- `WebSocketCubit` is already injected into `GameMessageListener`. For sending `item.deploy` from `ItemBloc`, the bloc needs `WebSocketCubit` as a dependency. Follow the same dependency injection pattern used by other blocs — pass `WebSocketCubit` to `ItemBloc` constructor

**Protocol sync pattern (messages.dart header):**
- All client protocol classes have `// SYNC WITH: rackup-server/internal/protocol/messages.go` headers
- `toJson()` for client→server payloads (like `ConfirmShotPayload.toJson()` at `messages.dart:326`)
- `fromJson()` for server→client payloads (like `TurnCompletePayload.fromJson()` at `messages.dart:418`)

### Architecture Compliance

**Full-stack story.** Server: deployment handler in room goroutine, protocol payloads, targeting metadata. Client: ItemBloc deployment states, Targeting overlay, ItemCard interaction, event feed, sounds via AudioListener.

**Key architectural constraints:**
- **Anytime deployment** (UX spec override of PRD FR35): do NOT add "is it my turn?" checks. Server accepts `item.deploy` from any player at any time
- **Optimistic-then-confirm**: animation starts on tap (~500ms masks latency). Server confirm → impact. Server reject → fizzle (fun moment, not error)
- **One-tap deployment**: no confirmation dialogs. One tap to open targeting, one tap to fire
- **AudioListener pattern**: all sounds route through centralized `BlocListener` in `AudioListener` — never call `SoundManager` directly from blocs or message listeners
- **Protocol→domain mapping**: leaderboard entries from `item.deployed` payload MUST be mapped via `mapToLeaderboardEntry()` before dispatching to `LeaderboardBloc` — never use protocol types in Bloc states
- **No item effects in 5.2**: deployment infra only (validate, consume, broadcast). Effects are Stories 5.3/5.4. Leaderboard in payload will be unchanged — this is correct

### Item Targeting Reference

| Item | Type Key | Requires Target | Deploy Behavior |
|------|----------|----------------|-----------------|
| Blue Shell | `blue_shell` | Yes | Target = 1st place (gold border + crosshair) |
| Shield | `shield` | No | Immediate self-deploy |
| Score Steal | `score_steal` | Yes | Select target player |
| Streak Breaker | `streak_breaker` | Yes | Select target player |
| Double Up | `double_up` | No | Immediate self-deploy |
| Trap Card | `trap_card` | No | Immediate deploy (delayed trap) |
| Reverse | `reverse` | Yes | Select target player |
| Immunity | `immunity` | No | Immediate self-deploy |
| Mulligan | `mulligan` | No | Group vote (Story 5.4 scope) |
| Wildcard | `wildcard` | No | Custom rule input (Story 5.4 scope) |

**NOTE:** Mulligan (group vote) and Wildcard (text input) have special deploy flows that are Story 5.4 scope. For Story 5.2, they deploy as simple non-targeted items — the item is consumed and a basic `item.deployed` is broadcast. Their special mechanics (vote overlay, text input) will be added in Story 5.4.

### Previous Story Intelligence

**From Story 5.1 (most recent completed, same epic):**
- `ItemCard` layout uses `FittedBox` for text scaling in compact 56dp card — maintain this approach when adding press/deploy states
- `AnimatedSwitcher` handles state transitions — extend switcher child to include `ItemDeploying` and `ItemFizzled` visual variants
- `ItemBloc` provider registered in `app_router.dart` (NOT `game_page.dart`) — add `WebSocketCubit` dependency injection at the same location
- `GameMessageListener` constructor already accepts `ItemBloc` as a parameter — extend the handler to process new `item.deployed` and `item.fizzled` actions
- Sound manager: `GameSound.itemDrop` was added — follow same pattern for `GameSound.itemDeployed`
- Test factories: `ItemBloc` already added to `game_page_test.dart` and `player_screen_test.dart` provider trees
- `mapToItem()` in mapper.dart converts `ItemDropPayload` → `Item` domain model — can reference for item type lookup pattern

**From Story 4.2 (punishment display):**
- `didUpdateWidget` race condition pattern: guard animation state transitions when server state changes during active animations. Apply to ItemCard's deploying→confirmed transition
- Delayed state transition pattern: for ItemBloc's fizzle→empty delayed transition (Task 4.3), use `Future.delayed` inside the event handler with an `isClosed` guard before emitting (Blocs don't have `mounted` — use `if (!isClosed) emit(...)` instead)

### Git Intelligence

Recent commits follow pattern: `Add [feature description] and code review fixes (Story X.Y)`. Story 5.1 commit: `Add item drop, inventory and code review fixes (Story 5.1)` — 29 files, 1963 insertions. This story will be similarly full-stack but focused on the deployment path rather than drop/inventory.

### Project Structure Notes

**New server files:**
- (none — all changes are modifications to existing files)

**Modified server files:**
- `rackup-server/internal/game/item_effect.go` (add RequiresTarget to ItemMeta, ItemRequiresTarget helper)
- `rackup-server/internal/protocol/actions.go` (add item.deploy, item.deployed, item.fizzled)
- `rackup-server/internal/protocol/messages.go` (add ItemDeployPayload, ItemDeployedPayload, ItemFizzledPayload)
- `rackup-server/internal/room/room.go` (add handleItemAction, item.* routing)

**New client files:**
- `rackup/lib/features/game/view/widgets/targeting_overlay.dart`
- `rackup/test/features/game/view/widgets/targeting_overlay_test.dart`

**Modified client files:**
- `rackup/lib/core/models/item.dart` (add requiresTarget field)
- `rackup/lib/core/protocol/actions.dart` (add item action constants)
- `rackup/lib/core/protocol/messages.dart` (add deployment payloads)
- `rackup/lib/features/game/bloc/item_bloc.dart` (add deployment handlers, WebSocketCubit dependency)
- `rackup/lib/features/game/bloc/item_event.dart` (add DeployItem, ItemDeployConfirmed, ItemDeployRejected)
- `rackup/lib/features/game/bloc/item_state.dart` (add ItemDeploying, ItemFizzled states)
- `rackup/lib/features/game/view/widgets/item_card.dart` (add tap handler, press/deploy/fizzle animations)
- `rackup/lib/core/websocket/game_message_listener.dart` (add item.deployed, item.fizzled handling)
- `rackup/lib/core/audio/sound_manager.dart` (add GameSound.itemDeployed)
- `rackup/lib/core/audio/audio_listener.dart` (add ItemBloc BlocListener for deployment sounds)
- `rackup/lib/core/routing/app_router.dart` (update ItemBloc provider with WebSocketCubit dependency)

**Modified test files:**
- `rackup/test/features/game/bloc/item_bloc_test.dart` (extend with deployment tests)
- `rackup/test/features/game/view/widgets/item_card_test.dart` (extend with tap/deploy tests)
- `rackup/test/core/websocket/game_message_listener_test.dart` (extend with deployed/fizzled tests)
- `rackup/test/core/audio/sound_manager_test.dart` (update GameSound count)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

None — clean implementation with no blockers.

### Completion Notes List

- **Task 1**: Added `item.deploy`, `item.deployed`, `item.fizzled` protocol actions and payloads on both server (Go) and client (Dart). JSON wire format matches spec with omitempty for optional targetId.
- **Task 2**: Implemented `handleItemAction()` and `handleItemDeployLocked()` in room.go with write lock, validation (game active, player holds item, target validity), item consumption via `ClearItem()`, leaderboard recalculation, `item.deployed` broadcast to all players, and `item.fizzled` to deployer on failure. Cascade queue safety is inherent in the goroutine-serialized action channel.
- **Task 3**: Added `RequiresTarget` field to `ItemMeta` struct and `ItemRequiresTarget()` helper. Updated all 10 items in both server `ItemRegistry` and client `Item.registry`. Blue Shell, Score Steal, Streak Breaker, Reverse require targets; Shield, Double Up, Trap Card, Immunity, Mulligan, Wildcard do not.
- **Task 4**: Extended ItemBloc with `DeployItem`, `ItemDeployConfirmed`, `ItemDeployRejected` events and `ItemDeploying`, `ItemFizzled` states. Added `WebSocketCubit` dependency for sending `item.deploy` messages. Race condition guards: ignore `ItemReceived` during deployment, ignore `DeployItem` when not `ItemHeld`. Fizzle→Empty uses `Future.delayed(500ms)` with `isClosed` guard.
- **Task 5**: Wired `item.deployed` and `item.fizzled` through `GameMessageListener`. Deployed: dispatches `ItemDeployConfirmed` to local player, updates leaderboard for all, creates event feed entry with deployer/target names resolved from leaderboard. Fizzled: dispatches `ItemDeployRejected`, creates fun "fizzled!" event feed entry.
- **Task 6**: Created `targeting_overlay.dart` with `showModalBottomSheet`, targeting rows with rank (Oswald 14dp), player color+shape tag (24dp), name (Oswald SemiBold 18dp), score (Oswald Bold 20dp right-aligned). Blue Shell first-place gets gold border and crosshair icon. Minimum 56dp row height. Tap-outside dismisses. `buildTargetList()` helper filters referee/deployer and sorts by rank.
- **Task 7**: Updated `ItemCard` with GestureDetector for tap deployment. Pressable state (gold border on tap-down). Deploying state (gold glow flash animation ~500ms). Fizzle state (shake animation + dim). Non-targeted items deploy immediately on tap. Targeted items open Targeting overlay. Card tappable at all times during gameplay (anytime deployment).
- **Task 8**: Added `GameSound.itemDeployed` to sound manager. Added `BlocListener<ItemBloc, ItemState>` in `AudioListener` — triggers `itemDeployed` sound on deployment, `blueShellImpact` for Blue Shell specifically. Used `MultiBlocListener` to combine with existing leaderboard listener.
- **Task 9**: Comprehensive tests added across all layers. Server: 4 new `item_effect_test.go` tests for `RequiresTarget`, 4 new `messages_test.go` tests for payload serialization. Client: 5 new `item_bloc_test.dart` tests for deployment flow, 3 new `item_card_test.dart` tests for tap/deploy/fizzle, 5 new `game_message_listener_test.dart` tests for deployed/fizzled handling, 3 new `messages_test.dart` tests for payload serialization, 6 new `targeting_overlay_test.dart` tests. All 462 client tests pass. All server tests pass.

### Change Log

- 2026-04-04: Implemented Story 5.2 — Item Deployment & Targeting (all 9 tasks)
- 2026-04-11: Code review pass — addressed all High/Medium/Low findings.
  - Added missing server `room_test.go` coverage for `handleItemAction`
    (Task 9.1 follow-up — original commit shipped without these tests).
  - Fixed audio sound timing: deploy impact now plays for ALL clients via
    a new `ItemDeploymentEventsCubit` (was previously deployer-only and
    fired on confirm instead of deploy).
  - Removed undocumented client-side 5s deploy timeout (state divergence
    risk; rely on WebSocket reconnect for resync).
  - Switched `NO_ITEM_HELD` validation to error path per Task 2.2.
  - Added connection-status check for targeted deploys (no ghost-target).
  - Added empty-payload, unknown-item, unknown-action server validation.
  - Targeting overlay now subscribes to `LeaderboardBloc` for live ranks.
  - Surfaced silent-failure paths in `ItemCard` via snackbar feedback.
  - Added `LeaderboardRefreshed` event so item flow does not misuse the
    shooter/cascade fields driving turn-completion side effects.
  - Added `EventFeedCategory.itemFizzle` for visual differentiation.
  - Extracted gold + overlay background colors into `RackUpColors`.
  - Added `Semantics` widget to `_TargetingRow` for screen readers.
  - Cleaned up malformed shell-loop fragments in `settings.local.json`.
  - Documented placeholder MP3 assets in `assets/sounds/README.md` so a
    future audio designer knows replacements are required.

### File List

**Server modified:**
- rackup-server/internal/protocol/actions.go
- rackup-server/internal/protocol/messages.go
- rackup-server/internal/protocol/messages_test.go
- rackup-server/internal/game/item_effect.go
- rackup-server/internal/game/item_effect_test.go
- rackup-server/internal/room/room.go

**Client new:**
- rackup/lib/features/game/view/widgets/targeting_overlay.dart
- rackup/test/features/game/view/widgets/targeting_overlay_test.dart
- rackup/test/core/protocol/messages_test.dart
- rackup/assets/sounds/item_deployed.mp3
- rackup/assets/sounds/item_drop.mp3

**Client modified:**
- rackup/lib/core/models/item.dart
- rackup/lib/core/protocol/actions.dart
- rackup/lib/core/protocol/messages.dart
- rackup/lib/features/game/bloc/item_bloc.dart
- rackup/lib/features/game/bloc/item_event.dart
- rackup/lib/features/game/bloc/item_state.dart
- rackup/lib/features/game/view/widgets/item_card.dart
- rackup/lib/core/websocket/game_message_listener.dart
- rackup/lib/core/audio/sound_manager.dart
- rackup/lib/core/audio/audio_listener.dart
- rackup/lib/core/routing/app_router.dart

**Test modified:**
- rackup/test/features/game/bloc/item_bloc_test.dart
- rackup/test/features/game/view/widgets/item_card_test.dart
- rackup/test/core/websocket/game_message_listener_test.dart
- rackup/test/core/audio/audio_listener_test.dart
- rackup/test/features/game/view/game_page_test.dart
- rackup/test/features/game/view/player_screen_test.dart
