# Story 2.3: Game Configuration & Start

Status: done

## Story

As a host,
I want to configure the number of rounds and start the game when everyone is ready,
So that I control the game length and launch timing.

## Acceptance Criteria

1. **Given** the host is in the pre-game lobby **When** the configuration area renders **Then** a round count selector is displayed with options 5, 10, and 15 (default 10) **And** the slide-to-start component is visible at the bottom of the screen.

2. **Given** not all players have submitted punishments and the timeout has not elapsed **When** the host views the slide-to-start **Then** the component is disabled (30% opacity) and cannot be activated.

3. **Given** all players have submitted punishments OR the configurable timeout has elapsed **When** the host views the slide-to-start **Then** the component becomes active with a shimmer animation along the track **And** the rounded track (52dp height) shows a circular thumb (44dp, green gradient with play arrow) **And** track text reads "SLIDE TO START GAME" (Oswald SemiBold 14dp, muted).

4. **Given** the host slides the thumb past the 70% threshold **When** the threshold is crossed **Then** the game starts with haptic feedback **And** the server receives a `lobby.start_game` message with the configured round count **And** all players are transitioned from lobby to the game state.

5. **Given** the host slides the thumb but releases before the 70% threshold **When** the thumb is released **Then** the thumb snaps back to the starting position **And** the game does NOT start.

6. **Given** accessibility requirements **When** a user cannot perform the slide gesture **Then** a 3-second long-press hold alternative triggers the game start.

7. **Given** the host is NOT the current player **When** a non-host player views the lobby **Then** the slide-to-start component is not visible **And** a waiting indicator shows "Waiting for host to start..."

## Tasks / Subtasks

- [x] Task 1: Protocol layer — add game start actions and payloads (AC: #4)
  - [x] 1.1 Add `lobbyStartGame` constant in `actions.dart` — client→server action (`"lobby.start_game"`)
  - [x] 1.2 Add `lobbyGameStarted` constant in `actions.dart` — server→client broadcast (`"lobby.game_started"`). Replace the existing TODO comment on line 20
  - [x] 1.3 Add corresponding `ActionLobbyStartGame` / `ActionLobbyGameStarted` in Go `actions.go`
  - [x] 1.4 Add `StartGamePayload` class in `messages.dart` — client→server: `roundCount: int`, with `toJson()` method
  - [x] 1.5 Add `GameStartedPayload` class in `messages.dart` — server→client: `roundCount: int`, with `fromJson()` factory
  - [x] 1.6 Add Go `StartGamePayload` struct (`RoundCount int json:"roundCount"`) and `GameStartedPayload` struct in `messages.go`

- [x] Task 2: Server game start logic (AC: #2, #4)
  - [x] 2.1 Add `roundCount int` and `gameStarted bool` fields to Room struct in `room.go`
  - [x] 2.2 Define `PunishmentTimeout = 120 * time.Second` constant in `room.go`
  - [x] 2.3 Add `protocol.ActionLobbyStartGame` case in `handleClientMessage()` switch
  - [x] 2.4 Validate: only host can start — compare `deviceHash == r.hostDeviceHash`. Reject with error code `"NOT_HOST"`
  - [x] 2.5 Validate: `len(r.players) >= 2` — minimum 2 players required (FR7). Reject with error code `"NOT_ENOUGH_PLAYERS"`
  - [x] 2.6 Validate: round count is 5, 10, or 15 — reject with error code `"INVALID_ROUND_COUNT"`
  - [x] 2.7 Validate: `AllPunishmentsSubmitted()` returns true OR `time.Since(r.punishmentPhaseStartedAt) >= PunishmentTimeout`. Reject with `"PUNISHMENTS_PENDING"`
  - [x] 2.8 Validate: `!r.gameStarted` — prevent double-start. Reject with `"GAME_ALREADY_STARTED"`
  - [x] 2.9 On valid start: set `r.roundCount`, set `r.gameStarted = true`, broadcast `lobby.game_started` with `GameStartedPayload{RoundCount}` to all players

- [x] Task 3: Pass host identity through to RoomLobby state (AC: #1, #7)
  - [x] 3.1 Add `hostDeviceIdHash: String` field to `RoomStateReceived` event in `room_event.dart` — **currently missing**: `LobbyMessageListener` parses `hostDeviceIdHash` from `LobbyRoomStatePayload` but doesn't pass it to the event
  - [x] 3.2 Add `hostDeviceIdHash: String` field to `RoomLobby` state in `room_state.dart` (add to `props`)
  - [x] 3.3 Update `_onRoomStateReceived` in `room_bloc.dart` to pass `hostDeviceIdHash` into `RoomLobby`
  - [x] 3.4 Update `LobbyMessageListener` to pass `payload.hostDeviceIdHash` when creating `RoomStateReceived` event
  - [x] 3.5 Update all existing `_onPlayerJoined`, `_onPlayerLeft`, `_onPlayerStatusChanged` handlers to preserve `hostDeviceIdHash` when emitting new `RoomLobby` states

- [x] Task 4: Extend RoomBloc with game start events (AC: #1, #2, #3)
  - [x] 4.1 Add `allPunishmentsReady` computed getter on `RoomLobby`: `players.every((p) => p.status == PlayerStatus.ready)`
  - [x] 4.2 Add `StartGameRequested` event with `roundCount: int` (imperative — user action)
  - [x] 4.3 Add `GameStarted` event with `roundCount: int` (past tense — server event)
  - [x] 4.4 Add `RoomStarting` state with `roundCount: int` in `room_state.dart`
  - [x] 4.5 Add handler `_onStartGameRequested`: send `Message(action: Actions.lobbyStartGame, payload: StartGamePayload(roundCount).toJson())` via `_webSocketCubit.sendMessage()`
  - [x] 4.6 Add handler `_onGameStarted`: emit `RoomStarting(roundCount: event.roundCount)`

- [x] Task 5: Extend LobbyMessageListener (AC: #4)
  - [x] 5.1 Add case for `Actions.lobbyGameStarted` in `_handleMessage` switch
  - [x] 5.2 Parse `GameStartedPayload.fromJson(message.payload)`
  - [x] 5.3 Dispatch `GameStarted(roundCount: payload.roundCount)` to RoomBloc

- [x] Task 6: Server timeout broadcast (AC: #2, #3)
  - [x] 6.1 Add `allReadyOrTimedOut: bool` field to `LobbyRoomStatePayload` in Go `messages.go` — server computes this as `AllPunishmentsSubmitted() || time.Since(punishmentPhaseStartedAt) >= PunishmentTimeout`
  - [x] 6.2 Update `buildRoomStateLocked()` in `room.go` to include `allReadyOrTimedOut`
  - [x] 6.3 Add `allReadyOrTimedOut: bool` field to Dart `LobbyRoomStatePayload` in `messages.dart`
  - [x] 6.4 Add `allReadyOrTimedOut: bool` field to `RoomLobby` state, pass through from `RoomStateReceived`
  - [x] 6.5 Update `LobbyMessageListener` to pass `payload.allReadyOrTimedOut` into `RoomStateReceived`
  - [x] 6.6 When timeout elapses server-side, broadcast a fresh `lobby.room_state` so clients get updated `allReadyOrTimedOut: true` — add a timer check in the room goroutine's `reconnectTicker` handler (runs every 5s): if `!r.gameStarted && time.Since(r.punishmentPhaseStartedAt) >= PunishmentTimeout`, broadcast room state once and set a `timeoutBroadcast` flag to avoid repeat

- [x] Task 7: Round Count Selector widget (AC: #1)
  - [x] 7.1 Create `round_count_selector.dart` in `features/lobby/view/widgets/`
  - [x] 7.2 Three toggle buttons: 5, 10, 15 — default 10 selected
  - [x] 7.3 Style: Oswald SemiBold text, use `RackUpColors` for selected/unselected states
  - [x] 7.4 Expose `onChanged(int roundCount)` callback and `selectedRoundCount` param
  - [x] 7.5 Add `Semantics` labels for each option (e.g., "5 rounds", "10 rounds selected")
  - [x] 7.6 Only visible to host — non-host sees nothing here

- [x] Task 8: Slide-to-Start widget (AC: #1, #2, #3, #4, #5, #6)
  - [x] 8.1 Create `slide_to_start.dart` in `features/lobby/view/widgets/`
  - [x] 8.2 Disabled state: 30% opacity, non-interactive, track (52dp height rounded), thumb (44dp circular), text "SLIDE TO START GAME" (Oswald SemiBold 14dp, `RackUpColors.textSecondary`)
  - [x] 8.3 Active state: full opacity, shimmer animation along track (respect `MediaQuery.disableAnimations`), green gradient thumb (`RackUpColors.madeGreen`) with `Icons.play_arrow`
  - [x] 8.4 Drag interaction: `GestureDetector` with horizontal drag, track thumb position as fraction 0.0–1.0, green fill behind thumb
  - [x] 8.5 Threshold logic: >= 0.7 triggers `onStart()` callback + `HapticFeedback.mediumImpact()`
  - [x] 8.6 Snap-back: if released below 0.7, animate thumb back to 0.0 with spring animation
  - [x] 8.7 Accessibility: 3-second `GestureDetector.onLongPress` alternative — use timer to verify 3s hold duration before triggering
  - [x] 8.8 Expose: `enabled: bool`, `onStart: VoidCallback`

- [x] Task 9: Lobby Page integration (AC: #1, #7)
  - [x] 9.1 Replace TODO comment (`// TODO: Story 2.3 — Slide-to-start` at line ~119) in `lobby_page.dart` with game config section
  - [x] 9.2 Determine if current user is host: inject `DeviceIdentityService` into `LobbyPage` (via `context.read<DeviceIdentityService>()`), compare `deviceIdentityService.getHashedDeviceId()` against `state.hostDeviceIdHash`
  - [x] 9.3 Host view: `RoundCountSelector` + `SlideToStart` at bottom of lobby, below `PunishmentInput`
  - [x] 9.4 Non-host view: "Waiting for host to start..." text (Barlow 14dp, `RackUpColors.textSecondary`) with subtle pulse animation (respect `MediaQuery.disableAnimations`)
  - [x] 9.5 Enable `SlideToStart` when `state.allReadyOrTimedOut || state.allPunishmentsReady`
  - [x] 9.6 Track selected round count in local `_LobbyPageState` (default 10)
  - [x] 9.7 On slide trigger: dispatch `StartGameRequested(roundCount: _selectedRoundCount)` to RoomBloc
  - [x] 9.8 Add `BlocListener<RoomBloc, RoomState>` for `RoomStarting` state — navigate to a placeholder game route. The actual game screen is Epic 3; for now navigate to a simple "Game starting..." screen or use `context.go('/game')` which can be a stub route in `app_router.dart`

- [x] Task 10: Comprehensive tests (all AC)
  - [x] 10.1 Widget test: `RoundCountSelector` — default selection is 10, tap changes selection, callbacks fire (3 tests)
  - [x] 10.2 Widget test: `SlideToStart` — disabled rendering at 30% opacity, active rendering with shimmer, threshold trigger fires callback, snap-back below threshold, long-press a11y triggers after 3s (5 tests)
  - [x] 10.3 Bloc test: `StartGameRequested` → calls `webSocketCubit.sendMessage()` with correct action and payload (1 test)
  - [x] 10.4 Bloc test: `GameStarted` → emits `RoomStarting(roundCount)` (1 test)
  - [x] 10.5 Widget test: `LobbyPage` host view shows round selector + slide-to-start (1 test)
  - [x] 10.6 Widget test: `LobbyPage` non-host view shows "Waiting for host to start..." (1 test)
  - [x] 10.7 Listener test: `lobbyGameStarted` message dispatches `GameStarted` event (1 test)
  - [x] 10.8 Go test: only host can start game — non-host gets `NOT_HOST` error (1 test)
  - [x] 10.9 Go test: cannot start with fewer than 2 players — gets `NOT_ENOUGH_PLAYERS` error (1 test)
  - [x] 10.10 Go test: cannot start before punishments ready and timeout not elapsed — gets `PUNISHMENTS_PENDING` error (1 test)
  - [x] 10.11 Go test: can start when all punishments submitted (1 test)
  - [x] 10.12 Go test: can start when timeout elapsed even if punishments missing (1 test)
  - [x] 10.13 Go test: roundCount validation — rejects values other than 5/10/15 (1 test)
  - [x] 10.14 Go test: broadcasts `lobby.game_started` to all connected players (1 test)
  - [x] 10.15 Go test: double-start returns `GAME_ALREADY_STARTED` error (1 test)

## Dev Notes

### Architecture Compliance

- **Server-authoritative**: Server validates all game start conditions (host check, player count, punishment readiness, round count). Client shows enabled/disabled UI based on server-provided `allReadyOrTimedOut` flag, but server rejects invalid requests with typed error codes.
- **RoomBloc scope**: RoomBloc manages the entire lobby phase including game config and start. No separate bloc needed — follows Stories 2.1/2.2 pattern.
- **Protocol separation**: Wire types in `core/protocol/`, domain models in bloc states. `WebSocketCubit` dispatches via `LobbyMessageListener`, never directly to UI.
- **Dual-action pattern**: `lobby.start_game` (client→server, imperative) and `lobby.game_started` (server→client broadcast, past tense). These are two distinct actions — the server receives the request, validates, then broadcasts the result.

### Existing Code Awareness — DO NOT DUPLICATE

These already exist and must NOT be re-created:
- `LobbyRoomStatePayload.hostDeviceIdHash` — already in both Dart `messages.dart` and Go `messages.go`
- `buildRoomStateLocked()` already populates `hostDeviceIdHash` in `room.go`
- `Player.isHost` field — already on the domain model in `player.dart`
- `LobbyPlayerPayload.isHost` — already on the wire type

What IS missing (must be added):
- `hostDeviceIdHash` is parsed in `LobbyMessageListener` but **dropped** — `RoomStateReceived` event doesn't carry it, and `RoomLobby` state doesn't store it. Task 3 fixes this pipeline gap.

### Implementation Patterns from Previous Stories

- **Player model immutability**: Use `copyWith()` for updates. RoomBloc emits new `RoomLobby` with reconstructed player list.
- **Message sending**: `_webSocketCubit.sendMessage(Message(action: Actions.lobbyStartGame, payload: StartGamePayload(roundCount: n).toJson()))`. The `sendMessage()` method internally checks `state is WebSocketConnected` before sending.
- **LobbyMessageListener**: Static `_handleMessage(Message, RoomBloc)` with switch on `message.action`. Parse payload in try-catch, silently drop malformed payloads.
- **Widget accessibility**: `Semantics(button: true, label: ...)` on all interactives. `ClampedTextScaler.of(context, TextRole.body)` for text. `MediaQuery.disableAnimations` before any animation.
- **Test factories**: `createTestRoomBloc()` from `test/helpers/factories.dart` (Dart). `testutil.NewTestRoom(code, hostHash)` from `internal/testutil/factories.go` (Go). Use `_MockWebSocketCubit`, `_MockDeviceIdentityService`, `_MockRoomApiService` from factories.
- **Bloc testing**: `blocTest<RoomBloc, RoomState>()` with `build`, `act`, `expect`, `verify` from `bloc_test` + `mocktail`.

### Key Design Decisions

- **Punishment timeout = 120 seconds**: Server tracks via `punishmentPhaseStartedAt` (set at room creation in `NewRoom()`). Server computes `allReadyOrTimedOut` flag and includes it in `lobby.room_state` payloads. When timeout elapses, server re-broadcasts room state so clients get the updated flag without polling.
- **Host identification on client**: `RoomLobby.hostDeviceIdHash` compared to `DeviceIdentityService.getHashedDeviceId()`. Access `DeviceIdentityService` in lobby page via `context.read<DeviceIdentityService>()`.
- **Round count is host-only local state until start**: No real-time broadcast of round count selection. Server receives the chosen value only in `lobby.start_game` message payload.
- **Minimum 2 players**: Server enforces `len(r.players) >= 2` on start. No client-side guard needed — server returns error.
- **Slide-to-start is deliberate UX**: 70% threshold + snap-back prevents accidental launches. Long-press 3s fallback for accessibility.
- **Game screen navigation placeholder**: Story 2.3 emits `RoomStarting(roundCount)` state. The actual game screen is Epic 3 (Story 3.1). For now, add a stub route (`/game`) in `app_router.dart` that shows "Game starting..." text. Story 3.1 will replace it.

### Project Structure Notes

**New files:**
- `rackup/lib/features/lobby/view/widgets/round_count_selector.dart`
- `rackup/lib/features/lobby/view/widgets/slide_to_start.dart`
- `rackup/test/features/lobby/view/widgets/round_count_selector_test.dart`
- `rackup/test/features/lobby/view/widgets/slide_to_start_test.dart`

**Modified files:**
- `rackup/lib/core/protocol/actions.dart` — add `lobbyStartGame`, `lobbyGameStarted` (replace TODO comment)
- `rackup/lib/core/protocol/messages.dart` — add `StartGamePayload`, `GameStartedPayload`, add `allReadyOrTimedOut` to `LobbyRoomStatePayload`
- `rackup/lib/features/lobby/bloc/room_event.dart` — add `StartGameRequested`, `GameStarted`; extend `RoomStateReceived` with `hostDeviceIdHash` and `allReadyOrTimedOut`
- `rackup/lib/features/lobby/bloc/room_state.dart` — add `hostDeviceIdHash`, `allReadyOrTimedOut` to `RoomLobby`; add `RoomStarting` state
- `rackup/lib/features/lobby/bloc/room_bloc.dart` — add handlers; update all existing handlers that emit `RoomLobby` to preserve `hostDeviceIdHash` and `allReadyOrTimedOut`
- `rackup/lib/features/lobby/view/lobby_page.dart` — replace TODO, integrate config UI, add `BlocListener`
- `rackup/lib/core/websocket/lobby_message_listener.dart` — pass `hostDeviceIdHash`/`allReadyOrTimedOut` to `RoomStateReceived`; add `lobbyGameStarted` case
- `rackup-server/internal/protocol/actions.go` — add `ActionLobbyStartGame`, `ActionLobbyGameStarted`
- `rackup-server/internal/protocol/messages.go` — add payloads; add `AllReadyOrTimedOut` to `LobbyRoomStatePayload`
- `rackup-server/internal/room/room.go` — add game start handler, timeout broadcast, validation, `PunishmentTimeout` constant

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 2, Story 2.3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Message Protocol, RoomBloc Scope, Naming Patterns, Structure Patterns]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Slide-to-Start Component, Round Count Selector, Host Lobby, Lobby Player Row]
- [Source: _bmad-output/planning-artifacts/prd.md — FR5, FR7, FR8, FR9, FR10]
- [Source: _bmad-output/implementation-artifacts/2-2-punishment-submission.md — Dev Notes, File List, Completion Notes]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

None — clean implementation, no blocking issues.

### Completion Notes List

- Task 1: Added `lobbyStartGame`/`lobbyGameStarted` actions in Dart and Go, `StartGamePayload`/`GameStartedPayload` in both languages.
- Task 2: Server game start handler with 5 validations (host-only, ≥2 players, valid round count, punishments ready/timeout, no double-start). Each returns typed error code.
- Task 3: Piped `hostDeviceIdHash` through `RoomStateReceived` event → `RoomLobby` state. Updated all existing handlers to preserve the field.
- Task 4: Added `allPunishmentsReady` getter, `StartGameRequested`/`GameStarted` events, `RoomStarting` state, and corresponding bloc handlers.
- Task 5: Extended `LobbyMessageListener` with `lobbyGameStarted` case dispatching `GameStarted` event.
- Task 6: Added `allReadyOrTimedOut` to `LobbyRoomStatePayload` (both Dart/Go), server computes from punishments + timeout. Added `checkPunishmentTimeout()` in reconnect ticker for auto-broadcast.
- Task 7: Created `RoundCountSelector` widget with 5/10/15 toggle, Oswald font, semantic labels.
- Task 8: Created `SlideToStart` widget with 70% drag threshold, 30% disabled opacity, shimmer, haptic feedback, 3s long-press a11y fallback.
- Task 9: Integrated into `LobbyPage` — host sees config section, non-host sees pulsing "Waiting for host to start..." text. Added `BlocListener` for `RoomStarting` → `/game` navigation. Added stub `/game` route.
- Task 10: 8 Go server tests (all validation paths), 3 round count selector tests, 5 slide-to-start tests, 2 new bloc tests. Updated all existing tests for new required fields. Full suite: 280 Dart tests + all Go tests pass.

### Change Log

- 2026-04-01: Story 2.3 implementation complete — game configuration & start

### File List

**New files:**
- rackup/lib/features/lobby/view/widgets/round_count_selector.dart
- rackup/lib/features/lobby/view/widgets/slide_to_start.dart
- rackup/test/features/lobby/view/widgets/round_count_selector_test.dart
- rackup/test/features/lobby/view/widgets/slide_to_start_test.dart

**Modified files:**
- rackup/lib/core/protocol/actions.dart
- rackup/lib/core/protocol/messages.dart
- rackup/lib/features/lobby/bloc/room_event.dart
- rackup/lib/features/lobby/bloc/room_state.dart
- rackup/lib/features/lobby/bloc/room_bloc.dart
- rackup/lib/features/lobby/view/lobby_page.dart
- rackup/lib/core/websocket/lobby_message_listener.dart
- rackup/lib/core/routing/app_router.dart
- rackup/lib/features/lobby/view/create_room_page.dart
- rackup/lib/features/lobby/view/join_room_page.dart
- rackup-server/internal/protocol/actions.go
- rackup-server/internal/protocol/messages.go
- rackup-server/internal/room/room.go
- rackup-server/internal/room/room_test.go
- rackup/test/features/lobby/bloc/room_bloc_test.dart
- rackup/test/features/lobby/view/lobby_page_test.dart
- rackup/test/features/lobby/view/widgets/punishment_input_test.dart
- rackup/test/features/accessibility_test.dart
