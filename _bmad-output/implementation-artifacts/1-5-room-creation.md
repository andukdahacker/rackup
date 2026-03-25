# Story 1.5: Room Creation

Status: done

## Story

As a host,
I want to create a new game room and receive a unique join code,
So that I can invite friends to join my game.

## Acceptance Criteria

1. **Given** the player taps "Create Room" on the home screen, **When** the POST /rooms request is sent with the hashed device ID, **Then** the server creates a room goroutine, generates a unique 4-character alpha (A-Z) room code, and returns `{roomCode, jwt}` **And** the JWT contains claims: roomCode, deviceIdHash, displayName, exp (HS256) **And** room creation completes within 2 seconds (NFR1) **And** communication is encrypted via TLS 1.2+ (NFR9)
2. **Given** the room is created successfully, **When** the host receives the response, **Then** a WebSocket connection is established using the JWT **And** the host sees the room code displayed prominently **And** the room code is collision-free against all currently active rooms (NFR18)
3. **Given** room creation fails (network error, server error), **When** the server returns an error or the request times out, **Then** a clear, actionable error message is displayed inline (NFR23) **And** a retry option is available without navigating away
4. **Given** the room is created, **When** the room goroutine is active, **Then** it supports 2-8 concurrent player connections (FR7)

## Tasks / Subtasks

### Server-Side (Go)

- [x] Task 1: JWT auth package (AC: #1)
  - [x] 1.1 Create `internal/auth/jwt.go` — `IssueToken(roomCode, deviceIdHash, displayName string) (string, error)` and `ValidateClaims(tokenString string) (*Claims, error)` using HS256 via `github.com/golang-jwt/jwt/v5`. Run `go get github.com/golang-jwt/jwt/v5` to add the dependency. JWT expiration: 24 hours (rooms are ephemeral sessions, not long-lived). Read `JWT_SECRET` from env var, require minimum 32 bytes.
  - [x] 1.2 Create `internal/auth/jwt_test.go` — round-trip issue/validate, expired token rejection, invalid signature rejection, claims extraction
  - [x] 1.3 Wire JWT_SECRET loading in `cmd/server/main.go` (currently loaded but ignored — activate it, pass to handler/auth)

- [x] Task 2: Room manager and room goroutine (AC: #1, #2, #4)
  - [x] 2.1 Create `internal/room/manager.go` — `RoomManager` struct with: `CreateRoom(ctx context.Context, hostDeviceIDHash string) (*Room, string)` (creates cancellable child context for room goroutine, returns room + code), `FindRoom(code string) *Room`, code generation (4-char A-Z via `crypto/rand`, collision-free against active rooms), room registry (sync.RWMutex-guarded map), `CleanupRoom(code string)` (cancels room context, removes from registry)
  - [x] 2.2 Create `internal/room/room.go` — `Room` struct with: players map, room code, created timestamp, max players (8). Room goroutine lifecycle: `Run(ctx context.Context)` method that selects on action channel + context cancellation. Player management: `AddPlayer`, `RemovePlayer`, `BroadcastMessage`. 60-second per-player reconnection hold window. 5-minute room-level timeout when all players disconnect.
  - [x] 2.3 Create `internal/room/connection.go` — WebSocket connection wrapper: `PlayerConn` struct wrapping `nhooyr.io/websocket.Conn`, read/write message helpers, disconnect detection, connection swap for reconnection
  - [x] 2.4 Create `internal/room/manager_test.go` — code generation uniqueness, room create/find/cleanup, concurrent room creation safety
  - [x] 2.5 Create `internal/room/room_test.go` — player add/remove, max 8 player enforcement, broadcast to all connected players
  - [x] 2.6 Create `internal/room/connection_test.go` — connection wrap/unwrap, message read/write, disconnect detection
  - [x] 2.7 Create test factories in `internal/testutil/factories.go` — `NewTestRoom()`, `NewTestPlayer()`, `NewTestRoomManager()`

- [x] Task 3: HTTP handler — POST /rooms (AC: #1, #3)
  - [x] 3.1 Update `internal/handler/http.go` — add `RoomManager` and `JWTSecret` fields to `Handler` struct (keep existing `pool` field), update `New()` constructor signature. Must update `cmd/server/main.go` call site simultaneously (Task 3.4) to avoid compilation failure.
  - [x] 3.2 Implement `CreateRoom` handler: parse request body `{deviceIdHash}`, call `manager.CreateRoom()`, issue JWT via `auth.IssueToken()`, return `{roomCode, jwt}` with 201 status
  - [x] 3.3 Error responses: 400 for missing deviceIdHash, 503 for capacity exceeded (NFR24), 500 for internal errors — all using `protocol.ErrorPayload` format
  - [x] 3.4 Update `cmd/server/main.go` — create `RoomManager`, pass to handler constructor along with JWT secret
  - [x] 3.5 Create `internal/handler/http_test.go` — test CreateRoom: success path, missing body, error responses

- [x] Task 4: WebSocket upgrade handler (AC: #2)
  - [x] 4.1 Create `internal/handler/websocket.go` — `Upgrade` handler: extract JWT from `Authorization: Bearer <token>` header on the HTTP upgrade request BEFORE accepting the WebSocket upgrade. Validate claims via `auth.ValidateClaims()`. If invalid/missing, reject with HTTP 401 (do NOT upgrade). On valid JWT, accept WebSocket via `nhooyr.io/websocket`, find room by roomCode via `manager.FindRoom()`, add player connection to room. No query params, no post-upgrade handshake.
  - [x] 4.2 Register WebSocket route: `GET /ws` in the existing `RegisterRoutes` method on `Handler` struct (same file as HTTP routes)
  - [x] 4.3 Write/read pump goroutines per connection: read loop dispatches messages to room channel, write loop sends messages from player's outbound channel

### Client-Side (Flutter)

- [x] Task 5: Protocol layer sync (AC: #1, #2)
  - [x] 5.1 Update `lib/core/protocol/messages.dart` — add `Message` class (action + payload JSON), `CreateRoomResponse` (roomCode, jwt), `ErrorResponse` (code, message). Mirror Go protocol types.
  - [x] 5.2 Update `lib/core/protocol/actions.dart` — add action constants matching Go: `lobbyPlayerJoined`, `error`
  - [x] 5.3 Update `lib/core/protocol/errors.dart` — add error code constants: `roomFull`, `roomNotFound`, `unauthorized`

- [x] Task 6: Room API service (AC: #1, #3)
  - [x] 6.1 Create `lib/core/services/room_api_service.dart` — `createRoom(String deviceIdHash)` method using `package:http` (add `http: ^1.4.0` to pubspec.yaml): POST to `${config.apiBaseUrl}/rooms` with JSON body `{deviceIdHash}`, parse response into `CreateRoomResponse`, implement single automatic retry on network error before throwing typed exception on failure
  - [x] 6.2 Provide via `RepositoryProvider` in app.dart (same pattern as `DeviceIdentityService`)

- [x] Task 7: WebSocket cubit implementation (AC: #2)
  - [x] 7.1 Implement `WebSocketCubit` in `lib/core/websocket/web_socket_cubit.dart` — `connect(String wsUrl, String jwt)`, `disconnect()`, `sendMessage(Message)`. States: Disconnected → Connecting → Connected → Reconnecting. Use `web_socket_channel` package. Pass JWT via `WebSocketChannel.connect(url, headers: {'Authorization': 'Bearer $jwt'})`.
  - [x] 7.2 Add remaining WebSocket states to `web_socket_state.dart`: `WebSocketConnecting`, `WebSocketConnected(channel)`, `WebSocketReconnecting(attempt, elapsedSeconds)`, `WebSocketConnectionFailed(reason)` (terminal state after 60s reconnection exhausted)
  - [x] 7.3 Implement `ReconnectionHandler` — exponential backoff (1s, 2s, 4s, 8s, max 16s) for up to 60 seconds total. After 60s, emit `WebSocketConnectionFailed` — UI shows "Connection Lost" with option to retry or go home

- [x] Task 8: RoomBloc — create room flow (AC: #1, #2, #3)
  - [x] 8.1 Create `lib/features/lobby/bloc/room_bloc.dart` — events: `CreateRoom`, `RoomCreated`, `RoomCreateFailed`, `WebSocketConnected`. States: `RoomInitial`, `RoomCreating`, `RoomCreated(roomCode, jwt)`, `RoomError(message)`
  - [x] 8.2 Create `lib/features/lobby/bloc/room_event.dart` and `room_state.dart` with equatable
  - [x] 8.3 On `CreateRoom`: get hashed device ID from `DeviceIdentityService`, call `RoomApiService.createRoom()`, on success emit `RoomCreated` + trigger WebSocket connect, on failure emit `RoomError`

- [x] Task 9: Create Room UI (AC: #1, #2, #3)
  - [x] 9.1 Replace `/create` placeholder in `app_router.dart` with `CreateRoomPage` route, provide `RoomBloc` via `BlocProvider`
  - [x] 9.2 Create `lib/features/lobby/view/create_room_page.dart`:
    - Loading state: centered spinner with "Creating room..." text
    - Success state: room code displayed (Oswald 36dp, gold `RackUpColors.streakGold`, letter-spaced), "Share Invite Link" button (primary, full-width, above room code), share via `share_plus` package
    - Error state: inline error message with "Try Again" button, no navigation away
  - [x] 9.3 Create `lib/features/lobby/view/widgets/room_code_display.dart` — prominent room code widget with gold Oswald typography and letter spacing

- [x] Task 10: Testing (all ACs)
  - [x] 10.1 Unit tests for `RoomBloc` — create room success/failure flows, state transitions
  - [x] 10.2 Unit tests for `RoomApiService` — mock HTTP responses, parse success/error
  - [x] 10.3 Widget tests for `CreateRoomPage` — loading state, room code display, error + retry, share button
  - [x] 10.4 Unit tests for `WebSocketCubit` — connect/disconnect state transitions, reconnection
  - [x] 10.5 Update `test/helpers/factories.dart` — add `createTestRoomBloc()`, `createTestRoomApiService()`

## Dev Notes

### Architecture Constraints

- **Room goroutine is sole orchestrator** — the room goroutine (`internal/room/room.go`) coordinates all cross-package flows. No package calls another directly. All coordination flows through the room's action channel.
- **In-memory state during gameplay** — game state lives in the room goroutine, never in DB hot path. DB is only for post-game archival (Story 8.x).
- **Server-authoritative** — clients never trust game logic validation. All state transitions validated server-side.
- **Protocol types vs domain models** — `core/protocol/` = wire format for JSON (de)serialization. `core/models/` = domain objects for Bloc states. Never use protocol types in Bloc states. `WebSocketCubit` converts protocol → model during dispatch.

### Existing Code to Build On (DO NOT Recreate)

- **DeviceIdentityService** (`lib/core/services/device_identity_service.dart`) — already provides `getHashedDeviceId()` returning SHA-256 hex. Use `context.read<DeviceIdentityService>()` to access.
- **AppConfig** (`lib/core/config/`) — `apiBaseUrl` and `wsBaseUrl` already defined per flavor. DevConfig points to `http://localhost:8080` / `ws://localhost:8080`.
- **Design system** — all typography, colors, spacing tokens exist in `lib/core/theme/`. Use `RackUpColors.streakGold` for room code display, `RackUpTypography.displayMd` for room code (36dp Oswald), `RackUpSpacing` for all margins/padding.
- **GoRouter** (`lib/core/routing/app_router.dart`) — `/create` route already defined as placeholder. Replace `_PlaceholderScreen` with real `CreateRoomPage`.
- **WebSocketCubit stub** (`lib/core/websocket/web_socket_cubit.dart`) — shell exists with `WebSocketDisconnected` initial state. Implement connection logic here.
- **ReconnectionHandler stub** (`lib/core/websocket/reconnection_handler.dart`) — shell exists. Implement exponential backoff here.
- **Protocol stubs** — `messages.dart`, `actions.dart`, `errors.dart` all have `SYNC WITH:` headers. Add types matching Go counterparts.
- **Handler stubs** — `internal/handler/http.go` already has `CreateRoom` and `JoinRoom` stub methods + route registrations for `POST /rooms` and `POST /rooms/{code}/join`. **Do NOT implement JoinRoom** — that is Story 1.6. Only implement CreateRoom. Update the JoinRoom stub comment from "Story 1.5" to "Story 1.6".
- **Server entry point** — `cmd/server/main.go` already reads `JWT_SECRET` env var (line 39, currently ignored).
- **Go dependencies** — `nhooyr.io/websocket v1.8.17` already in `go.mod`. `pgx/v5` already available.
- **Flutter dependencies** — `web_socket_channel`, `share_plus`, `flutter_bloc`, `bloc`, `equatable` all in `pubspec.yaml`.
- **Test helper** — `test/helpers/pump_app.dart` wraps widgets with MaterialApp + RackUpGameTheme. Use for all widget tests.
- **Homepage buttons** — navigate via `context.push('/create')` and `context.push('/join')` with debounce guard.

### Key Technical Decisions

- **JWT in WebSocket**: Pass JWT via `Authorization: Bearer <token>` header in the HTTP upgrade request. Server validates BEFORE upgrading — rejects with 401 if invalid. No query params, no post-upgrade auth message. Flutter's `web_socket_channel` supports custom headers: `WebSocketChannel.connect(url, headers: {'Authorization': 'Bearer $jwt'})`.
- **Room code generation**: Random 4-char A-Z using `crypto/rand` (not `math/rand`), checked against active room map for collision avoidance. 456K combinations (alpha-only per architecture spec — PRD says "alphanumeric" but architecture narrowed to alpha-only for readability at noisy bars).
- **Go concurrency**: `sync.RWMutex` on room registry map in manager. Each room runs its own goroutine with a buffered action channel. No shared mutable state between rooms.
- **Share flow**: Use `share_plus` package for native share sheet. Share text format: "Join my RackUp game! Use code: XXXX or tap: rackup.app/join/XXXX"
- **Error display**: Inline errors on create room page — no dialogs, no navigation. User can retry from same screen.
- **No display name for host yet**: Host creates room without display name. Display name entry happens in lobby (Story 1.6 adds this). JWT `displayName` claim can be empty string for host at creation time.
- **Server logging**: Use Go `slog` structured logging. `slog.Info` for: room created, player joined. `slog.Warn` for: invalid actions rejected, reconnection attempts. `slog.Error` for: WebSocket failures, DB errors. `slog.Debug` for: message payloads, state transitions (local dev only).
- **Wire format**: All WebSocket messages use JSON envelope: `{"action": "namespace.verb_noun", "payload": {...}}`. Action naming: all lowercase with underscores (e.g., `lobby.player_joined`). Error actions: `{"action": "error", "payload": {"code": "ROOM_FULL", "message": "..."}}`.
- **HTTP retry**: Client implements single automatic retry on network error for room creation before showing error to user (architecture spec requirement).
- **Deep link in share text**: The `rackup.app/join/XXXX` URL in share text is a placeholder — deep link handling is implemented in Story 1.7. For now, just include it in share text string.
- **Reconnection scope**: The 60-second per-player reconnection hold and 5-minute room timeout should be implemented as functional stubs with correct timer values. Full reconnection swap logic is exercised more in Stories 9.1-9.2, but the infrastructure must be in place now.

### File Structure (New Files)

```
rackup-server/internal/
├── auth/
│   ├── jwt.go                    # NEW: JWT issue + validate
│   └── jwt_test.go               # NEW
├── room/
│   ├── manager.go                # NEW: Room registry, code gen
│   ├── room.go                   # NEW: Room struct, goroutine
│   ├── connection.go             # NEW: WebSocket connection wrapper
│   ├── manager_test.go           # NEW
│   ├── room_test.go              # NEW
│   └── connection_test.go        # NEW
├── handler/
│   ├── http.go                   # MODIFY: CreateRoom implementation
│   ├── websocket.go              # NEW: WebSocket upgrade handler
│   └── http_test.go              # NEW
└── testutil/
    └── factories.go              # MODIFY: Add test factories

rackup/lib/
├── core/
│   ├── protocol/
│   │   ├── messages.dart         # MODIFY: Add wire types
│   │   ├── actions.dart          # MODIFY: Add action constants
│   │   └── errors.dart           # MODIFY: Add error constants
│   ├── services/
│   │   └── room_api_service.dart # NEW: HTTP room API client
│   └── websocket/
│       ├── web_socket_cubit.dart  # MODIFY: Implement connection
│       ├── web_socket_state.dart  # MODIFY: Add states
│       └── reconnection_handler.dart # MODIFY: Implement backoff
├── features/
│   └── lobby/
│       ├── bloc/
│       │   ├── room_bloc.dart    # NEW
│       │   ├── room_event.dart   # NEW
│       │   └── room_state.dart   # NEW
│       └── view/
│           ├── create_room_page.dart # NEW
│           └── widgets/
│               └── room_code_display.dart # NEW
└── core/routing/
    └── app_router.dart           # MODIFY: Wire CreateRoomPage

rackup/test/
├── core/
│   ├── services/
│   │   └── room_api_service_test.dart # NEW
│   └── websocket/
│       └── web_socket_cubit_test.dart # MODIFY: Add connection tests
├── features/
│   └── lobby/
│       ├── bloc/
│       │   └── room_bloc_test.dart    # NEW
│       └── view/
│           └── create_room_page_test.dart # NEW
└── helpers/
    └── factories.dart            # MODIFY: Add room test factories
```

### Project Structure Notes

- Alignment with unified project structure confirmed — all paths match architecture spec exactly
- `internal/room/` directory is empty (reserved) — create all files fresh
- `internal/auth/` directory is empty (reserved) — create all files fresh
- `lib/features/lobby/` has `.gitkeep` — remove and add real files
- `lib/core/models/` has `.gitkeep` — leave for now (models added in Story 1.6 when Player model needed)

### Anti-Patterns to Avoid

- **Use `github.com/golang-jwt/jwt/v5`** for JWT (not v4, not raw crypto/hmac). Add to `go.mod`.
- **DO NOT** put JWT in WebSocket URL query params or send as post-upgrade message — use `Authorization: Bearer` header on upgrade request
- **DO NOT** use `Material.ElevatedButton` or `Material.OutlinedButton` — follow established custom button pattern from HomePage (InkWell + DecoratedBox)
- **Add `http: ^1.4.0`** to pubspec.yaml for HTTP client (not currently listed — needs explicit addition)
- **DO NOT** create separate Bloc for WebSocket — use existing `WebSocketCubit` pattern
- **DO NOT** use `setState` in lobby pages — use Bloc/Cubit pattern exclusively
- **DO NOT** hardcode API URLs — always use `AppConfig.apiBaseUrl` / `AppConfig.wsBaseUrl`
- **DO NOT** store raw device ID in JWT — always use hashed version from `DeviceIdentityService.getHashedDeviceId()`

### NFR Compliance Checklist

| NFR | Requirement | How to Verify |
|-----|-------------|---------------|
| NFR1 | Room creation < 2 seconds | Measure POST /rooms response time |
| NFR9 | TLS 1.2+ | Railway provides TLS by default |
| NFR16 | 100 concurrent rooms | Room manager uses efficient map lookup |
| NFR18 | Collision-free room codes | Check against active room map before assigning |
| NFR23 | Clear error messages | Typed `ErrorPayload` with human-readable messages |
| NFR24 | Graceful capacity rejection | Return 503 when room limit exceeded |

### References

- [Source: _bmad-output/planning-artifacts/architecture.md — Room Management, JWT Auth, WebSocket sections]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.5]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 1: Room Creation, Host Lobby, Design Benchmarks]
- [Source: _bmad-output/planning-artifacts/prd.md — FR1, FR7, NFR1, NFR2, NFR16-18, NFR23-24]
- [Source: _bmad-output/implementation-artifacts/1-4-device-identity-and-app-home-screen.md — DeviceIdentityService pattern, HomePage navigation, design system usage]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Go room tests take ~75s due to WebSocket server cleanup in test fixtures
- `web_socket_channel` v3.0.3 `WebSocketChannel.connect` does not support `headers` — must use `IOWebSocketChannel.connect` instead
- `ArgumentError` from invalid port is not caught by `on Exception` — used `on Object` for WebSocket connection errors

### Completion Notes List

- **Task 1**: JWT auth package (`internal/auth/jwt.go`) — HS256 via `golang-jwt/jwt/v5`, 24h expiry, 32-byte minimum secret, round-trip issue/validate with 8 tests
- **Task 2**: Room manager + room goroutine + connection wrapper — `sync.RWMutex`-guarded registry, crypto/rand 4-char A-Z codes, max 100 rooms, max 8 players, action channel, `WriteDirect` for broadcast, reconnection slot support, 11 tests
- **Task 3**: HTTP handler `POST /rooms` — parses `{deviceIdHash}`, creates room, issues JWT, returns 201 `{roomCode, jwt}`, 400/503/500 error handling, 5 handler tests. Updated `JoinRoom` stub comment to Story 1.6
- **Task 4**: WebSocket upgrade handler `GET /ws` — validates JWT from `Authorization: Bearer` header before upgrade, finds room, adds player, read/write pump goroutines
- **Task 5**: Flutter protocol layer — `Message`, `CreateRoomResponse`, `ErrorResponse` classes, `Actions` constants, `ErrorCodes` constants mirroring Go
- **Task 6**: `RoomApiService` — POST to `/rooms`, single auto-retry on network error, typed `RoomApiException`, provided via `RepositoryProvider` in `app.dart`
- **Task 7**: `WebSocketCubit` — `IOWebSocketChannel.connect` with JWT header, `ReconnectionHandler` with exponential backoff (1s,2s,4s,8s,max 16s) over 60s window, 5 states (Disconnected/Connecting/Connected/Reconnecting/ConnectionFailed)
- **Task 8**: `RoomBloc` — `CreateRoom` event triggers device hash lookup + API call + WebSocket connect, emits `RoomCreating`/`RoomCreatedState`/`RoomError`
- **Task 9**: `CreateRoomPage` — auto-triggers creation, loading spinner, gold room code display, share button via `share_plus`, inline error with retry. Wired in `app_router.dart` replacing placeholder
- **Task 10**: All tests — 3 RoomBloc tests (success/API fail/exception), 4 RoomApiService tests (success/400/503/non-JSON), 4 CreateRoomPage widget tests, 6 WebSocketCubit+ReconnectionHandler tests, updated factories

### Change Log

- 2026-03-25: Story 1.5 implementation complete — full room creation flow end-to-end

### File List

#### Server (Go) — New
- rackup-server/internal/auth/jwt.go
- rackup-server/internal/auth/jwt_test.go
- rackup-server/internal/room/manager.go
- rackup-server/internal/room/room.go
- rackup-server/internal/room/connection.go
- rackup-server/internal/room/manager_test.go
- rackup-server/internal/room/room_test.go
- rackup-server/internal/room/connection_test.go

#### Server (Go) — Modified
- rackup-server/cmd/server/main.go
- rackup-server/internal/handler/http.go
- rackup-server/internal/handler/http_test.go
- rackup-server/internal/handler/websocket.go
- rackup-server/internal/protocol/errors.go
- rackup-server/internal/testutil/factories.go
- rackup-server/go.mod
- rackup-server/go.sum

#### Client (Flutter) — New
- rackup/lib/core/services/room_api_service.dart
- rackup/lib/features/lobby/bloc/room_bloc.dart
- rackup/lib/features/lobby/bloc/room_event.dart
- rackup/lib/features/lobby/bloc/room_state.dart
- rackup/lib/features/lobby/view/create_room_page.dart
- rackup/lib/features/lobby/view/widgets/room_code_display.dart
- rackup/test/core/services/room_api_service_test.dart
- rackup/test/features/lobby/bloc/room_bloc_test.dart
- rackup/test/features/lobby/view/create_room_page_test.dart

#### Client (Flutter) — Modified
- rackup/lib/core/protocol/messages.dart
- rackup/lib/core/protocol/actions.dart
- rackup/lib/core/protocol/errors.dart
- rackup/lib/core/websocket/web_socket_cubit.dart
- rackup/lib/core/websocket/web_socket_state.dart
- rackup/lib/core/websocket/reconnection_handler.dart
- rackup/lib/core/routing/app_router.dart
- rackup/lib/app/view/app.dart
- rackup/test/core/websocket/web_socket_cubit_test.dart
- rackup/test/helpers/factories.dart
- rackup/pubspec.yaml
- rackup/pubspec.lock

#### Deleted
- rackup/lib/features/lobby/.gitkeep
- rackup/lib/core/services/.gitkeep
