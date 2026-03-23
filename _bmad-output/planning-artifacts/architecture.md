---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-rackup-2026-03-20.md
  - _bmad-output/planning-artifacts/research/market-rackup-global-bar-game-market-research-2026-03-02.md
  - _bmad-output/planning-artifacts/research/market-vietnam-pool-culture-research-2026-03-02.md
  - _bmad-output/planning-artifacts/research/party-game-market-research-report-2026-03-02.md
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-03-21'
project_name: 'RackUp'
user_name: 'Ducdo'
date: '2026-03-21'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (68 total):**

| Domain | Count | Architectural Significance |
|--------|-------|---------------------------|
| Room & Multiplayer (FR1-FR11) | 11 | Room lifecycle, join flow, deep linking, mid-game joining — defines the session management layer |
| Game Flow & Turn Management (FR12-FR17) | 6 | Turn state machine, consequence chain orchestration, triple-points mode — the game engine core |
| Referee System (FR18-FR25) | 8 | Complex client-side state machine with rotation, handoff, and **authority transfer** between devices — highest UI complexity and a distinct real-time state ownership concern |
| Scoring & Streaks (FR26-FR31) | 6 | Point calculations, streak tracking, mission bonuses — pure game logic, server-computed |
| Items & Power-Ups (FR32-FR36j) | 15 | **Item effect resolution engine** with 4 distinct execution patterns: instant effects (Blue Shell), persistent effects (Shield, Immunity), targeted effects requiring player selection (Score Steal, Reverse), and group-vote effects (Mulligan). Requires a clean effect interface to avoid special-casing |
| Secret Missions (FR37-FR40) | 4 | Probability-based assignment, private display, referee-confirmed completion |
| Punishments (FR41-FR44) | 4 | Tiered deck with percentage-based escalation, custom submissions mixed in |
| Leaderboard & Display (FR45-FR49) | 5 | Real-time animated leaderboard, sound effects, screen wake lock |
| Post-Game & Sharing (FR50-FR56) | 7 | Report card generation, styled image rendering (client-side template rendering engine), ceremony flow, "RECORD THIS" prompts |
| Connectivity & Resilience (FR57-FR61) | 5 | Disconnect detection, auto-skip, state preservation, silent reconnect — affects entire architecture |
| Analytics & Identity (FR62-FR68) | 7 | Device ID, **group identity player graph** (core data model, not analytics bolt-on), event tracking |

**Non-Functional Requirements (25 total):**

| Category | Key Constraints | Architecture Impact |
|----------|----------------|---------------------|
| Performance (NFR1-8) | Room creation <2s, join <3s, state sync <2s, animations 60fps, sounds <200ms latency | Managed real-time service essential; client-side animation optimization for low-end Android |
| Security & Privacy (NFR9-15) | TLS 1.2+, hashed device IDs, 90-day data retention, GDPR/CCPA | Standard security posture; analytics data lifecycle management |
| Scalability (NFR16-19) | 100 concurrent rooms MVP, 1,000+ without architecture changes, burst writes at game end | Managed service selection must accommodate 10x growth without re-architecture |
| Reliability (NFR20-25) | 99.95% uptime via provider SLA, app backgrounding recovery, <15% battery per 60-min session, crash-free >99% | Efficient WebSocket keep-alive, no polling, graceful degradation under load |

**Scale & Complexity:**

- Primary domain: Mobile-first real-time multiplayer (Flutter + managed backend)
- Complexity level: Medium
- Estimated architectural components: ~8-10 (client app, real-time service, game state engine, consequence chain orchestrator, item effect resolution engine, analytics pipeline, share image generator, deep link handler, push notification service [Phase 1.5])

### Technical Constraints & Dependencies

1. **Solo developer + solo operability** — architecture must minimize ops burden; managed services over self-hosted infrastructure. Every component must pass the test: "Can one person operate this at 3 AM when something breaks?" If it requires more than checking a dashboard and maybe restarting a service, it's the wrong architecture
2. **Flutter cross-platform** — single codebase for iOS + Android; constrains backend choices to those with good Flutter SDKs
3. **App-required for MVP** — all clients run native Flutter app (web join deferred to Phase 2)
4. **Anonymous-first auth** — device ID only for MVP; optional sign-in in Phase 1.5
5. **Ephemeral rooms** — no persistent room state between sessions; simplifies data model
6. **<50MB app size** — download-on-the-spot at a bar over cell data
7. **Portrait-locked** — single orientation simplifies layout
8. **Group identity as core data model** — 7-Day Group Return is the make-or-break metric. Group identity must be derived from player composition (which anonymous device IDs appear together across sessions). This requires a **player graph** in the data model — mapping device ID hashes to session participation. This is not an analytics bolt-on; it shapes how session data is stored and queried from day one. Without it, the MVP ships blind to its own success metric

### Cross-Cutting Concerns Identified

1. **Connectivity resilience** — every feature must handle disconnect/reconnect gracefully; this isn't a feature, it's a design constraint that permeates the entire architecture
2. **Server-authoritative state** — all game logic (scoring, items, streaks, missions, punishments) computed server-side; clients render received state with optimistic updates
3. **Consequence chain orchestration** — every shot result triggers a deterministic cascade: `shot_result → streak_update → item_drop_check → punishment_draw → score_update → leaderboard_recalc → UI_events → sound_triggers → "RECORD THIS"_check`. Steps depend on previous steps (item drops depend on rank, which depends on score, which depends on streak). This requires a **pipeline pattern** on the server, not scattered event handlers. In the final rounds, this cascade must resolve within the 2-second sync window across 8 devices simultaneously
4. **Referee authority transfer** — the referee role is not just a UI concern. When the referee hands off (or disconnects and fails over), the WebSocket connection that is authoritative for referee actions shifts from one device to another. This is a real-time authority transfer pattern — the server must track which client holds referee authority and reject referee actions from non-authoritative clients
5. **Analytics instrumentation** — events woven into room creation, game flow, item use, sharing, and group identity; must be non-blocking
6. **Sound/haptic triggers** — 5 MVP sound effects triggered from game state changes across multiple subsystems; centralized event bus recommended
7. **Game state consistency** — all players must see the same leaderboard, items, and turn state within 2 seconds; the referee's actions are the authoritative input

## Starter Template Evaluation

### Primary Technology Domain

Mobile-first real-time multiplayer: Flutter client + custom Go WebSocket game server, deployed on Railway.

### Starter Options Considered

**Flutter Client Starters:**

| Starter | What It Provides | Verdict |
|---------|-----------------|---------|
| `flutter create` (standard) | Bare Flutter app, minimal structure | Too bare — no state management, testing infra, or production patterns |
| Very Good CLI (`very_good create flutter_app`) | Bloc state management, 100% test coverage setup, flavors (dev/staging/prod), localization, CI-ready | **Selected** — production-grade structure, Bloc maps well to referee state machine and game state |
| Flutter Starter CLI | Riverpod or Bloc, Dio/HTTP API options | Less mature, smaller community |

**Backend Game Server Options:**

| Option | Language | Flutter SDK | Railway | Verdict |
|--------|---------|-------------|---------|---------|
| Colyseus 0.17 (Feb 2026) | TypeScript | **No official Dart/Flutter SDK** | Yes | **Eliminated** — best game framework but no Flutter client SDK, open issue since 2019 |
| Nakama | Go (server) | Official Dart SDK (`^1.3.0`) | Yes (Docker) | **Eliminated** — too heavy; built-in accounts, chat, matchmaker fight RackUp's anonymous/ephemeral model |
| Custom Go WebSocket server | Go | `web_socket_channel` (standard Dart) | Yes (native) | **Selected** — full control, goroutines per room, channels for pipeline, solo-operable |

### Selected Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Client** | Flutter (Very Good CLI) + Bloc | Production-grade structure, state machine-friendly, testing infra from day one |
| **Backend** | Custom Go WebSocket server | Goroutines per room, channels for consequence chain pipeline, single binary deployment |
| **Database** | PostgreSQL (Railway, `pgx`) | Session archival, group identity player graph, analytics queries |
| **Real-time** | `nhooyr.io/websocket` | Modern Go WebSocket lib, context-aware, production-ready |
| **Deployment** | Railway (single instance for MVP) | Go binary + PostgreSQL addon, health checks, zero Docker config needed |
| **Auth (MVP)** | Device ID (anonymous) | Generated client-side, hashed server-side |

### Initialization Commands

**Flutter Client:**

```bash
dart pub global activate very_good_cli
very_good create flutter_app rackup --desc "Party game platform for real bar games" --org "com.rackup.app"
```

**Go Backend:**

```bash
mkdir rackup-server && cd rackup-server
go mod init github.com/ducdo/rackup-server
go get nhooyr.io/websocket
go get github.com/jackc/pgx/v5
go get github.com/google/uuid
```

### Architectural Decisions Provided by Stack Selection

**Language & Runtime:**
- Client: Dart (Flutter 3.x, Very Good CLI template)
- Server: Go (single binary, goroutine-per-room concurrency model)

**State Management (Client):**
- Bloc pattern — maps naturally to the referee state machine (6+ states) and game state management
- Single WebSocket cubit as the sole inbound pipe, fanning out to game-specific blocs (room, game, leaderboard, items)

**Real-time Communication:**
- `nhooyr.io/websocket` (server) ↔ `web_socket_channel` (client)
- JSON envelope protocol for MVP: `{"type": "shot_result", "payload": {...}}`
- JSON chosen for debuggability at MVP scale; binary (msgpack/protobuf) deferred until optimization is needed

**Database Strategy:**
- PostgreSQL is **cold path only** — never in the game hot path
- Game state lives in memory (room goroutine) during active sessions
- Post-game: events buffered via Go channel, drained to PostgreSQL asynchronously in a background goroutine
- PostgreSQL stores: session archives, group identity player graph, analytics events

**Deployment:**
- Single Railway instance for MVP (100 concurrent rooms target — well within single-instance capacity)
- `/health` endpoint from day one for Railway health checks and auto-restart
- Multi-instance architecture (sticky sessions or Redis room registry) deferred — evaluate when approaching 1,000+ concurrent rooms

**First Implementation Task:**
- Define the `Room` struct and its goroutine lifecycle — every other system (turns, items, scoring, connectivity) hangs off the room

### Decisions Deferred to Step 4 (Architectural Decisions)

- **Reconnection protocol design** — how the server holds player slots during disconnect, connection swapping on reconnect, device ID verification in reconnect handshake
- **Single vs. multi-instance scaling strategy** — when and how to transition from single Railway instance
- **Message protocol specification** — full enumeration of message types and payload shapes

**Note:** Project initialization using these commands should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Data model: Normalized PostgreSQL tables (`sessions`, `session_players`, `session_events`)
- Message protocol: Namespaced JSON envelope with atomic turn updates (`game.turn_complete`)
- Reconnection protocol: Server holds player slot for 60s, connection swap on reconnect via JWT + device ID
- Bloc architecture: 6 blocs with single WebSocket cubit inbound pipe, synchronous dispatch model

**Important Decisions (Shape Architecture):**
- Device ID: Client UUID v4 → SHA-256 hash server-side
- WebSocket auth: Short-lived JWT with structured claims (`roomCode`, `deviceIdHash`, `displayName`, `exp`)
- Room codes: 4-char alpha only (A-Z), no ambiguous characters
- Share image: `RepaintBoundary` capture of report card widget
- Monitoring: Sentry for both Flutter client and Go server

**Deferred Decisions (Post-MVP):**
- Multi-instance scaling (sticky sessions or Redis room registry) — evaluate at 1,000+ concurrent rooms
- Binary message protocol (msgpack/protobuf) — optimize when JSON becomes a bottleneck
- Materialized player graph — upgrade from query-time computation when analytics queries slow down

### Data Architecture

- **Database:** PostgreSQL on Railway (`pgx` driver)
- **Schema:** Normalized tables — `sessions` (game metadata, timestamps), `session_players` (device_id_hash, display_name, final_score, awards per session), `session_events` (timestamped game events for analytics)
- **Indexes:** Composite index on `session_players(device_id_hash, session_id)` from day one — critical for group identity queries and costs nothing at low volume
- **Group identity:** Query-time computation — on session end, query `session_players` for overlapping device ID hash sets across sessions. Self-join is performant through ~3,500 player rows/week (100 rooms/day). Materialize the player graph when approaching 10,000+ rooms/day
- **Migration tool:** `golang-migrate` with SQL migration files
- **Data flow:** Game state lives in-memory (room goroutine) during play → buffered Go channel → async drain to PostgreSQL on game end. Database is never in the hot path

### Authentication & Security

- **Device ID:** Client generates UUID v4 on first launch, persists locally. Server receives raw UUID, hashes with SHA-256 before storage. Same hash = same returning player
- **WebSocket auth:** Server issues a short-lived JWT on room creation/join via HTTP endpoint. JWT claims: `{roomCode, deviceIdHash, displayName, exp}`. Client includes JWT in WebSocket upgrade request. Server validates JWT, extracts room code + player identity, routes to correct room goroutine. No query params, no extra handshake
- **JWT implementation:** HS256 with strong random secret stored as Railway environment variable. Rotate-ability: briefly accept both old and new secrets during transition window if needed
- **Room codes:** 4-character alpha only (A-Z), 456K combinations. Sufficient for MVP scale. Codes are ephemeral — released when room ends
- **TLS:** All communication over TLS 1.2+ (Railway provides this by default)
- **Custom punishment text:** Visible only within the room — never persisted beyond session archival, never exposed via API

### API & Communication Patterns

- **Message protocol:** Namespaced JSON envelope
  ```json
  {"action": "game.turn_complete", "payload": {"playerId": "...", "shotResult": "missed", "scoreChange": -0, "streak": 0, "itemDrop": {"item": "blue_shell"}, "punishment": {"text": "...", "tier": "SPICY"}, "leaderboard": [...], "recordThis": false}}
  {"action": "lobby.player_joined", "payload": {"displayName": "Danny", ...}}
  {"action": "error", "payload": {"code": "ROOM_FULL", "message": "..."}}
  ```
  - Namespaces: `lobby.*`, `game.*`, `referee.*`, `item.*`, `postgame.*`, `system.*`
- **Atomic turn updates:** The server's consequence chain pipeline produces a single `game.turn_complete` message per shot containing ALL consequences (score change, streak update, item drop, punishment, leaderboard positions, "RECORD THIS" flag, cascade timing profile). Clients never receive piecemeal updates for a single shot — this ensures visual consistency for leaderboard animations
- **Anytime item deployment (UX spec override of PRD FR35):** Players can deploy their held item at any point during active gameplay, not just on their own turn. The server accepts `item.deploy` from any player at any time while the game is in progress. Item effects resolve immediately as a parallel event — the room goroutine processes item deployments outside the turn consequence chain and broadcasts `item.deployed` + updated leaderboard to all clients. If a deployment coincides with an active turn cascade, the server queues the item effect to resolve after the current cascade completes, preventing race conditions
- **Play Again flow:** After game end, host sends `postgame.play_again`. Server creates a new room, migrates all connected players (preserving display names and device ID associations), and broadcasts `postgame.new_room` with the new room code + JWT for each player. Clients auto-transition to the new lobby without re-entering codes. Players who already exited can rejoin via the new room code manually
- **Protocol source of truth:** Go structs in a `protocol/` package are the canonical message type definitions. Dart classes mirror Go structs field-for-field with a sync comment header (`// SYNC WITH: rackup-server/protocol/messages.go`). No code generation dependency — manual sync with Go as authoritative reference
- **Reconnection protocol:** On client disconnect, server starts 60s timer. Player state (score, items, turn position) preserved in room goroutine. On reconnect, client sends JWT + device ID in WebSocket upgrade request. Server validates, swaps WebSocket connection to existing player slot, sends current game state snapshot. Timer expiry → player marked "left," game continues without them
- **Room-level timeout:** If ALL players in a room disconnect simultaneously (full connection loss), the room goroutine preserves the complete game state for up to 5 minutes. If any player reconnects within 5 minutes, the game resumes from the preserved state. After 5 minutes with zero connected players, the room is terminated — game state is archived for analytics and the room code is released. This is distinct from the per-player 60-second reconnection window and addresses the scenario where an entire group loses connectivity (e.g., bar Wi-Fi drops, group moves to a different area)
- **Error handling:** Typed error messages over WebSocket — `{"action": "error", "payload": {"code": "ROOM_FULL", "message": "Room has reached maximum 8 players"}}`
- **HTTP endpoints:** Minimal REST surface:
  - `POST /rooms` — create room, returns `{roomCode, jwt}`
  - `POST /rooms/:code/join` — join room, returns `{jwt}`
  - `GET /health` — room count, active connections, uptime

### Client Architecture

- **State management:** 7 Bloc instances per active game session:
  - `WebSocketCubit` — connection lifecycle, message deserialization, dispatches to blocs. On `game.turn_complete`, unpacks the atomic message and dispatches relevant slices to each bloc in a single synchronous pass for visual consistency
  - `RoomBloc` — lobby state, player list, room lifecycle (joining, waiting, started, ended)
  - `GameBloc` — turn state, current shooter, round tracking, triple-points mode
  - `RefereeBloc` — referee state machine (6+ states), authority tracking
  - `LeaderboardBloc` — scores, rankings, streaks, position change animations
  - `ItemBloc` — held item, deployment, incoming effects, fizzle handling
  - `EventFeedCubit` — cascade event narration on player screen (max 4 visible entries, 2-second minimum hold). Fed by `WebSocketCubit` from turn complete, item deployed, and system events. Lightweight cubit (list of recent events), not a full Bloc
- **Cascade timing controller:** Client-side component that sequences the visual output of a `game.turn_complete` message. The server includes a `cascadeProfile` field indicating moment significance (`routine`, `streak_milestone`, `item_punishment`, `spicy`, `record_this`). The controller selects timing: instant for routine makes, 500ms build for streak milestones, 1-2s for item+punishment, 3-5s storm pause for RECORD THIS moments. Implemented as a helper class consumed by the game-feature widgets, not a Bloc
- **Item deployment fizzle pattern:** Item deployment uses an optimistic-then-confirm strategy. Client starts the targeting animation and Eruption immediately on user tap. The animation duration (~500ms) masks server confirmation latency. If the server confirms: impact frame plays. If the server rejects (race condition, item already consumed): animation resolves as a "fizzle" — `ItemBloc` receives `ItemFizzled` event, and `WebSocketCubit` also dispatches the fizzle to `EventFeedCubit` (event feed shows "[Item] fizzled!") and `LeaderboardBloc` (acknowledges no-change for visual consistency). The fizzle is a fun game moment, not error rollback
- **`RackUpGameTheme`:** Cross-cutting theme class that takes game progression percentage and returns the active visual set — background color, particle preset, copy intensity tier, glow intensity. Passed down via `InheritedWidget` (not Bloc — it's a read-only derived value that changes at most 4 times per game on tier transitions, no event/state ceremony needed). Every widget references this for escalation-aware rendering. ~20 lines of code driving the entire visual escalation
- **Routing:** `go_router` — declarative routing with built-in deep link support for `rackup.app/join/CODE`
- **Share image:** `RepaintBoundary` + `RenderRepaintBoundary.toImage()` — render report card widget tree to PNG in 9:16 and 1:1 formats. Same widget used for on-screen ceremony and share image capture. One system, two outputs

### Infrastructure & Deployment

- **CI/CD:** GitHub Actions for tests + lint on PR; Railway auto-deploys from main branch
- **Environment config:** Railway environment variables for server (DB URL, JWT secret). Flutter flavors (dev/staging/prod) from Very Good CLI for API endpoint switching. `.env` for local dev only, never committed
- **Logging:** Go `slog` (stdlib, structured JSON) → Railway log drain (stdout captured automatically)
- **Error tracking:** Sentry — single dashboard for both Flutter client and Go server. Monitors >99% crash-free session target
- **Health checks:** `/health` endpoint returning room count, active connections, uptime. Railway auto-restarts on health check failure
- **Deployment:** Single Railway instance for MVP. Go compiles to single binary. PostgreSQL as Railway addon

### Decision Impact Analysis

**Implementation Sequence:**
1. Go server scaffold with `/health`, WebSocket upgrade, JWT issuance (`POST /rooms`, `POST /rooms/:code/join`)
2. Room struct + goroutine lifecycle (create, join, disconnect with 60s hold, cleanup)
3. Message protocol — Go structs in `protocol/` package, action routing by namespace
4. Flutter project init (Very Good CLI) + `WebSocketCubit` + `go_router` with deep linking
5. Reconnection protocol (60s hold, JWT validation, connection swap, state snapshot on reconnect)
6. Game logic — consequence chain pipeline in room goroutine, producing atomic `game.turn_complete` messages
7. Bloc architecture — 6 blocs wired to `WebSocketCubit` with synchronous dispatch
8. PostgreSQL schema + `golang-migrate` migrations + async archival drain via buffered channel
9. Sentry integration (Flutter + Go)
10. Share image generation (`RepaintBoundary`)

**Cross-Component Dependencies:**
- JWT auth must exist before WebSocket connections work → blocks everything
- Room goroutine lifecycle must exist before game logic → blocks gameplay
- Message protocol shared between Go and Flutter → define Go structs early, mirror in Dart
- Atomic `game.turn_complete` message design drives both server pipeline output and client bloc dispatch model
- PostgreSQL `session_players` table with `(device_id_hash, session_id)` index must support group identity queries from day one

## Implementation Patterns & Consistency Rules

### Critical Conflict Points Identified

22 areas where AI agents could make different choices, resolved into consistent patterns across 5 categories.

### Naming Patterns

**Database (PostgreSQL):**
- Tables: `snake_case` plural — `sessions`, `session_players`, `session_events`
- Columns: `snake_case` — `device_id_hash`, `created_at`, `room_code`
- Indexes: `idx_{table}_{columns}` — `idx_session_players_device_id_session_id`
- Foreign keys: `fk_{table}_{ref_table}` — `fk_session_players_sessions`

**Go Backend:**
- Files: `snake_case.go` — `room_handler.go`, `game_state.go`
- Packages: single lowercase word — `protocol`, `room`, `game`
- Exported: `PascalCase` — `Room`, `HandleShot`, `TurnComplete`
- Unexported: `camelCase` — `processItemDrop`, `calculateStreak`

**Flutter/Dart:**
- Files: `snake_case.dart` — `web_socket_cubit.dart`, `game_bloc.dart`
- Classes: `PascalCase` — `GameBloc`, `LeaderboardState`
- Variables/functions: `camelCase` — `currentShooter`, `processMessage`
- Bloc events (from server): past tense — `TurnCompleted`, `PlayerJoined`, `ItemReceived`
- Bloc events (user action): imperative — `DeployItem`, `ConfirmShot`, `StartGame`

**JSON Wire Format (cross-boundary contract):**
- `camelCase` for all field names
- Go structs use `json:"camelCase"` struct tags
- Dart deserializes natively without annotations

### Structure Patterns

**Go Backend — Standard Go Layout:**
```
rackup-server/
├── cmd/server/main.go
├── internal/
│   ├── room/          # Room lifecycle, goroutine management
│   ├── game/          # Game logic, consequence chain, items, missions, punishments
│   ├── protocol/      # Message types (canonical source of truth)
│   ├── auth/          # JWT issuance and validation
│   ├── store/         # PostgreSQL persistence, migrations
│   └── testutil/      # Test factories — NewTestRoom(), NewTestPlayer()
├── migrations/        # golang-migrate SQL files
├── go.mod
└── go.sum
```

**Flutter — Feature-Based Organization:**
```
lib/
├── features/
│   ├── lobby/         # Room creation, join, player list, punishment submission
│   ├── game/          # Game screen, referee UI, leaderboard, items
│   └── postgame/      # Report card, ceremony, share image
├── core/
│   ├── websocket/     # WebSocketCubit
│   ├── protocol/      # Wire types (mirrors Go, SYNC comment header)
│   ├── models/        # Shared domain models (Player, Item, Award, GameState)
│   ├── config/        # AppConfig abstraction (per-flavor: apiBaseUrl, wsBaseUrl, sentryDsn)
│   ├── routing/       # go_router configuration, deep links
│   └── audio/         # AudioListener (centralized sound trigger)
└── app.dart

test/
├── helpers/
│   └── factories.dart # Test factories — createTestRoom(), createTestPlayer()
├── features/          # Mirrors lib/features/
└── core/              # Mirrors lib/core/
```

**Protocol vs. Models (critical separation):**
- `core/protocol/` = wire format types for JSON deserialization. Mirror Go's `internal/protocol/` with `// SYNC WITH: rackup-server/internal/protocol/messages.go` header
- `core/models/` = domain objects used in Bloc states and business logic (`Player`, `Item`, `Award`, `LeaderboardEntry`)
- **Rule:** Never use protocol types directly in Bloc states. `WebSocketCubit` converts protocol → model during dispatch. If the server changes a field name, only the protocol layer and mapping change, not every Bloc

**Test Location:**
- Go: `*_test.go` co-located with source (Go convention)
- Flutter: `test/` mirroring `lib/` structure (Very Good CLI default)
- Test factories: `internal/testutil/factories.go` (Go), `test/helpers/factories.dart` (Flutter) — consistent object construction across all test files

### Format Patterns

**WebSocket Action Naming:**
- Format: `{namespace}.{verb_noun}`, all lowercase with underscores
- Examples: `lobby.player_joined`, `game.turn_complete`, `item.deployed`, `item.fizzled`, `postgame.new_room`, `referee.handoff_requested`
- Namespaces: `lobby`, `game`, `referee`, `item`, `postgame`, `system`, `error`

**Date/Time:**
- Server: all timestamps UTC, stored as `timestamptz` in PostgreSQL
- Wire: ISO 8601 — `"2026-03-21T22:47:00Z"`
- Client: convert to local time only for display

**Null Handling:**
- Omit null fields — `json:"fieldName,omitempty"` in Go
- Dart: handle missing fields with defaults in deserialization
- Never send `"field": null`

**Error Response Format:**
```json
{"action": "error", "payload": {"code": "ROOM_FULL", "message": "Room has reached maximum 8 players"}}
```

### Communication Patterns

**Bloc State Pattern:**
- Sealed classes (Dart 3): `GameState` → `GameInitial | GameLobby | GameInProgress | GameEnded`
- Each state carries only relevant data — no nullable fields on a god-state object

**WebSocket Connection States:**
- `WebSocketCubit` states: `Disconnected | Connecting | Connected | Reconnecting`
- UI shows connection status bar only on `Reconnecting`

**Protocol → Model Dispatch Flow:**
1. `WebSocketCubit` receives JSON message from server
2. Deserializes into protocol type (e.g., `TurnCompletePayload`)
3. Maps protocol type to domain models (e.g., extracts `LeaderboardEntry` list, `Item` drop, score changes)
4. Dispatches domain model slices to appropriate Blocs in a single synchronous pass
5. Blocs update their sealed states with domain models, never protocol types

**AudioListener Pattern:**
- Centralized `BlocListener` at the app level — listens to all game blocs and triggers sounds
- No bloc ever calls audio directly
- Single place that decides "this event makes a noise"
- Triggers: Blue Shell impact → `LeaderboardBloc` position change, streak fire → `GameBloc` streak milestone, punishment reveal → `GameBloc` punishment event, leaderboard shuffle → `LeaderboardBloc` ranking change, podium fanfare → postgame ceremony state

**AppConfig Pattern:**
```dart
abstract class AppConfig {
  String get apiBaseUrl;        // HTTP endpoint for room create/join
  String get wsBaseUrl;         // WebSocket endpoint
  bool get enableSentryLogging;
  String get sentryDsn;
}
```
- Dev flavor: `localhost` endpoints, Sentry disabled
- Staging flavor: Railway staging, Sentry enabled
- Prod flavor: Railway production, Sentry enabled
- No hardcoded URLs or DSNs anywhere in the codebase — every agent references `AppConfig`

**Go Error Handling:**
- Custom error types for game logic: `ErrRoomFull`, `ErrNotReferee`, `ErrInvalidAction`
- Errors returned, never panicked
- Game logic errors → client via error action
- Infrastructure errors (DB, WebSocket) → `slog` + Sentry, never sent to client

### Process Patterns

**Validation:**
- Server validates everything — client is untrusted. All game actions validated server-side before state changes
- Client validates for UX only — prevent invalid UI states, never trust for game logic

**Retry Patterns:**
- WebSocket reconnection: exponential backoff (1s, 2s, 4s, 8s, max 16s) for up to 60 seconds, then "Connection Lost" screen
- HTTP (room create/join): single retry on network error, then show error to user

**Logging Levels (Go `slog`):**
- `Debug`: message payloads, state transitions (local dev only)
- `Info`: room created, player joined, game started, game ended
- `Warn`: reconnection attempts, invalid actions rejected, timeouts
- `Error`: WebSocket failures, DB write failures, panics recovered

### Enforcement Guidelines

**All AI Agents MUST:**
- Follow naming conventions exactly as specified — no exceptions for "readability" or "preference"
- Use the canonical Go `internal/protocol/` package as the source of truth for message types; Dart `core/protocol/` mirrors with `// SYNC WITH:` header
- Separate protocol types (wire format) from domain models — never use protocol types in Bloc states
- Never put game logic validation on the client only — server-authoritative means server validates
- Use the established Bloc event naming (past tense for server events, imperative for user actions)
- Place code in the correct feature directory — no cross-feature imports except through `core/`
- Use test factories from `testutil`/`test/helpers/` — never construct test objects ad-hoc
- Trigger sounds only through the `AudioListener` — no direct audio calls from blocs
- Reference `AppConfig` for all environment-specific values — no hardcoded URLs or DSNs

**Anti-Patterns to Avoid:**
- `snake_case` in JSON fields (use `camelCase`)
- Nullable god-state objects in Blocs (use sealed classes)
- Client-side game logic that isn't also validated server-side
- `print()` or `fmt.Println()` for logging (use `slog` / Sentry)
- Direct PostgreSQL calls in the game hot path (cold path only, async drain)
- Protocol types in Bloc states (use domain models from `core/models/`)
- Scattered audio calls from individual blocs (use `AudioListener`)
- Hardcoded URLs, DSNs, or environment-specific values (use `AppConfig`)

## Project Structure & Boundaries

### Complete Project Directory Structure

**Go Backend (`rackup-server/`):**
```
rackup-server/
├── ARCHITECTURE.md                    # Pointer to _bmad-output/planning-artifacts/architecture.md
├── cmd/
│   └── server/
│       └── main.go                    # Entry point, HTTP server, WebSocket upgrade, graceful shutdown
├── internal/
│   ├── auth/
│   │   ├── jwt.go                     # JWT issuance (HS256), validation, claims extraction
│   │   └── jwt_test.go
│   ├── room/
│   │   ├── room.go                    # Room struct, goroutine lifecycle, player management, cross-package orchestrator
│   │   ├── manager.go                 # Room registry, code generation (4-char alpha), room lookup
│   │   ├── connection.go              # WebSocket connection wrapper, disconnect detection, reconnection swap
│   │   ├── room_test.go
│   │   ├── manager_test.go
│   │   └── connection_test.go
│   ├── game/
│   │   ├── engine.go                  # Consequence chain pipeline, turn processing
│   │   ├── scoring.go                 # Points, streaks, triple-points, leaderboard calculation
│   │   ├── item_effect.go             # ItemEffect interface definition + item registry
│   │   ├── items/                     # Per-item implementations (one file per item)
│   │   │   ├── blue_shell.go
│   │   │   ├── shield.go
│   │   │   ├── score_steal.go
│   │   │   ├── streak_breaker.go
│   │   │   ├── double_up.go
│   │   │   ├── trap_card.go
│   │   │   ├── reverse.go
│   │   │   ├── immunity.go
│   │   │   ├── mulligan.go
│   │   │   └── wildcard.go
│   │   ├── missions.go                # Mission assignment (33% probability), deck, validation
│   │   ├── punishments.go             # Punishment deck, percentage-based escalation, custom mixing
│   │   ├── referee.go                 # Referee authority tracking, rotation, handoff, failover
│   │   ├── engine_test.go
│   │   ├── scoring_test.go
│   │   ├── items_test.go              # Tests for item registry + drop logic
│   │   ├── items/
│   │   │   ├── blue_shell_test.go
│   │   │   ├── shield_test.go
│   │   │   └── ...                    # Per-item tests
│   │   ├── missions_test.go
│   │   ├── punishments_test.go
│   │   └── referee_test.go
│   ├── protocol/
│   │   ├── messages.go                # Canonical message types (all namespaces)
│   │   ├── actions.go                 # Action string constants (lobby.*, game.*, referee.*, etc.)
│   │   └── errors.go                  # Error code constants (ROOM_FULL, NOT_REFEREE, etc.)
│   ├── store/
│   │   ├── postgres.go                # PostgreSQL connection, query methods
│   │   ├── sessions.go                # Session archival (async drain)
│   │   ├── analytics.go               # Group identity queries, event tracking
│   │   └── postgres_test.go
│   ├── handler/
│   │   ├── http.go                    # POST /rooms, POST /rooms/:code/join, GET /health
│   │   ├── websocket.go               # WebSocket upgrade, JWT validation, room routing
│   │   └── http_test.go
│   └── testutil/
│       └── factories.go               # NewTestRoom(), NewTestPlayer(), NewTestGameState()
├── migrations/
│   ├── 001_create_sessions.up.sql
│   ├── 001_create_sessions.down.sql
│   ├── 002_create_session_players.up.sql
│   ├── 002_create_session_players.down.sql
│   ├── 003_create_session_events.up.sql
│   ├── 003_create_session_events.down.sql
│   ├── 004_create_group_sessions_view.up.sql   # Convenience view for 7-Day Group Return KPI queries
│   └── 004_create_group_sessions_view.down.sql
├── .env.example
├── .gitignore
├── go.mod
├── go.sum
└── Dockerfile                         # Multi-stage build for Railway
```

**Flutter Client (`rackup/`):**
```
rackup/
├── ARCHITECTURE.md                    # Pointer to _bmad-output/planning-artifacts/architecture.md
├── lib/
│   ├── app.dart                       # App widget, MaterialApp, AudioListener, go_router
│   ├── features/
│   │   ├── lobby/
│   │   │   ├── bloc/
│   │   │   │   ├── room_bloc.dart             # Room lifecycle + punishment submission (lobby phase)
│   │   │   │   ├── room_event.dart
│   │   │   │   └── room_state.dart
│   │   │   └── view/
│   │   │       ├── create_room_page.dart      # Host creates room, gets code
│   │   │       ├── join_room_page.dart         # Guest enters code + display name
│   │   │       ├── lobby_page.dart             # Player list, punishment submission, waiting
│   │   │       └── widgets/
│   │   │           ├── player_list_tile.dart
│   │   │           └── punishment_input.dart
│   │   ├── game/
│   │   │   ├── bloc/
│   │   │   │   ├── game_bloc.dart             # Turn state, round tracking, triple-points
│   │   │   │   ├── game_event.dart
│   │   │   │   ├── game_state.dart
│   │   │   │   ├── referee_bloc.dart          # Referee state machine (6+ states)
│   │   │   │   ├── referee_event.dart
│   │   │   │   ├── referee_state.dart
│   │   │   │   ├── leaderboard_bloc.dart      # Scores, rankings, streak indicators
│   │   │   │   ├── leaderboard_event.dart
│   │   │   │   ├── leaderboard_state.dart
│   │   │   │   ├── item_bloc.dart             # Held item, anytime deployment, fizzle handling
│   │   │   │   ├── item_event.dart
│   │   │   │   ├── item_state.dart
│   │   │   │   ├── event_feed_cubit.dart      # Cascade event narration (max 4 visible, 2s hold)
│   │   │   │   └── event_feed_state.dart
│   │   │   └── view/
│   │   │       ├── game_page.dart             # Main game screen (player view)
│   │   │       ├── referee_page.dart          # Referee command center
│   │   │       └── widgets/
│   │   │           ├── leaderboard_widget.dart     # Animated position-shuffle
│   │   │           ├── event_feed_widget.dart      # Player screen cascade narration
│   │   │           ├── item_card.dart              # Item display + anytime deploy
│   │   │           ├── streak_indicator.dart       # ON FIRE / UNSTOPPABLE badges
│   │   │           ├── mission_overlay.dart         # Secret mission private display
│   │   │           ├── punishment_card.dart          # Punishment display with tier tag
│   │   │           ├── shot_buttons.dart             # MADE IT / MISSED (referee)
│   │   │           ├── undo_button.dart              # 5-second undo (referee)
│   │   │           ├── record_this_prompt.dart       # "RECORD THIS" overlay
│   │   │           └── turn_announcement.dart        # Current shooter display
│   │   └── postgame/
│   │       ├── bloc/
│   │       │   ├── postgame_bloc.dart          # Ceremony flow, award calculation
│   │       │   ├── postgame_event.dart
│   │       │   └── postgame_state.dart
│   │       └── view/
│   │           ├── ceremony_page.dart          # Podium reveal (3rd → 2nd → 1st)
│   │           ├── report_card_page.dart       # Awards, stats, share button
│   │           └── widgets/
│   │               ├── podium_widget.dart
│   │               ├── award_card.dart
│   │               ├── share_image_builder.dart     # RepaintBoundary capture (9:16 + 1:1)
│   │               └── feedback_prompt.dart          # Referee satisfaction thumbs up/down
│   ├── core/
│   │   ├── websocket/
│   │   │   ├── web_socket_cubit.dart          # Connection lifecycle, message dispatch
│   │   │   ├── web_socket_state.dart          # Disconnected | Connecting | Connected | Reconnecting
│   │   │   └── reconnection_handler.dart      # Exponential backoff (1s→16s), 60s timeout
│   │   ├── protocol/
│   │   │   ├── messages.dart                  # Wire types — SYNC WITH: rackup-server/internal/protocol/messages.go
│   │   │   ├── actions.dart                   # Action constants — SYNC WITH: rackup-server/internal/protocol/actions.go
│   │   │   ├── errors.dart                    # Error constants — SYNC WITH: rackup-server/internal/protocol/errors.go
│   │   │   └── mapper.dart                    # Protocol → Model conversion (Dart-only)
│   │   ├── models/
│   │   │   ├── player.dart                    # Player domain model
│   │   │   ├── game_state.dart                # Game state domain model
│   │   │   ├── item.dart                      # Item domain model
│   │   │   ├── leaderboard_entry.dart         # Leaderboard entry domain model
│   │   │   ├── mission.dart                   # Mission domain model
│   │   │   ├── punishment.dart                # Punishment domain model
│   │   │   └── award.dart                     # Award domain model (MVP, Sharpshooter, etc.)
│   │   ├── config/
│   │   │   ├── app_config.dart                # Abstract AppConfig
│   │   │   ├── dev_config.dart                # localhost endpoints
│   │   │   ├── staging_config.dart            # Railway staging
│   │   │   └── prod_config.dart               # Railway production
│   │   ├── routing/
│   │   │   └── app_router.dart                # go_router config, deep link handling
│   │   ├── theme/
│   │   │   └── game_theme.dart                # RackUpGameTheme — escalation palette, particle preset, copy tier
│   │   ├── cascade/
│   │   │   └── cascade_controller.dart        # Client-side cascade timing (routine → record_this profiles)
│   │   └── audio/
│   │       ├── audio_listener.dart            # Centralized BlocListener for sound triggers
│   │       └── sound_manager.dart             # Preload, play, respect silent mode
├── assets/
│   └── sounds/
│       ├── blue_shell_impact.mp3
│       ├── leaderboard_shuffle.mp3
│       ├── punishment_reveal.mp3
│       ├── streak_fire.mp3
│       └── podium_fanfare.mp3
├── test/
│   ├── helpers/
│   │   ├── factories.dart                     # createTestRoom(), createTestPlayer(), etc.
│   │   └── pump_app.dart                      # Very Good CLI test helper
│   ├── features/
│   │   ├── lobby/
│   │   ├── game/
│   │   └── postgame/
│   └── core/
│       ├── websocket/
│       ├── protocol/
│       └── models/
├── .github/
│   └── workflows/
│       └── ci.yml                             # Flutter test + lint on PR
├── pubspec.yaml
├── analysis_options.yaml                      # Very Good CLI lint rules
└── .gitignore
```

### Architectural Boundaries

**API Boundaries (HTTP):**
- `POST /rooms` → `handler/http.go` → `room/manager.go` (create room) → `auth/jwt.go` (issue JWT) → response `{roomCode, jwt}`
- `POST /rooms/:code/join` → `handler/http.go` → `room/manager.go` (find room, add player) → `auth/jwt.go` (issue JWT) → response `{jwt}`
- `GET /health` → `handler/http.go` → `room/manager.go` (room count, connection count)

**WebSocket Boundary:**
- `handler/websocket.go` — upgrade HTTP → WebSocket, validate JWT, extract claims, route to room goroutine
- All game actions flow through the room goroutine — no direct client-to-client communication
- Server is the sole authority; clients render received state

**Data Boundary:**
- `internal/game/` — pure game logic, no database awareness. Operates on in-memory state only
- `internal/store/` — sole database access layer. Called only from room goroutine's post-game archival path (buffered channel drain)
- `internal/room/` — orchestrates game engine + connection management. Calls `store/` for archival only after game ends

**Client Boundary:**
- `core/` — shared infrastructure, no feature-specific logic
- `features/` — feature-specific blocs and views, can import from `core/` but never from other features
- `core/protocol/` → `core/models/` — wire types never cross into blocs or views; `mapper.dart` converts at the boundary

**Cross-Package Orchestration Rule:**
- The room goroutine (`room/room.go`) is the **sole orchestrator** of all cross-package flows
- No package calls another package directly — all coordination flows through the room
- Examples:
  - **Mid-game join (FR6):** `room.go` receives join → calls `scoring.go` for catch-up score → inserts into turn rotation → broadcasts update
  - **Referee failover (FR25):** `room.go` detects referee disconnect → selects next in rotation → transfers authority → broadcasts new referee
  - **Reconnection (FR60):** `room.go` validates JWT on reconnect → swaps connection → sends state snapshot
  - **Anytime item deployment:** `room.go` receives `item.deploy` → validates ownership → queues if mid-cascade → executes via `item_effect.go` → broadcasts result
  - **Play Again:** `room.go` receives `postgame.play_again` → creates new room via `manager.go` → migrates players → issues new JWTs → broadcasts new room info → shuts down old room after archival
  - **Post-game archival:** `room.go` gathers final state → pushes to store channel

### Item Effect Interface Pattern

```go
// internal/game/item_effect.go
type ItemEffect interface {
    Execute(state *GameState, user *Player, target *Player) (*EffectResult, error)
    RequiresTarget() bool
    RequiresVote() bool
}
```

- Each item is a separate file in `internal/game/items/` implementing `ItemEffect`
- `item_effect.go` contains the interface definition + item registry (maps item type → implementation)
- Drop logic (probability, rubber banding) lives in `item_effect.go`
- Adding a new item = adding a new file implementing `ItemEffect` + registering it
- 4 execution patterns covered by the interface: instant (`RequiresTarget: false, RequiresVote: false`), persistent (same, effect tracked in player state), targeted (`RequiresTarget: true`), group-vote (`RequiresVote: true`)
- **Anytime deployment:** Items are deployable at any point during active gameplay (UX spec override of PRD FR35). The room goroutine accepts `item.deploy` actions from any player, not just the current shooter. If a deployment arrives mid-cascade, it queues behind the active cascade to prevent state corruption. The server validates item ownership and returns an error action if the item was already consumed (race condition) — the client renders this as a "fizzle" animation

### RoomBloc Scope (Flutter)

- `RoomBloc` manages **both** the player list AND punishment submission during the lobby phase
- States: `RoomInitial | RoomCreating | RoomJoining | RoomLobby(players, punishmentStatus) | RoomStarting | RoomInGame | RoomEnded`
- `RoomLobby` state carries: list of connected players, each player's punishment submission status, whether all punishments are submitted or timeout elapsed
- Once the game starts, `RoomBloc` transitions to `RoomInGame` and game-specific blocs take over

### Requirements to Structure Mapping

| FR Domain | Go Package | Flutter Feature | Key Files | Orchestrator |
|-----------|-----------|-----------------|-----------|-------------|
| Room & Multiplayer (FR1-11) | `room/`, `handler/`, `auth/` | `lobby/` | `room.go`, `manager.go`, `jwt.go`, `room_bloc.dart` | `room.go` |
| Game Flow (FR12-17) | `game/engine.go` | `game/` | `engine.go`, `game_bloc.dart` | `room.go` |
| Referee System (FR18-25) | `game/referee.go` | `game/` | `referee.go`, `referee_bloc.dart` | `room.go` |
| Scoring & Streaks (FR26-31) | `game/scoring.go` | `game/` | `scoring.go`, `leaderboard_bloc.dart` | `room.go` |
| Items (FR32-36j, FR35 updated per UX spec: anytime deploy) | `game/item_effect.go`, `game/items/*.go` | `game/` | item files, `item_bloc.dart`, `cascade_controller.dart` | `room.go` |
| Missions (FR37-40) | `game/missions.go` | `game/` | `missions.go`, `mission_overlay.dart` | `room.go` |
| Punishments (FR41-44) | `game/punishments.go` | `game/` | `punishments.go`, `punishment_card.dart` | `room.go` |
| Leaderboard (FR45-49) | `game/scoring.go` | `game/` | `leaderboard_bloc.dart`, `leaderboard_widget.dart` | `room.go` |
| Post-Game (FR50-56) + Play Again | `game/engine.go`, `room/manager.go` | `postgame/` | `ceremony_page.dart`, `share_image_builder.dart` | `room.go` |
| Connectivity (FR57-61) | `room/connection.go` | `core/websocket/` | `connection.go`, `web_socket_cubit.dart` | `room.go` |
| Analytics (FR62-68) | `store/analytics.go` | N/A (server-side) | `analytics.go`, `sessions.go` | `room.go` → `store/` channel |

### Integration Points & Data Flow

**Game Turn Data Flow (hot path):**
```
Referee taps MADE/MISSED
  → Flutter: RefereeBloc emits ConfirmShot event
  → WebSocketCubit sends {"action": "referee.confirm_shot", "payload": {...}}
  → Go: handler/websocket.go routes to room goroutine
  → Go: room.go validates referee authority
  → Go: game/engine.go runs consequence chain pipeline:
       scoring.go → item_effect.go → items/*.go → punishments.go → scoring.go (leaderboard recalc)
  → Go: room.go broadcasts {"action": "game.turn_complete", "payload": {ALL consequences}}
  → Flutter: WebSocketCubit deserializes TurnCompletePayload (protocol type)
  → Flutter: mapper.dart converts to domain models
  → Flutter: WebSocketCubit dispatches slices to GameBloc, LeaderboardBloc, ItemBloc (synchronous)
  → Flutter: AudioListener triggers appropriate sound
  → Flutter: Widgets rebuild from new Bloc states
```

**Post-Game Archival (cold path):**
```
Game ends
  → Go: room.go calls game/engine.go to compute awards (MVP, Sharpshooter, etc.)
  → Go: room.go sends {"action": "postgame.ceremony_ready", "payload": {...}}
  → Go: room.go pushes session data to buffered channel
  → Go: store/sessions.go background goroutine drains channel → PostgreSQL INSERT
  → Go: store/analytics.go writes session_players rows + session_events
```

**Play Again Flow (post-game → new lobby):**
```
Host taps "Play Again"
  → Flutter: RoomBloc emits PlayAgain event
  → WebSocketCubit sends {"action": "postgame.play_again"}
  → Go: room.go pushes session data to buffered archival channel FIRST (ensures game data persists before migration)
  → Go: room.go creates new room via manager.go (new code, new goroutine)
  → Go: room.go migrates connected players to new room (preserves display names, device ID associations)
  → Go: room.go issues new JWTs for each player in new room
  → Go: broadcasts {"action": "postgame.new_room", "payload": {"roomCode": "WXYZ", "jwt": "..."}} to each player
  → Go: room.go re-routes existing WebSocket connections to new room goroutine (no new handshake — reuses open connections)
  → Flutter: WebSocketCubit receives new JWT + room context, RoomBloc transitions to RoomLobby (feels instant — no reconnection)
  → Old room goroutine shuts down after archival channel push confirmed
```

**Item Deployment (parallel event during gameplay):**
```
Player taps item card (anytime during active game)
  → Flutter: ItemBloc emits DeployItem event, starts optimistic targeting/eruption animation
  → WebSocketCubit sends {"action": "item.deploy", "payload": {"item": "blue_shell", "targetId": "..."}}
  → Go: room.go validates item ownership + game state
  → If mid-cascade: queues item effect behind active cascade
  → Go: room.go executes item effect via ItemEffect.Execute()
  → Go: broadcasts {"action": "item.deployed", "payload": {effect result, updated leaderboard}}
  → Flutter: WebSocketCubit dispatches to ItemBloc (confirmation) + EventFeedCubit (narration) + LeaderboardBloc (updated rankings)
  → Flutter: ItemBloc receives ItemDeployed → impact animation plays
  → If rejected: {"action": "item.fizzled", "payload": {"item": "blue_shell", "reason": "ITEM_CONSUMED"}}
  → Flutter: WebSocketCubit dispatches fizzle to ItemBloc (fizzle animation) + EventFeedCubit ("[Item] fizzled!") + LeaderboardBloc (no-change ack)
```

**External Integrations:**
- **Sentry:** Flutter SDK (client errors/crashes) + Go SDK (server errors) → Sentry dashboard
- **App Store / Google Play:** Flutter build → store submission
- **Railway:** Go binary deployment + PostgreSQL addon
- **Device share sheet:** Flutter `share_plus` package → native OS share

### Development Workflow

**Local Development:**
- Go server: `go run cmd/server/main.go` with `.env` pointing to local PostgreSQL
- Flutter: `flutter run --flavor development` pointing to `localhost` via `DevConfig`
- Database: Local PostgreSQL or Railway dev database

**CI (GitHub Actions):**
- On PR: `go test ./...` + `flutter test` + `flutter analyze`
- On merge to main: Railway auto-deploys Go server

**Deployment:**
- Go: Railway detects `go.mod`, builds, runs binary. `PORT` from Railway env
- Flutter: Manual build → `flutter build ios` / `flutter build appbundle` → store submission
- Database: Railway PostgreSQL addon, migrations run via `golang-migrate` on deploy
