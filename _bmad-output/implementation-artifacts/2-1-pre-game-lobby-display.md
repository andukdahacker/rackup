# Story 2.1: Pre-Game Lobby Display

Status: review

## Story

As a player,
I want to see who's in the room and their status while waiting for the game to start,
So that I know when everyone is ready.

## Acceptance Criteria

1. **Given** a player has joined a room via code or deep link, **When** the lobby screen renders, **Then** the room code is displayed prominently (Oswald 36dp, gold, letter-spaced), a large "Share Invite Link" button is the primary action, and a player list shows all connected players with Lobby Player Row components.

2. **Given** a player is in the lobby, **When** they view the player list, **Then** each player row shows: color+shape identity tag (20dp), Oswald SemiBold player name, status indicator, and the host has a gold "HOST" badge next to their name.

3. **Given** a new player joins the room, **When** the server broadcasts the `lobby.player_joined` event via WebSocket, **Then** the new player's row slides in with a 300ms stagger animation and all connected players see the updated player list in real time.

4. **Given** a player is in the lobby, **When** they view the player list, **Then** each player's row shows their current status: "Joining..." (muted). (Note: "Writing..." and "Ready" statuses will be added by Story 2.2 when punishment submission is implemented.)

5. **Given** the lobby is displayed, **When** the screen renders, **Then** the layout is portrait-locked with dark base canvas (#0F0E1A) and follows the bottom-weighted interaction pattern (info top, actions bottom).

6. **Given** a player disconnects, **When** the server broadcasts `lobby.player_left`, **Then** the player is removed from the lobby list for all remaining players.

7. **Given** a player reconnects within 60 seconds, **When** the server re-broadcasts `lobby.player_joined`, **Then** the player reappears in the list (visually indistinguishable from an initial join).

## Tasks / Subtasks

- [x] Task 1: Create Player domain model (AC: #2, #4)
  - [x] Create `rackup/lib/core/models/player.dart` with `Player` class: `displayName`, `deviceIdHash`, `slot` (int), `isHost` (bool), `status` (PlayerStatus enum). Class must be immutable and extend Equatable.
  - [x] Create `PlayerStatus` enum with `joining` value only. Mark as extensible for Story 2.2 which will add `writing` and `ready` statuses when punishment submission is implemented.
  - [x] Add `PlayerIdentity` linkage via slot index (reuse existing `player_identity.dart`)

- [x] Task 2: Extend protocol layer for lobby messages (AC: #3, #6)
  - [x] **Dart** `actions.dart`: Add constants `lobbyPlayerLeft`, `lobbyRoomState`. Forward-declare `lobbyPunishmentSubmitted` (Story 2.2) and `lobbyGameStarted` (Story 2.3) with comments noting no handler in 2.1.
  - [x] **Dart** `messages.dart`: Add `LobbyPlayerPayload` (displayName, deviceIdHash, slot, isHost, status), `LobbyRoomStatePayload` (list of players, roomCode, hostDeviceIdHash)
  - [x] **Go** `actions.go`: Add `ActionLobbyPlayerLeft`, `ActionLobbyRoomState`
  - [x] **Go** `messages.go`: Add `LobbyPlayerPayload` and `LobbyRoomStatePayload` structs
  - [x] **Dart** `mapper.dart`: Implement `mapToPlayer()` converting `LobbyPlayerPayload` to `Player` domain model

- [x] Task 3: Extend server room management for full lobby state (AC: #3, #6, #7)
  - [x] `room.go`: Add slot assignment (1-8) when player joins. Maintain a separate `slotAssignments map[string]int` in Room struct that persists even when a player disconnects, so reconnecting players retain their original slot.
  - [x] `room.go`: On new player join, broadcast `lobby.player_joined` with full player payload including slot
  - [x] `room.go`: On player disconnect, broadcast `lobby.player_left` with deviceIdHash
  - [x] `room.go`: Add `GetRoomState()` method returning all current players with slots, statuses, host info
  - [x] `websocket.go`: After WebSocket upgrade and room join, send `lobby.room_state` message with full room snapshot to the newly connected player
  - [x] Add tests for slot assignment, room state broadcast, and player_left broadcast

- [x] Task 4: Extend RoomBloc for lobby state management (AC: #1, #2, #3, #6)
  - [x] Add `RoomLobby` state to `room_state.dart`: carries `List<Player>`, `roomCode`, `jwt`. All fields non-nullable.
  - [x] Add events to `room_event.dart`: `PlayerJoined(Player)`, `PlayerLeft(String deviceIdHash)`, `RoomStateReceived(List<Player>, String roomCode)`. Note: `PlayerStatusChanged` event deferred to Story 2.2.
  - [x] In `room_bloc.dart`: after successful create/join, transition to `RoomLobby` state when `lobby.room_state` is received from WebSocket
  - [x] Handle `PlayerJoined` — add player to list (immutable copy), emit updated `RoomLobby`
  - [x] Handle `PlayerLeft` — remove player from list (immutable copy), emit updated `RoomLobby`

- [x] Task 5: Implement WebSocket message routing to RoomBloc (AC: #3, #6)
  - [x] **Architecture decision**: Chose Option A (stream-based). Added `Stream<Message> messages` to `WebSocketCubit`, created `LobbyMessageListener` class that subscribes and dispatches events to RoomBloc.
  - [x] Implement message parsing by action string for: `lobby.room_state`, `lobby.player_joined`, `lobby.player_left`
  - [x] For `lobby.room_state`: deserialize to `LobbyRoomStatePayload`, map to domain models via `mapper.dart`, dispatch `RoomStateReceived` to RoomBloc
  - [x] For `lobby.player_joined`: deserialize to `LobbyPlayerPayload`, map to `Player`, dispatch `PlayerJoined` to RoomBloc
  - [x] For `lobby.player_left`: extract deviceIdHash, dispatch `PlayerLeft` to RoomBloc
  - [x] Note: `lobby.punishment_submitted` handling deferred to Story 2.2

- [x] Task 6: Create lobby_page.dart (AC: #1, #2, #4, #5)
  - [x] Create `rackup/lib/features/lobby/view/lobby_page.dart`
  - [x] Layout: portrait-locked, dark canvas (#0F0E1A), lobby tier background (#1A1832)
  - [x] Top section: Room code display (reuse existing `RoomCodeDisplay` widget), "Share Invite Link" button (primary, full-width)
  - [x] Middle section: Scrollable player list using `BlocBuilder<RoomBloc, RoomState>` listening to `RoomLobby` state
  - [x] Bottom section: Placeholder area for future punishment input (Story 2.2) and slide-to-start (Story 2.3). Add explicit `// TODO: Story 2.2 — Punishment input` and `// TODO: Story 2.3 — Slide-to-start` comments.
  - [x] Add Semantics wrappers for all interactive elements (continue accessibility patterns from Story 1.8)
  - [x] Respect `RackUpGameTheme` for escalation-tier-aware rendering (lobby tier). Lobby tier particle count = 0 (no ambient particles) — ensure particle system is not initialized during lobby phase.
  - [x] Wrap text in `ClampedTextScaler` with appropriate `TextRole` assignments

- [x] Task 7: Create player_list_tile.dart (AC: #2, #3, #4)
  - [x] Create `rackup/lib/features/lobby/view/widgets/player_list_tile.dart`
  - [x] Anatomy: `PlayerShapeWidget` (20dp, reuse existing) + player name (Oswald SemiBold 20dp — use custom `TextStyle` with `RackUpTypography.oswald` at SemiBold/600 weight, NOT the `bodyLg` token which is Barlow) + optional gold "HOST" badge (10dp) + status indicator (right-aligned)
  - [x] Status states for 2.1: "Joining..." (muted lavender, use `RackUpColors.textSecondary` `#8B85A1`). Story 2.2 will add "Writing..." (amber) and "Ready" (green checkmark) states.
  - [x] Slide-in animation on entry: 300ms, from left — respect `MediaQuery.disableAnimations` for reduced motion
  - [x] Use `AnimatedList` or `AnimatedSwitcher` for staggered arrival animation
  - [x] Add Semantics label: "{name}, {status}" (e.g., "Danny, Ready")

- [x] Task 8: Update routing to navigate to lobby after room create/join (AC: #1)
  - [x] **Critical: Fix BLoC persistence across routes.** Hoisted `WebSocketCubit` and `RoomBloc` to a `ShellRoute` (`_RoomShell`) so they persist across `/create` → `/lobby` and `/join` → `/lobby` transitions.
  - [x] Add `/lobby` route in `app_router.dart` pointing to `LobbyPage`. Use `BlocProvider.value()` to pass existing BLoC instances — do NOT create new instances.
  - [x] After successful room creation (`RoomCreatedState`), navigate to `/lobby` via BlocListener
  - [x] After successful room join, navigate to `/lobby` via BlocListener

- [x] Task 9: Implement share invite link (AC: #1)
  - [x] "Share Invite Link" button generates deep link: `https://rackup.app/join/{CODE}`
  - [x] Use `share_plus` package (already in project from Story 1.5 create_room_page)
  - [x] Button: full-width, primary style, prominent placement above player list

- [x] Task 10: Add comprehensive tests (AC: all)
  - [x] Unit tests for `Player` model and `PlayerStatus` enum (6 tests)
  - [x] Unit tests for protocol mapper (`mapToPlayer`) (5 tests)
  - [x] RoomBloc tests: `PlayerJoined`, `PlayerLeft`, `RoomStateReceived` events (6 tests; PlayerStatusChanged deferred to Story 2.2)
  - [x] Widget tests for `LobbyPage` and `PlayerListTile` (14 tests)
  - [x] Widget tests for animation behavior (reduced motion off = animated, on = instant)
  - [x] Go server tests: slot assignment, room state snapshot, player_left broadcast (4 tests)
  - [x] Target: maintain 100% test pass rate, add ~30+ tests — 37 new Dart + 4 new Go = 41 new tests

## Dev Notes

### Design Priority

The lobby is classified as **Tier 1 — Fully Custom Design** (the screens that ARE the product). This demands highest design fidelity — every animation, spacing token, and visual detail matters. The lobby is where players emotionally invest in the game before it starts.

### Architecture Compliance

- **State management**: Use sealed Bloc states (Dart 3 pattern). `RoomLobby` must carry only relevant data — no nullable fields on god-state. `Player` model must be immutable and extend `Equatable`.
- **Protocol → Model separation**: Wire types in `core/protocol/`, domain models in `core/models/`. Never use protocol types in Bloc states.
- **Feature isolation**: No cross-feature imports except through `core/`. All lobby code stays in `features/lobby/`.
- **Server validation**: Server is authoritative. Client validates for UX only. All player list state comes from server broadcasts.
- **No database in hot path**: Room/player state lives in-memory in room goroutine. No DB calls during lobby phase.
- **Particle system**: Lobby tier = 0 particles (calm anticipation). Do not initialize or render any ambient particles during lobby phase.

### Existing Code to Reuse (DO NOT recreate)

| Component | Location | Usage |
|-----------|----------|-------|
| `RoomCodeDisplay` | `features/lobby/view/widgets/room_code_display.dart` | Room code in lobby header |
| `PlayerShapeWidget` | `core/theme/widgets/player_shape.dart` | Color+shape identity tags in player rows |
| `PlayerIdentity` | `core/theme/player_identity.dart` | `PlayerIdentity.forSlot(slot)` for color+shape lookup |
| `RackUpColors` | `core/theme/rackup_colors.dart` | All color constants including player identity, semantic, canvas |
| `RackUpTypography` | `core/theme/rackup_typography.dart` | Oswald/Barlow type scale tokens |
| `RackUpSpacing` | `core/theme/rackup_spacing.dart` | 8dp grid spacing tokens |
| `ClampedTextScaler` | `core/theme/clamped_text_scaler.dart` | Accessibility text scaling with role-based limits |
| `RackUpGameTheme` | `core/theme/game_theme.dart` | InheritedWidget for tier-aware rendering |
| `WebSocketCubit` | `core/websocket/web_socket_cubit.dart` | WebSocket connection management |
| `ReconnectionHandler` | `core/websocket/reconnection_handler.dart` | Exponential backoff logic |
| `RoomApiService` | `core/services/room_api_service.dart` | HTTP room create/join (already used) |
| `DeviceIdentityService` | `core/services/device_identity_service.dart` | UUID + SHA-256 device ID |
| `share_plus` | Already in pubspec | Native share sheet for invite link |

### Design Token Reference

| Token | Value | Context |
|-------|-------|---------|
| Canvas background | `#0F0E1A` | Scaffold background |
| Lobby tier background | `#1A1832` | Content area background accent |
| Room code | Oswald 36dp, gold `#FFD700`, letter-spaced | Header |
| Player name | Oswald SemiBold (600) 20dp — custom TextStyle, NOT `bodyLg` token | Player row |
| HOST badge | Gold `#FFD700`, 10dp | Next to host name |
| Status: Joining | `RackUpColors.textSecondary` `#8B85A1` | Player row right |
| Status: Writing | Amber `#FFB347` (Story 2.2) | Player row right — deferred |
| Status: Ready | `RackUpColors.madeGreen` `#16A34A` + checkmark (Story 2.2) | Player row right — deferred |
| Identity tag | 20dp color+shape | Player row left |
| Min tap target | 56dp | All interactive elements |
| Screen edge padding | 32dp (space-xl) | Layout margins |
| List item spacing | 16dp (space-md) | Between player rows |

### Accessibility Requirements

- All text: WCAG AA contrast (>= 4.5:1) against `#0F0E1A` — already verified in Story 1.8
- Player identity: redundant color + shape encoding (colorblind safe)
- Minimum text size: 14dp
- `ClampedTextScaler`: body text scales to 2.0x, display to 1.2x, button labels no scaling
- Reduced motion: lobby slide-in animations disabled, players appear immediately — check `MediaQuery.disableAnimations`
- Screen reader: Semantics labels on all player rows, buttons, room code
- Minimum tap target: 56dp on Share button and any interactive elements

### WebSocket Message Contracts

**Server → Client: `lobby.room_state`** (sent once on WebSocket connect)
```json
{
  "action": "lobby.room_state",
  "payload": {
    "roomCode": "ABCD",
    "hostDeviceIdHash": "sha256...",
    "players": [
      {"displayName": "Jake", "deviceIdHash": "sha256...", "slot": 1, "isHost": true, "status": "ready"},
      {"displayName": "Danny", "deviceIdHash": "sha256...", "slot": 2, "isHost": false, "status": "joining"}
    ]
  }
}
```

**Server → Client: `lobby.player_joined`** (broadcast to all on new join)
```json
{
  "action": "lobby.player_joined",
  "payload": {"displayName": "Maya", "deviceIdHash": "sha256...", "slot": 3, "isHost": false, "status": "joining"}
}
```

**Server → Client: `lobby.player_left`** (broadcast to all on disconnect)
```json
{
  "action": "lobby.player_left",
  "payload": {"deviceIdHash": "sha256..."}
}
```

### Anti-Patterns to Avoid

- Do NOT use `print()` for logging — use `slog` (Go) or Sentry (Dart)
- Do NOT use camelCase in JSON fields — use snake_case (`device_id_hash`, not `deviceIdHash`). Note: current codebase uses camelCase in JSON. Follow existing convention (`deviceIdHash`) for consistency until a project-wide migration.
- Do NOT use protocol types directly in Bloc states — always map to domain models
- Do NOT make DB calls during lobby phase — all state is in-memory
- Do NOT import from other features — only import from `core/`
- Do NOT hardcode URLs — use `AppConfig`
- Do NOT scatter audio calls — use centralized `AudioListener` pattern (no audio in this story)
- Do NOT add nullable fields to sealed states — each state carries exactly its data

### Previous Story Intelligence

**From Story 1.8 (Accessibility Audit):**
- Established `ClampedTextScaler` pattern — apply to all new Text widgets
- Established `Semantics` wrapper pattern — apply to all new interactive elements
- 204 tests passing — maintain zero regressions
- Accessibility patterns verified: reduced motion, screen reader, contrast, tap targets

**From Stories 1.5-1.7 (Room Creation & Joining):**
- `RoomBloc` handles create/join but does NOT yet manage lobby state — needs extension
- After room create/join, no navigation to lobby page exists yet — currently stays on create/join success screen
- `WebSocketCubit` connects but does not yet dispatch incoming messages to RoomBloc
- Share functionality already works in `create_room_page.dart` — reuse `share_plus` pattern
- JWT is stored in `RoomCreatedState` / `JoinRoomResponse` — pass to lobby

### Git Intelligence

Recent commits show consistent patterns:
- One commit per story with format: "Add {feature} with code review fixes (Story X.Y)"
- Tests always included in same commit
- Both Dart and Go changes in same commit when story spans both
- CI passes on all PRs (`flutter test` + `flutter analyze`)

### Project Structure Notes

- Flutter client: `rackup/lib/` with feature-based organization
- Go server: `rackup-server/internal/` with domain-based packages
- `core/models/` directory exists but is empty (only `.gitkeep`) — this story creates the first model
- `protocol/mapper.dart` exists as placeholder (1 line) — this story implements it
- Test structure mirrors `lib/` — maintain this pattern

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic-2, Story 2.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#WebSocket-Message-Protocol]
- [Source: _bmad-output/planning-artifacts/architecture.md#Bloc-Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Room-Management]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Lobby-Player-Row]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Escalation-Palette]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Animation-Language]
- [Source: _bmad-output/planning-artifacts/prd.md#FR10-Pre-game-lobby]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- ✅ All 10 tasks completed with TDD (red-green-refactor cycle)
- ✅ 241 Dart tests pass (37 new), 23 Go tests pass (4 new) — zero regressions
- ✅ Architecture decision: chose Option A (stream-based) for WebSocket message routing — `WebSocketCubit` exposes `Stream<Message>`, `LobbyMessageListener` subscribes and dispatches to RoomBloc
- ✅ BLoC persistence fixed: hoisted `WebSocketCubit` and `RoomBloc` to `ShellRoute` (`_RoomShell`) so they survive `/create` → `/lobby` and `/join` → `/lobby` navigation
- ✅ Removed unused `_SuccessView` from `CreateRoomPage` and `JoinRoomPage` since navigation now goes to `/lobby`
- ✅ Updated existing tests (accessibility, create/join page) to reflect new behavior
- ✅ All ACs satisfied: room code display, player list with identity tags, real-time join/leave, status indicators, share invite, portrait layout, dark canvas

### Change Log

- 2026-03-27: Implemented Story 2.1 — Pre-Game Lobby Display (10 tasks, 41 new tests)

### File List

**New Files (Dart):**
- `rackup/lib/core/models/player.dart` — Player domain model with PlayerStatus enum
- `rackup/lib/core/websocket/lobby_message_listener.dart` — WebSocket message routing to RoomBloc
- `rackup/lib/features/lobby/view/lobby_page.dart` — Pre-game lobby screen
- `rackup/lib/features/lobby/view/widgets/player_list_tile.dart` — Player row widget with slide-in animation
- `rackup/test/core/models/player_test.dart` — Player model tests
- `rackup/test/core/protocol/mapper_test.dart` — Protocol mapper tests
- `rackup/test/core/websocket/lobby_message_listener_test.dart` — Message listener tests
- `rackup/test/features/lobby/view/lobby_page_test.dart` — Lobby page widget tests
- `rackup/test/features/lobby/view/widgets/player_list_tile_test.dart` — Player list tile widget tests

**Modified Files (Dart):**
- `rackup/lib/core/protocol/actions.dart` — Added lobbyPlayerLeft, lobbyRoomState constants
- `rackup/lib/core/protocol/messages.dart` — Added LobbyPlayerPayload, LobbyRoomStatePayload
- `rackup/lib/core/protocol/mapper.dart` — Implemented mapToPlayer()
- `rackup/lib/core/websocket/web_socket_cubit.dart` — Added message stream, parse incoming messages
- `rackup/lib/core/routing/app_router.dart` — ShellRoute for BLoC persistence, /lobby route
- `rackup/lib/features/lobby/bloc/room_bloc.dart` — Added lobby event handlers
- `rackup/lib/features/lobby/bloc/room_state.dart` — Added RoomLobby state
- `rackup/lib/features/lobby/bloc/room_event.dart` — Added PlayerJoined, PlayerLeft, RoomStateReceived events
- `rackup/lib/features/lobby/view/create_room_page.dart` — Navigate to /lobby on success, removed _SuccessView
- `rackup/lib/features/lobby/view/join_room_page.dart` — Navigate to /lobby on success, removed _SuccessView
- `rackup/test/features/lobby/bloc/room_bloc_test.dart` — Added lobby event tests
- `rackup/test/features/lobby/view/create_room_page_test.dart` — Updated for navigation behavior
- `rackup/test/features/lobby/view/join_room_page_test.dart` — Updated for navigation behavior
- `rackup/test/features/accessibility_test.dart` — Updated Share Invite Link and text scaling tests for lobby

**Modified Files (Go):**
- `rackup-server/internal/protocol/actions.go` — Added ActionLobbyPlayerLeft, ActionLobbyRoomState
- `rackup-server/internal/protocol/messages.go` — Added LobbyPlayerPayload, LobbyRoomStatePayload structs
- `rackup-server/internal/room/room.go` — Slot assignment, GetRoomState(), player_left broadcast
- `rackup-server/internal/handler/websocket.go` — Send room_state snapshot on connect
- `rackup-server/internal/room/room_test.go` — Added slot, room state, player_left tests
