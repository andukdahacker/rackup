# Story 2.2: Punishment Submission

Status: review

## Story

As a player,
I want to submit a custom punishment before the game starts,
So that the punishment deck includes personal, group-specific challenges.

## Acceptance Criteria

1. **Given** a player is in the pre-game lobby, **When** the punishment input area renders, **Then** a text field is displayed (Barlow 14dp) with rotating placeholder examples (e.g., "Do your best impression of someone here"), **And** a "Random" button (purple accent, small) is available to generate a punishment from a built-in deck.

2. **Given** the player has not yet submitted a punishment, **When** they type in the punishment input, **Then** their lobby status changes to "Writing..." (amber `#FFB347`) visible to all players, **And** the input field shows a focused state with blue border.

3. **Given** the player has entered punishment text or tapped "Random", **When** they submit the punishment, **Then** the input becomes read-only with a checkmark visible (Submitted state), **And** their lobby status changes to "Ready" (green checkmark, `RackUpColors.madeGreen` `#16A34A`) visible to all players, **And** the punishment text is sent to the server and stored in the room's punishment deck, **And** the punishment is visible only to players within the same room (NFR13).

4. **Given** the player taps the "Random" button, **When** a random punishment is generated, **Then** the text field populates with a punishment from a built-in deck, **And** the player can edit it before submitting or submit as-is.

## Tasks / Subtasks

- [x] Task 1: Extend PlayerStatus enum and update status rendering (AC: #2, #3)
  - [x] `rackup/lib/core/models/player.dart`: Add `writing` and `ready` values to `PlayerStatus` enum
  - [x] `rackup/lib/core/protocol/mapper.dart`: Update `_mapStatus()` switch to map `'writing'` → `PlayerStatus.writing` and `'ready'` → `PlayerStatus.ready`
  - [x] `rackup/lib/features/lobby/view/widgets/player_list_tile.dart`: Update `_statusText()` and `_statusColor()` switches — `writing` → "Writing..." / amber `#FFB347`, `ready` → "Ready" / `RackUpColors.madeGreen`. Add green checkmark icon for ready state.
  - [x] Update existing player model and mapper tests for new statuses

- [x] Task 2: Add protocol layer for punishment submission (AC: #2, #3)
  - [x] **Dart** `actions.dart`: Add `lobbyPunishmentSubmitted = 'lobby.punishment_submitted'` and `lobbyPlayerStatusChanged = 'lobby.player_status_changed'` constants (replace placeholder comments)
  - [x] **Dart** `messages.dart`: Add `PunishmentSubmitPayload` (text: String) for client→server, `PlayerStatusChangedPayload` (deviceIdHash: String, status: String) for server→client broadcast
  - [x] **Go** `actions.go`: Add `ActionLobbyPunishmentSubmitted`, `ActionLobbyPlayerStatusChanged`
  - [x] **Go** `messages.go`: Add `PunishmentSubmitPayload` (Text string), `PlayerStatusChangedPayload` (DeviceIDHash string, Status string) structs

- [x] Task 3: Extend server room for punishment tracking and status changes (AC: #2, #3)
  - [x] `room.go`: Add `punishments map[string]string` field to Room struct (deviceIdHash → punishment text). Add `playerStatuses map[string]string` field (deviceIdHash → status string, default "joining").
  - [x] `room.go`: Update `NewRoom()` to initialize both maps
  - [x] `room.go`: Update `buildRoomStateLocked()` to use `playerStatuses[deviceHash]` instead of hardcoded `"joining"`
  - [x] `room.go`: In `Run()` action loop, handle `client_message` action type — parse incoming `Message`, check action:
    - `lobby.punishment_submitted`: Extract text from payload, store in `punishments` map, update `playerStatuses` to `"ready"`, broadcast `lobby.player_status_changed` with status `"ready"` to all players
    - `lobby.player_status_changed`: Extract status from payload, update `playerStatuses`, broadcast to all players (including sender — client handles idempotently, and this ensures consistency on reconnect)
  - [x] `room.go`: Server-side validation: reject punishment text longer than 140 characters (send `error` action back to sender with code `PUNISHMENT_TOO_LONG`)
  - [x] `room.go`: Add `AllPunishmentsSubmitted() bool` method (returns true if `len(punishments) == len(players)`) — Story 2.3 will use this for slide-to-start enablement
  - [x] `room.go`: Add `punishmentPhaseStartedAt time.Time` field to Room struct — set when first player joins. Story 2.3 will use this for the configurable timeout that allows game start even if not all punishments are submitted (FR8).
  - [x] Add Go tests for punishment submission handling, status broadcast, and room state with statuses

- [x] Task 4: Extend RoomBloc and LobbyMessageListener for status changes (AC: #2, #3)
  - [x] `room_event.dart`: Add `PlayerStatusChanged(String deviceIdHash, PlayerStatus status)` event and `PunishmentSubmitted(String text)` event
  - [x] `room_bloc.dart`: Add handler `_onPlayerStatusChanged` — update the matching player's status in the `RoomLobby` player list (create new Player with `copyWith` or reconstruct). Add handler `_onPunishmentSubmitted` — send punishment via WebSocket.
  - [x] `player.dart`: Add `copyWith()` method to Player class for immutable status updates
  - [x] `lobby_message_listener.dart`: Add cases for `Actions.lobbyPlayerStatusChanged` — parse `PlayerStatusChangedPayload`, map status string to `PlayerStatus`, dispatch `PlayerStatusChanged` event to RoomBloc
  - [x] Add Bloc tests for `PlayerStatusChanged` and `PunishmentSubmitted` events

- [x] Task 5: Create built-in punishment deck (AC: #4)
  - [x] Create `rackup/lib/core/data/punishment_deck.dart` — a static list of ~30 fun, bar-appropriate punishments. Examples: "Do your best impression of someone here", "Text the 3rd person in your contacts 'I love you'", "Speak in an accent until your next turn", "Let the group pick your next drink order", "Do 10 push-ups right now". Categorize loosely but no tier logic needed (tiers are a game-phase concept from Epic 4, not lobby).
  - [x] Add a `randomPunishment()` function that returns a random entry from the deck

- [x] Task 6: Create PunishmentInput widget (AC: #1, #2, #3, #4)
  - [x] Create `rackup/lib/features/lobby/view/widgets/punishment_input.dart`
  - [x] States: Empty (placeholder visible), Focused (blue border `RackUpColors.itemBlue` `#3B82F6`), Filled (user text), Submitted (read-only, checkmark overlay)
  - [x] Text field: Barlow 14dp (`RackUpTypography.caption`), dark background, light text. Max 140 characters — add a character counter and enforce limit on both client and server.
  - [x] Rotating placeholder examples — cycle through 3-4 examples from the punishment deck using a Timer (3-second interval). Only rotate while field is empty and unfocused.
  - [x] "Random" button: Purple accent (`RackUpColors.missionPurple` `#A855F7`), small, positioned to the right of the text field or below it. On tap → populate text field with `randomPunishment()`. Player can still edit before submitting.
  - [x] Submit button: Appears when text field is non-empty. On tap → send `PunishmentSubmitted` event to RoomBloc, transition to Submitted state (read-only with checkmark).
  - [x] Submitted state: TextField becomes read-only, shows green checkmark icon overlay, muted appearance. Text remains visible so player can see what they submitted.
  - [x] Accessibility: Semantics labels on text field ("Enter a custom punishment"), Random button ("Generate random punishment"), Submit button ("Submit punishment"). Min 56dp tap targets. `ClampedTextScaler` on all text.
  - [x] Widget tests for all states and transitions

- [x] Task 7: Integrate PunishmentInput into LobbyPage (AC: #1, #5)
  - [x] `lobby_page.dart`: Replace `// TODO: Story 2.2 — Punishment input` with `PunishmentInput` widget
  - [x] Position below the player list in the bottom section of the layout (bottom-weighted interaction pattern)
  - [x] PunishmentInput must send status change to server when user starts typing (transition from "joining" to "writing"). Use `onChanged` callback to detect first keystroke and send `lobby.player_status_changed` with status `"writing"` via WebSocket (only send once, not on every keystroke).
  - [x] Widget tests for LobbyPage with PunishmentInput integration

- [x] Task 8: WebSocket message sending for punishment (AC: #2, #3)
  - [x] In `room_bloc.dart`: `_onPunishmentSubmitted` handler constructs a `Message` with action `lobby.punishment_submitted` and payload `{"text": "..."}`, sends via `_webSocketCubit.sendMessage()`
  - [x] Add a method or event to send status changes: when typing starts, send `Message` with action `lobby.player_status_changed` and payload `{"status": "writing"}` via WebSocketCubit
  - [x] Ensure WebSocketCubit.sendMessage() is used (already exists at line 111 of web_socket_cubit.dart)

- [x] Task 9: Add comprehensive tests (AC: all)
  - [x] Unit tests for `PlayerStatus` new values and `Player.copyWith()` (4 tests)
  - [x] Unit tests for protocol mapper new status mappings (3 tests)
  - [x] Unit tests for `punishment_deck.dart` — randomPunishment returns valid string, list is non-empty (2 tests)
  - [x] RoomBloc tests: `PlayerStatusChanged`, `PunishmentSubmitted` events (4 tests)
  - [x] LobbyMessageListener tests: handle `lobby.player_status_changed` message (2 tests)
  - [x] Widget tests for `PunishmentInput`: empty, focused, filled, random, submitted states (8 tests)
  - [x] Widget tests for `PlayerListTile` with writing and ready statuses (3 tests)
  - [x] Widget tests for `LobbyPage` with punishment input visible (2 tests)
  - [x] Go server tests: punishment submission handling, status broadcast, AllPunishmentsSubmitted, text length rejection (6 tests)
  - [x] Target: ~34 new tests, maintain zero regressions

## Dev Notes

### Architecture Compliance

- **State management**: RoomBloc manages both player list AND punishment submission during lobby phase. `RoomLobby` state carries the player list; individual player statuses flow through the Player model. Do NOT create a separate PunishmentBloc — the architecture specifies RoomBloc owns this.
- **Protocol → Model separation**: Wire types in `core/protocol/`, domain models in `core/models/`. Never use protocol types in Bloc states or widgets.
- **Feature isolation**: All punishment input code stays in `features/lobby/`. The built-in punishment deck goes in `core/data/` as it will be reused by Epic 4 (game-phase punishment draws).
- **Server authoritative**: Server stores punishments and broadcasts status changes. Client sends punishment text; server confirms and broadcasts. Client does NOT optimistically update other players' statuses.
- **No database in hot path**: Punishments stored in-memory in Room struct maps. No DB calls during lobby phase.
- **Immutable state**: Player model updated via `copyWith()`. RoomBloc emits new `RoomLobby` with updated player list on every status change. Never mutate existing state objects.

### Existing Code to Reuse (DO NOT recreate)

| Component | Location | Usage |
|-----------|----------|-------|
| `Player` model | `core/models/player.dart` | Extend with `copyWith()`, add enum values |
| `PlayerStatus` enum | `core/models/player.dart` | Add `writing` and `ready` values |
| `PlayerListTile` | `features/lobby/view/widgets/player_list_tile.dart` | Update `_statusText()` and `_statusColor()` switches |
| `LobbyMessageListener` | `core/websocket/lobby_message_listener.dart` | Add case for `lobby.player_status_changed` |
| `RoomBloc` | `features/lobby/bloc/room_bloc.dart` | Add event handlers, do NOT restructure |
| `WebSocketCubit.sendMessage()` | `core/websocket/web_socket_cubit.dart:111` | Use for sending punishment and status messages |
| `Message.toRawJson()` | `core/protocol/messages.dart` | Construct outgoing messages |
| `RackUpTypography.caption` | `core/theme/rackup_typography.dart` | Barlow 14dp for text field |
| `RackUpColors` | `core/theme/rackup_colors.dart` | `.madeGreen` (#16A34A), `.textSecondary` (#8B85A1), `.canvas` (#0F0E1A) |
| `ClampedTextScaler` | `core/theme/clamped_text_scaler.dart` | Wrap all text in punishment input |
| `RackUpSpacing` | `core/theme/rackup_spacing.dart` | 8dp grid for layout spacing |

### Design Token Reference

| Token | Value | Context |
|-------|-------|---------|
| Text field font | Barlow 14dp (`RackUpTypography.caption`) | Punishment input |
| Writing status | Amber `#FFB347` | Player row status when typing |
| Ready status | `RackUpColors.madeGreen` `#16A34A` + checkmark icon | Player row status after submit |
| Random button | `RackUpColors.missionPurple` `#A855F7` | Small button beside/below input |
| Focused border | `RackUpColors.itemBlue` `#3B82F6` | Text field focus state |
| Max text length | 140 characters | Client counter + server validation |
| Submitted overlay | Green checkmark, muted text field | Read-only confirmation |
| Min tap target | 56dp | Random button, Submit button |

### WebSocket Message Contracts

**Client → Server: `lobby.player_status_changed`** (sent when player starts typing)
```json
{
  "action": "lobby.player_status_changed",
  "payload": {"status": "writing"}
}
```

**Client → Server: `lobby.punishment_submitted`** (sent when player submits)
```json
{
  "action": "lobby.punishment_submitted",
  "payload": {"text": "Do your best impression of someone here"}
}
```

**Server → All Clients: `lobby.player_status_changed`** (broadcast on status change)
```json
{
  "action": "lobby.player_status_changed",
  "payload": {"deviceIdHash": "sha256...", "status": "writing"}
}
```

Note: When punishment is submitted, server broadcasts `lobby.player_status_changed` with status `"ready"` to ALL connected players including the sender (not a separate `lobby.punishment_submitted` broadcast). The punishment text itself is NOT broadcast to other clients — it stays server-side in the punishment deck (NFR13: visible only within the room, never exposed via API). Broadcasting to all players (including sender) ensures consistency — the client handles its own status change idempotently.

### Server Action Routing Pattern

The server's `room.go` `Run()` loop currently ignores `client_message` actions (line 86: `_ = action`). Story 2.2 must implement the action routing:

```go
case action := <-r.actions:
    switch action.Type {
    case "client_message":
        r.handleClientMessage(action.Player, action.Payload)
    case "internal.check_empty":
        // existing empty-room handling
    }
```

The `handleClientMessage` method parses the JSON payload as a `protocol.Message`, then routes by action string. This is the first story that implements client→server message handling — establish the pattern cleanly for future stories.

### Anti-Patterns to Avoid

- Do NOT create a separate PunishmentBloc — RoomBloc owns lobby-phase state per architecture
- Do NOT broadcast punishment text to other clients — only the status change is broadcast
- Do NOT use `print()` for logging — use `slog` (Go) or let errors propagate naturally (Dart)
- Do NOT use camelCase in JSON — follow existing convention (`deviceIdHash`) for consistency
- Do NOT import from other features — only import from `core/`
- Do NOT hardcode URLs — use `AppConfig`
- Do NOT add nullable fields to sealed Bloc states — each state carries exactly its data
- Do NOT mutate Player objects — use `copyWith()` for immutable updates
- Do NOT send status change on every keystroke — send "writing" status once on first keystroke only
- Do NOT add punishment tier logic — tiers are Epic 4's concern. Lobby punishments are just text strings stored in a flat list.
- Do NOT implement the punishment timeout for game start — that is Story 2.3's concern. This story only adds `punishmentPhaseStartedAt` timestamp as a forward-compatible field.

### Previous Story Intelligence

**From Story 2.1 (Pre-Game Lobby Display):**
- `PlayerStatus` enum was designed as extensible — comments mark exactly where to add `writing` and `ready`
- `mapper.dart` has placeholder comments for the new status mappings
- `actions.dart` has placeholder comments for `lobby.punishment_submitted`
- `lobby_message_listener.dart` has placeholder comment for punishment handling
- `lobby_page.dart` has `// TODO: Story 2.2 — Punishment input` marking exact insertion point
- `player_list_tile.dart` `_statusText()` and `_statusColor()` are exhaustive switches — adding enum values will cause compile errors until updated (Dart 3 sealed pattern, this is intentional)
- BLoC persistence solved: `WebSocketCubit` and `RoomBloc` hoisted to `ShellRoute` (`_RoomShell`) — they persist across navigation. PunishmentInput can directly access both via `context.read<>()`.
- 241 Dart tests + 23 Go tests passing — maintain zero regressions
- `WebSocketCubit.sendMessage()` already exists and works — use it for client→server communication

**From Story 1.8 (Accessibility Audit):**
- All new widgets need `Semantics` wrappers
- All text needs `ClampedTextScaler` with appropriate `TextRole`
- Min 56dp tap targets on buttons
- Reduced motion: respect `MediaQuery.disableAnimations` for any animations (placeholder rotation timer should still cycle — it's not a visual animation)

### Git Intelligence

Recent commits show consistent patterns:
- One commit per story: "Add {feature} with code review fixes (Story X.Y)"
- Tests always included in same commit
- Both Dart and Go changes in same commit
- CI passes: `flutter test` + `flutter analyze`

### Project Structure Notes

New files this story creates:
- `rackup/lib/core/data/punishment_deck.dart` — Built-in punishment deck
- `rackup/lib/features/lobby/view/widgets/punishment_input.dart` — Punishment input widget
- Corresponding test files

Files this story modifies:
- `rackup/lib/core/models/player.dart` — Add enum values + copyWith
- `rackup/lib/core/protocol/actions.dart` — Add action constants
- `rackup/lib/core/protocol/messages.dart` — Add payload classes
- `rackup/lib/core/protocol/mapper.dart` — Add status mappings
- `rackup/lib/features/lobby/bloc/room_bloc.dart` — Add event handlers
- `rackup/lib/features/lobby/bloc/room_event.dart` — Add events
- `rackup/lib/features/lobby/view/lobby_page.dart` — Add PunishmentInput widget
- `rackup/lib/features/lobby/view/widgets/player_list_tile.dart` — Update status switches
- `rackup/lib/core/websocket/lobby_message_listener.dart` — Add status change handling
- `rackup-server/internal/protocol/actions.go` — Add action constants
- `rackup-server/internal/protocol/messages.go` — Add payload structs
- `rackup-server/internal/room/room.go` — Add punishment storage, status tracking, client message routing

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic-2, Story 2.2]
- [Source: _bmad-output/planning-artifacts/architecture.md#RoomBloc-Scope]
- [Source: _bmad-output/planning-artifacts/architecture.md#WebSocket-Message-Protocol]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Punishment-Input]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Lobby-Player-Row]
- [Source: _bmad-output/planning-artifacts/prd.md#FR8-Punishment-Submission]
- [Source: _bmad-output/planning-artifacts/prd.md#FR10-Pre-game-lobby]
- [Source: _bmad-output/planning-artifacts/prd.md#NFR13-Privacy]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

No debug issues encountered.

### Completion Notes List

- ✅ Task 1: Extended `PlayerStatus` enum with `writing` and `ready` values. Added `copyWith()` to Player. Updated mapper and PlayerListTile status switches with correct colors (amber #FFB347 for writing, madeGreen for ready) and checkmark icon for ready state.
- ✅ Task 2: Added protocol layer — Dart `Actions` constants, `PunishmentSubmitPayload` and `PlayerStatusChangedPayload` classes, Go `actions.go` and `messages.go` structs.
- ✅ Task 3: Extended server Room with `punishments`, `playerStatuses`, and `punishmentPhaseStartedAt` fields. Implemented `handleClientMessage` routing for punishment submission and status changes. Added 140-char server-side validation with `PUNISHMENT_TOO_LONG` error. Added `AllPunishmentsSubmitted()` method. Updated `buildRoomStateLocked()` and `broadcastPlayerJoinedToOthersLocked` to use `playerStatuses`.
- ✅ Task 4: Added `PlayerStatusChanged` and `PunishmentSubmitted` events to RoomBloc. `_onPlayerStatusChanged` updates player status via `copyWith()`. `_onPunishmentSubmitted` sends via WebSocket. Updated `LobbyMessageListener` to handle `lobby.player_status_changed`.
- ✅ Task 5: Created `punishment_deck.dart` with 30 bar-appropriate punishments and `randomPunishment()` function.
- ✅ Task 6: Created `PunishmentInput` widget with all states (Empty/Focused/Filled/Submitted), rotating placeholder (3s interval), Random button (purple accent), Submit button, 140-char counter, accessibility semantics, 56dp min tap targets.
- ✅ Task 7: Integrated `PunishmentInput` into `LobbyPage` below the player list. Sends "writing" status on first keystroke (once only).
- ✅ Task 8: WebSocket message sending implemented in RoomBloc (`_onPunishmentSubmitted`) and PunishmentInput (`_onTextChanged` for status).
- ✅ Task 9: 28 new Dart tests (269 total, up from 241) + 5 new Go tests (28 total, up from 23). Zero regressions.

### Change Log

- 2026-03-28: Implemented Story 2.2 — Punishment Submission. All 9 tasks complete.

### File List

**New files:**
- `rackup/lib/core/data/punishment_deck.dart`
- `rackup/lib/features/lobby/view/widgets/punishment_input.dart`
- `rackup/test/core/data/punishment_deck_test.dart`
- `rackup/test/features/lobby/view/widgets/punishment_input_test.dart`

**Modified files:**
- `rackup/lib/core/models/player.dart`
- `rackup/lib/core/protocol/actions.dart`
- `rackup/lib/core/protocol/messages.dart`
- `rackup/lib/core/protocol/mapper.dart`
- `rackup/lib/features/lobby/bloc/room_bloc.dart`
- `rackup/lib/features/lobby/bloc/room_event.dart`
- `rackup/lib/features/lobby/view/lobby_page.dart`
- `rackup/lib/features/lobby/view/widgets/player_list_tile.dart`
- `rackup/lib/core/websocket/lobby_message_listener.dart`
- `rackup-server/internal/protocol/actions.go`
- `rackup-server/internal/protocol/messages.go`
- `rackup-server/internal/room/room.go`
- `rackup/test/core/models/player_test.dart`
- `rackup/test/core/protocol/mapper_test.dart`
- `rackup/test/features/lobby/bloc/room_bloc_test.dart`
- `rackup/test/core/websocket/lobby_message_listener_test.dart`
- `rackup/test/features/lobby/view/widgets/player_list_tile_test.dart`
- `rackup/test/features/lobby/view/lobby_page_test.dart`
- `rackup-server/internal/room/room_test.go`
