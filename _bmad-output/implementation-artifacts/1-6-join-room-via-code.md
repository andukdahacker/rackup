# Story 1.6: Join Room via Code

Status: done

## Story

As a player,
I want to enter a room code and display name to join my friend's game,
So that I can participate in the game session.

## Acceptance Criteria

1. **Given** the player taps "Join Room" on the home screen, **When** the join screen renders, **Then** a 4-character code input is displayed (large, auto-uppercase, auto-advance between characters) **And** a display name input field is below the code input **And** a full-width green "Join" button is visible **And** the screen follows the dark base canvas with proper typography and contrast
2. **Given** the player enters a valid room code and display name, **When** they tap "Join", **Then** POST /rooms/:code/join is sent with the hashed device ID and display name **And** the server validates the room exists and is accepting players, returns `{jwt}` **And** a WebSocket connection is established using the JWT **And** the player joins the room within 3 seconds of tapping Join (NFR2) **And** no account, email, phone, or social login is required (NFR11)
3. **Given** the player enters an invalid or expired room code, **When** they tap "Join", **Then** an inline error "Room not found" is displayed below the input field (NFR23) **And** the player can correct and retry without navigating away
4. **Given** the room already has 8 players, **When** a 9th player attempts to join, **Then** the server rejects the join with a clear "Room is full" message

## Tasks / Subtasks

### Server-Side (Go)

- [x] Task 1: Implement JoinRoom HTTP handler (AC: #2, #3, #4)
  - [x] 1.1 Update `internal/handler/http.go` — replace the `JoinRoom` stub (line ~105, currently calls `writeNotImplemented`) with full implementation: extract room code from URL path via `r.PathValue("code")`, parse JSON body `{"deviceIdHash": "...", "displayName": "..."}` using `json.NewDecoder(r.Body)` (same pattern as `CreateRoom`), validate both fields are non-empty, trim displayName whitespace, find room via `h.manager.FindRoom(code)` (returns `*Room` or nil), check capacity via `rm.PlayerCount() < room.MaxPlayers` (both are public — do NOT call `AddPlayer` here since it requires a `*PlayerConn` which only exists at WebSocket upgrade time), issue JWT via `auth.IssueToken(h.jwtSecret, code, deviceIdHash, displayName)`, return `{"jwt": "..."}` with 200 status. Note: the capacity check is best-effort — a race between HTTP and WebSocket connect is possible; the WebSocket handler in `websocket.go` is the authoritative guard (already returns `StatusPolicyViolation` on `ErrRoomFull`).
  - [x] 1.2 Error responses using `writeError()` helper (same as CreateRoom): 400 for missing/empty deviceIdHash or displayName (`protocol.ErrInvalidRequest`), 400 for displayName > 20 chars, 404 for room not found (`protocol.ErrRoomNotFound`), 409 for room full (`protocol.ErrRoomFull`), 500 for internal errors (`protocol.ErrInternal`) — all as `protocol.ErrorPayload` JSON
  - [x] 1.3 Validate display name constraints: non-empty after trim, max 20 characters
  - [x] 1.4 Update `internal/handler/http_test.go` — add tests for JoinRoom following existing test patterns (`httptest.NewRequest` + `httptest.NewRecorder` + `mux.ServeHTTP`): success path (200 + JWT returned), missing body (400), empty displayName (400), room not found (404), room full (409 — create room then fill to 8 players via AddPlayer with mock PlayerConns), display name too long (400). Also update or remove the existing `TestJoinRoom_NotImplemented` test (line ~136) since the stub is replaced.

- [x] Task 2: PlayerConn displayName + join broadcast (AC: #2)
  - [x] 2.1 Add `displayName string` field to `PlayerConn` struct in `internal/room/connection.go` (currently only has `deviceHash`). Update `NewPlayerConn` signature from `NewPlayerConn(conn *websocket.Conn, deviceHash string)` to `NewPlayerConn(conn *websocket.Conn, deviceHash, displayName string)`. Add `DisplayName() string` accessor method. Update `connection_test.go` for new signature.
  - [x] 2.2 Update `internal/handler/websocket.go` line ~56 — change `room.NewPlayerConn(conn, claims.DeviceIDHash)` to `room.NewPlayerConn(conn, claims.DeviceIDHash, claims.DisplayName)` to pass display name from JWT claims.
  - [x] 2.3 Add `lobby.player_joined` broadcast in `internal/room/room.go` `AddPlayer()` method — after successfully adding the player to the map (line ~141, after `slog.Info`), call `r.BroadcastMessage(protocol.Message{Action: protocol.ActionLobbyPlayerJoined, Payload: ...})` with JSON payload containing `{"displayName": conn.DisplayName(), "deviceIdHash": conn.DeviceHash(), "playerCount": len(r.players)}`. This does NOT currently exist — `AddPlayer` only logs, it does not broadcast. The broadcast uses the existing `BroadcastMessage()` method (lines 181-196).
  - [x] 2.4 Update `internal/room/room_test.go` — add test verifying that `AddPlayer` broadcasts `lobby.player_joined` to existing connected players when a new player joins.

### Client-Side (Flutter)

- [x] Task 3: Protocol layer — JoinRoomResponse (AC: #2)
  - [x] 3.1 Add `JoinRoomResponse` class to `lib/core/protocol/messages.dart` — `jwt` field only (unlike `CreateRoomResponse` which has both `roomCode` and `jwt`). Include `fromJson` factory. Add `SYNC WITH:` header comment referencing Go handler.

- [x] Task 4: RoomApiService — joinRoom method (AC: #2, #3, #4)
  - [x] 4.1 Add `joinRoom(String code, String displayName, String deviceIdHash)` method to `lib/core/services/room_api_service.dart` — POST to `${config.apiBaseUrl}/rooms/$code/join` with JSON body `{"deviceIdHash": deviceIdHash, "displayName": displayName}`, parse response into JWT string. Implement single automatic retry on network error (same pattern as `createRoom`). Throw `RoomApiException` on failure with error code from server response.

- [x] Task 5: RoomBloc — JoinRoom event (AC: #2, #3, #4)
  - [x] 5.1 Add `JoinRoom` event to `lib/features/lobby/bloc/room_event.dart` — fields: `code` (String), `displayName` (String)
  - [x] 5.2 Add `RoomJoining` state to `lib/features/lobby/bloc/room_state.dart` (parallel to `RoomCreating`)
  - [x] 5.3 Add `_onJoinRoom` handler in `lib/features/lobby/bloc/room_bloc.dart`: emit `RoomJoining` → get hashed device ID from `DeviceIdentityService` → call `RoomApiService.joinRoom()` → on success emit `RoomCreatedState(roomCode: code, jwt: jwt)` + trigger WebSocket connect via `WebSocketCubit` → on failure emit `RoomError(message)` with user-friendly message mapped from error code (ROOM_NOT_FOUND → "Room not found", ROOM_FULL → "Room is full")

- [x] Task 6: JoinRoomPage UI (AC: #1, #2, #3, #4)
  - [x] 6.1 Create `lib/features/lobby/view/join_room_page.dart` — StatelessWidget with `BlocBuilder<RoomBloc, RoomState>` switching on state (same pattern as `create_room_page.dart`):
    - `RoomInitial` state (default): show form with 4-character room code input + display name input + "Join" button. Code input: 4 separate `TextField` widgets (~48dp wide each, centered character, underlined or boxed), `Oswald` `displaySm` font, `RackUpColors.textPrimary` text. Use `FocusNode` per field for auto-advance on input and auto-backspace on delete. Display name input: single `TextField`, `Barlow` `body` (16dp), hint text "Enter your name", max 20 chars via `maxLength`. "Join" button: full-width green (`RackUpColors.madeGreen`), `primaryButtonHeight` (64dp), same `Material` + `InkWell` pattern as `_PrimaryButton` in `home_page.dart`. Button disabled (visually dimmed, `onTap: null`) until code is exactly 4 characters AND display name is non-empty. On tap: dispatch `JoinRoom(code: code, displayName: displayName)`.
    - `RoomJoining` state: centered `CircularProgressIndicator` with "Joining room..." text below (same layout as `_LoadingView` in `create_room_page.dart`)
    - `RoomCreatedState` state: show "Joined!" heading + `RoomCodeDisplay` widget with room code (reuse existing widget from `widgets/room_code_display.dart`) + "Waiting for game to start..." subtext in `RackUpColors.textSecondary`. Stay on this page — do NOT navigate away (no `/lobby` route exists yet; lobby page is Story 2.1).
    - `RoomError` state: show form again with inline error message between code input and "Join" button. Error text in `RackUpColors.missedRed`, `caption` (14dp). Inputs remain editable with previous values preserved. "Join" button re-enabled for retry.
  - [x] 6.2 Use Material `TextField` for code and name inputs (per UX spec: Material invisible infrastructure is allowed for text input). Style with design system tokens — `RackUpColors.canvas` background, `RackUpColors.textPrimary` text, `RackUpColors.textSecondary` hints. Use `InputDecoration` with `UnderlineInputBorder` or `OutlineInputBorder` styled with `RackUpColors.textSecondary`.
  - [x] 6.3 Room code uppercase enforcement: `TextCapitalization.characters` is only a keyboard hint and does NOT guarantee uppercase on all platforms. You MUST also apply a custom `TextInputFormatter` that converts input to uppercase (e.g., `TextInputFormatter.withFunction((old, new) => new.copyWith(text: new.text.toUpperCase()))`) or call `.toUpperCase()` in the `onChanged` callback before storing. Combined with `FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))` to reject non-alpha characters.

- [x] Task 7: Wire JoinRoomPage in router (AC: #1)
  - [x] 7.1 Replace `/join` placeholder in `lib/core/routing/app_router.dart` with `JoinRoomPage` route, provide `RoomBloc` via `BlocProvider` (same pattern as `/create` route with `CreateRoomPage`)

- [x] Task 8: Testing (all ACs)
  - [x] 8.1 Unit tests for JoinRoom in `RoomBloc` — success flow (emits RoomJoining → RoomCreatedState), API error with ROOM_NOT_FOUND (emits RoomJoining → RoomError), API error with ROOM_FULL (emits RoomJoining → RoomError), network exception (emits RoomJoining → RoomError). Add to existing `test/features/lobby/bloc/room_bloc_test.dart`
  - [x] 8.2 Unit tests for `joinRoom` in `RoomApiService` — success (returns JWT), 404 response, 409 response, non-JSON error. Add to existing `test/core/services/room_api_service_test.dart`
  - [x] 8.3 Widget tests for `JoinRoomPage` — initial state (code input + name input + join button visible), button disabled when fields empty, button enabled when valid, loading state, error state with retry, success navigation. Create `test/features/lobby/view/join_room_page_test.dart`
  - [x] 8.4 Server handler tests for JoinRoom — add to existing `internal/handler/http_test.go`
  - [x] 8.5 Update `test/helpers/factories.dart` — add `createTestJoinRoomBloc()` if needed

## Dev Notes

### Architecture Constraints

- **Room goroutine is sole orchestrator** — all join coordination flows through the room's action channel, not direct package-to-package calls.
- **Server-authoritative** — client never validates room capacity or code existence locally. All validation on server.
- **Protocol types vs domain models** — `core/protocol/` = wire format. `core/models/` = domain. Never use protocol types in Bloc states.
- **JoinRoom HTTP response returns JWT only** — unlike CreateRoom which returns `{roomCode, jwt}`, JoinRoom returns `{jwt}` because the client already knows the room code (they typed it). Architecture spec: `POST /rooms/:code/join → response {jwt}`.

### Existing Code to Build On (DO NOT Recreate)

- **JoinRoom handler stub** (`internal/handler/http.go` line ~105) — route `POST /rooms/{code}/join` is already registered. Replace the `writeNotImplemented` stub with real implementation.
- **FindRoom** (`internal/room/manager.go`) — `FindRoom(code string) *Room` returns room or nil. Use for room existence check.
- **AddPlayer** (`internal/room/room.go`) — `AddPlayer(deviceIDHash string, conn *PlayerConn) error` returns `ErrRoomFull` if >= 8 players. Handles reconnection (replaces old conn). Also has `PlayerCount() int` (public) and `MaxPlayers = 8` (public constant) — use these for HTTP capacity check. Note: `AddPlayer` currently does NOT broadcast `lobby.player_joined` — it only logs via `slog.Info`. Broadcast must be added in Task 2.3.
- **PlayerConn** (`internal/room/connection.go`) — currently `NewPlayerConn(conn, deviceHash)` with only `deviceHash` field. MUST be extended with `displayName` field (Task 2.1) since `lobby.player_joined` broadcast needs it.
- **IssueToken** (`internal/auth/jwt.go`) — `IssueToken(secret, roomCode, deviceIdHash, displayName string) (string, error)` already accepts displayName parameter (was empty string for host in Story 1.5).
- **Protocol error codes** (`internal/protocol/errors.go`) — `ErrRoomNotFound`, `ErrRoomFull`, `ErrInvalidRequest` already defined.
- **RoomApiService** (`lib/core/services/room_api_service.dart`) — add `joinRoom` method following same pattern as `createRoom` (auto-retry, `RoomApiException`, 5s timeout).
- **RoomBloc** (`lib/features/lobby/bloc/`) — add `JoinRoom` event and handler alongside existing `CreateRoom`.
- **WebSocketCubit** (`lib/core/websocket/web_socket_cubit.dart`) — fully implemented `connect(wsUrl, jwt)`. Reuse as-is.
- **DeviceIdentityService** — `getHashedDeviceId()` returns SHA-256 hex. Access via `context.read<DeviceIdentityService>()`.
- **AppConfig** — `apiBaseUrl` and `wsBaseUrl` already configured per flavor.
- **GoRouter** — `/join` route is placeholder. Replace `_PlaceholderScreen` with `JoinRoomPage`.
- **Design system** — all typography, colors, spacing tokens in `lib/core/theme/`. Green button = `RackUpColors.madeGreen`. Error text = `RackUpColors.missedRed`.
- **HomePage buttons** — "Join Room" already navigates to `/join` via `context.push('/join')`.
- **Test helpers** — `test/helpers/pump_app.dart` wraps widgets, `test/helpers/factories.dart` has mock classes for `DeviceIdentityService`, `RoomApiService`, `WebSocketCubit`.
- **CreateRoomPage pattern** — follow the exact same BlocProvider + BlocBuilder + state-switching pattern for JoinRoomPage.

### Key Technical Decisions

- **JoinRoom response is JWT only**: Server returns `{"jwt": "..."}` (not `{roomCode, jwt}` like CreateRoom). The client already has the room code from user input.
- **Display name validation**: Server enforces non-empty, max 20 characters, trimmed. Client mirrors this for UX feedback before submission.
- **Room code input**: 4 separate TextField widgets, each accepting 1 character, auto-uppercase, auto-advance on entry, auto-backspace on delete. Use `FocusNode` per field. Only A-Z allowed (architecture spec: alpha-only codes).
- **Error mapping**: Client maps server error codes to user-friendly messages: `ROOM_NOT_FOUND` → "Room not found — check the code and try again", `ROOM_FULL` → "Room is full (max 8 players)". Network errors → "Connection failed — check your internet and try again".
- **Join button disabled state**: Button is disabled (visually dimmed) until room code is exactly 4 characters AND display name is non-empty. Prevents invalid API calls.
- **No navigation on error**: Error displayed inline below the code input. Inputs remain editable. Same screen, same state — user corrects and retries.
- **HTTP 409 for room full**: Use 409 Conflict (not 403) to indicate room is at capacity. Distinguishes from auth errors.
- **Display name flows through JWT**: `IssueToken` already accepts `displayName` param (was empty string for host in Story 1.5). JoinRoom handler passes display name into JWT → WebSocket upgrade extracts `claims.DisplayName` → passes to `NewPlayerConn` → stored on `PlayerConn` → used in `lobby.player_joined` broadcast. One-way data flow, no extra storage.
- **HTTP join vs WebSocket join — race condition**: The HTTP handler checks `PlayerCount() < MaxPlayers` before issuing JWT. Between HTTP response and WebSocket connect, another player could fill the room. This is acceptable — the WebSocket handler in `websocket.go` is the authoritative guard (already returns `StatusPolicyViolation` on `ErrRoomFull`). Client should handle WebSocket rejection: if connection fails after successful HTTP join, show "Room is full" error.

### File Structure

```
rackup-server/internal/
├── handler/
│   ├── http.go                   # MODIFY: Implement JoinRoom handler (replace stub)
│   ├── http_test.go              # MODIFY: Add JoinRoom tests, update NotImplemented test
│   └── websocket.go              # MODIFY: Pass claims.DisplayName to NewPlayerConn
├── room/
│   ├── connection.go             # MODIFY: Add displayName field + param to NewPlayerConn
│   ├── connection_test.go        # MODIFY: Update NewPlayerConn calls with displayName
│   ├── room.go                   # MODIFY: Add lobby.player_joined broadcast in AddPlayer
│   └── room_test.go              # MODIFY: Add broadcast test, update NewPlayerConn calls

rackup/lib/
├── core/
│   ├── protocol/
│   │   └── messages.dart         # MODIFY: Add JoinRoomResponse class
│   └── services/
│       └── room_api_service.dart # MODIFY: Add joinRoom method
├── features/
│   └── lobby/
│       ├── bloc/
│       │   ├── room_bloc.dart    # MODIFY: Add JoinRoom event handler
│       │   ├── room_event.dart   # MODIFY: Add JoinRoom event
│       │   └── room_state.dart   # MODIFY: Add RoomJoining state
│       └── view/
│           └── join_room_page.dart # NEW: Join room UI
├── core/routing/
│   └── app_router.dart           # MODIFY: Wire JoinRoomPage

rackup/test/
├── core/
│   └── services/
│       └── room_api_service_test.dart # MODIFY: Add joinRoom tests
├── features/
│   └── lobby/
│       ├── bloc/
│       │   └── room_bloc_test.dart    # MODIFY: Add JoinRoom tests
│       └── view/
│           └── join_room_page_test.dart # NEW: Widget tests
└── helpers/
    └── factories.dart            # MODIFY: Add join-specific factories if needed
```

### Project Structure Notes

- All paths align with architecture spec and established patterns from Story 1.5
- `lib/features/lobby/view/` already exists with `create_room_page.dart` — add `join_room_page.dart` alongside it
- No new packages needed — all dependencies (`http`, `flutter_bloc`, `equatable`, `web_socket_channel`) already in pubspec.yaml

### Anti-Patterns to Avoid

- **DO NOT** create a separate Bloc for join — extend existing `RoomBloc` with new events/states
- **DO NOT** use `setState` — use Bloc/Cubit pattern exclusively
- **DO NOT** hardcode API URLs — use `AppConfig.apiBaseUrl`
- **DO NOT** store raw device ID — always use hashed version from `DeviceIdentityService`
- **DO NOT** validate room code existence on the client — send to server and handle error response
- **DO NOT** use Material `ElevatedButton` or `OutlinedButton` — follow established custom button pattern (InkWell + DecoratedBox) from HomePage
- **DO NOT** use `showDialog` for errors — display inline on the same screen
- **DO NOT** navigate away on error — keep user on join screen with editable inputs
- **DO NOT** add display name to host flow — host display name entry is a future story (lobby phase)
- **DO NOT** implement lobby page — after successful join, navigate to a placeholder or the same `_PlaceholderScreen` pattern until lobby is built. The `/lobby` route does not exist yet.
- **DO NOT** add `http` package to pubspec.yaml — it was already added in Story 1.5

### NFR Compliance Checklist

| NFR | Requirement | How to Verify |
|-----|-------------|---------------|
| NFR2 | Join < 3 seconds (code entry to visible in lobby) | Measure POST /rooms/:code/join + WebSocket connect time |
| NFR9 | TLS 1.2+ | Railway provides TLS by default |
| NFR11 | No account/email/phone required | Join flow only requires room code + display name |
| NFR23 | Clear error messages | Typed errors: "Room not found", "Room is full" — not generic |

### Previous Story Intelligence (Story 1.5)

Key learnings from Story 1.5 implementation:
- `web_socket_channel` v3.0.3 `WebSocketChannel.connect` does not support `headers` — must use `IOWebSocketChannel.connect` instead (already fixed in WebSocketCubit)
- `ArgumentError` from invalid port is not caught by `on Exception` — use `on Object` for WebSocket connection errors (already handled)
- Go room tests take ~75s due to WebSocket server cleanup — expect similar for join handler tests
- Handler pattern established: parse JSON body → validate → call manager → issue JWT → return response. Follow this exactly for JoinRoom.
- `RoomApiService` uses `http.Client` with 5-second timeout and single auto-retry on network errors. Follow same pattern for `joinRoom`.
- Test patterns established: `bloc_test` with `mocktail`, `when().thenAnswer()` for async, `when().thenThrow()` for errors.

### Git Intelligence (Recent Commits)

```
94b0de2 Add room creation with code review fixes (Story 1.5)
9aec649 Fix code review findings for Story 1.4
02b8e53 Fix code review findings for Story 1.3 and CI path filters
35b84ab Add device identity & app home screen (Story 1.4)
7ac9a48 Add design system & theme (Story 1.3) with code review fixes
```

Patterns: single commit per story, code review fixes as follow-up commits. All infrastructure (JWT, room manager, WebSocket, protocol layer) was built in Story 1.5 and is ready to use.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.6: Join Room via Code]
- [Source: _bmad-output/planning-artifacts/architecture.md — HTTP endpoints POST /rooms/:code/join, RoomBloc states (RoomJoining), JWT claims with displayName]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR79: Join screen (4-char code input, display name, green Join button), Join Flow tier 2 priority, effortless interactions, accessibility]
- [Source: _bmad-output/planning-artifacts/prd.md — FR2, FR4, FR7, NFR2, NFR11, NFR23]
- [Source: _bmad-output/implementation-artifacts/1-5-room-creation.md — Handler patterns, WebSocketCubit implementation notes, test patterns, established code conventions]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- N/A — no blocking issues encountered

### Completion Notes List

- Task 1: Implemented JoinRoom HTTP handler replacing stub. Validates deviceIdHash, displayName (non-empty, max 20 chars, trimmed), checks room existence via FindRoom, checks capacity via PlayerCount, issues JWT. Error responses: 400 (invalid request), 404 (room not found), 409 (room full). 6 handler tests added.
- Task 2: Extended PlayerConn with displayName field and accessor. Updated NewPlayerConn signature to 3 params. WebSocket handler passes claims.DisplayName. Added `lobby.player_joined` broadcast in AddPlayer using new `broadcastLocked()` method (avoids double-locking). Broadcast test verifies payload fields.
- Task 3: Added JoinRoomResponse class with jwt-only field and fromJson factory.
- Task 4: Added joinRoom method to RoomApiService with auto-retry pattern, errorCode field on RoomApiException for error mapping.
- Task 5: Added JoinRoom event, RoomJoining state, _onJoinRoom handler with error code mapping (ROOM_NOT_FOUND, ROOM_FULL → user-friendly messages).
- Task 6: Created JoinRoomPage with 4-character code input (auto-advance, auto-backspace, uppercase enforcement via TextInputFormatter), display name input (max 20 chars), disabled Join button until valid, inline error display on RoomError state, success view with RoomCodeDisplay.
- Task 7: Wired JoinRoomPage in GoRouter at /join with RoomBloc + WebSocketCubit providers. Removed unused _PlaceholderScreen.
- Task 8: All tests pass — 157 Flutter tests (4 JoinRoom bloc, 4 joinRoom API, 5 JoinRoomPage widget), Go tests all pass (6 JoinRoom handler + 1 broadcast test).

### Change Log

- 2026-03-25: Story 1.6 implementation complete — join room via code (server + client)

### File List

**Server (Go) — Modified:**
- rackup-server/internal/handler/http.go
- rackup-server/internal/handler/http_test.go
- rackup-server/internal/handler/websocket.go
- rackup-server/internal/room/connection.go
- rackup-server/internal/room/connection_test.go
- rackup-server/internal/room/room.go
- rackup-server/internal/room/room_test.go

**Client (Flutter) — Modified:**
- rackup/lib/core/protocol/messages.dart
- rackup/lib/core/services/room_api_service.dart
- rackup/lib/core/routing/app_router.dart
- rackup/lib/features/lobby/bloc/room_bloc.dart
- rackup/lib/features/lobby/bloc/room_event.dart
- rackup/lib/features/lobby/bloc/room_state.dart
- rackup/lib/features/lobby/view/create_room_page.dart

**Client (Flutter) — New:**
- rackup/lib/features/lobby/view/join_room_page.dart

**Tests — Modified:**
- rackup/test/features/lobby/bloc/room_bloc_test.dart
- rackup/test/core/services/room_api_service_test.dart

**Tests — New:**
- rackup/test/features/lobby/view/join_room_page_test.dart
