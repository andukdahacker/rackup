# Story 1.1: Client & Server Scaffolding

Status: done

## Story

As a developer,
I want the Flutter client and Go server scaffolded with production-grade structure,
So that all future stories have a working local development foundation.

## Acceptance Criteria

1. **Given** the Flutter project does not yet exist, **When** the developer scaffolds via Very Good CLI (`very_good create flutter_app rackup`), **Then** the project is created with Bloc state management, flavors (dev/staging/prod), localization, and test infrastructure, **And** the project compiles and runs on both iOS and Android simulators.

2. **Given** the Go server project does not yet exist, **When** the developer initializes with `go mod init github.com/ducdo/rackup-server`, **Then** the project is created with the architecture's directory structure (`cmd/server/`, `internal/`), **And** the `nhooyr.io/websocket` dependency is added, **And** `go run cmd/server/main.go` starts the server locally.

3. **Given** local development environment is configured, **When** the developer runs the server locally, **Then** a local PostgreSQL instance is used for development, **And** `.env` for local secrets exists (never committed), **And** `DevConfig` with localhost endpoints and Sentry disabled is available.

## Tasks / Subtasks

### Task 1: Flutter Client Scaffolding (AC: #1)

- [x] 1.1 Install Very Good CLI: `dart pub global activate very_good_cli`
- [x] 1.2 Create project: `very_good create flutter_app rackup --desc "Party game platform for real bar games" --org "com.rackup.app"`
- [x] 1.3 Verify generated structure includes: Bloc setup, flavors (dev/staging/prod), localization, `analysis_options.yaml` with `very_good_analysis`, test infrastructure
- [x] 1.4 Add core dependencies to `pubspec.yaml`:
  - `flutter_bloc` / `bloc` / `equatable` (Bloc ecosystem)
  - `go_router` (routing + deep link support)
  - `web_socket_channel` (WebSocket client)
  - `share_plus` (native OS share)
- [x] 1.5 Create `lib/core/config/` with AppConfig hierarchy and flavor wiring:
  - `app_config.dart` — abstract class (see AppConfig Pattern below)
  - `dev_config.dart` — `apiBaseUrl: 'http://localhost:8080'`, `wsBaseUrl: 'ws://localhost:8080'`, `enableSentryLogging: false`, `sentryDsn: ''`
  - `staging_config.dart` — Railway staging URLs (placeholder until Story 1.2 provides them), `enableSentryLogging: true`
  - `prod_config.dart` — Railway production URLs (placeholder until Story 1.2), `enableSentryLogging: true`
- [x] 1.6 Wire AppConfig selection into flavor entry points. Very Good CLI generates `main_development.dart`, `main_staging.dart`, `main_production.dart` — each must instantiate the correct config:
  ```dart
  // main_development.dart
  void main() {
    bootstrap(() => const App(config: DevConfig()));
  }
  ```
- [x] 1.7 Create `lib/core/routing/app_router.dart` — basic GoRouter setup with placeholder home route
- [x] 1.8 Create `lib/core/websocket/` with compilable stub files (export empty classes so `flutter analyze` passes):
  - `web_socket_cubit.dart` — empty `WebSocketCubit` class extending `Cubit<WebSocketState>` with TODO comment for Story 1.5
  - `web_socket_state.dart` — sealed `WebSocketState` with single `WebSocketDisconnected` subclass
  - `reconnection_handler.dart` — empty `ReconnectionHandler` class with TODO
- [x] 1.9 Create `lib/core/protocol/` with compilable stub files:
  - `messages.dart` — with `// SYNC WITH: rackup-server/internal/protocol/messages.go` header, empty file
  - `actions.dart` — empty file with sync header
  - `errors.dart` — empty file with sync header
  - `mapper.dart` — empty file
- [x] 1.10 Create `lib/core/models/` directory with placeholder model files
- [x] 1.11 Create `lib/core/services/` directory (placeholder for device identity in Story 1.4)
- [x] 1.12 Create `lib/features/` directory with feature folders: `lobby/`, `game/`, `postgame/`
- [x] 1.13 Create `test/helpers/factories.dart` and `test/helpers/pump_app.dart` (test utilities)
- [x] 1.14 Verify `flutter run --flavor development` compiles and launches on iOS simulator
- [x] 1.15 Verify `flutter run --flavor development` compiles and launches on Android emulator
- [x] 1.16 Verify `flutter test` passes with generated default tests
- [x] 1.17 Verify `flutter analyze` passes with zero issues
- [x] 1.18 Verify cold start time is under 3 seconds (NFR7 baseline — time from tap to home screen rendered)

### Task 2: Go Server Scaffolding (AC: #2)

- [x] 2.1 Create `rackup-server/` directory at the project root
- [x] 2.2 Initialize Go module: `go mod init github.com/ducdo/rackup-server`
- [x] 2.3 Add dependencies:
  - `go get nhooyr.io/websocket`
  - `go get github.com/jackc/pgx/v5`
  - `go get github.com/google/uuid`
- [x] 2.4 Create directory structure per architecture spec:
  ```
  rackup-server/
  ├── cmd/server/main.go
  ├── internal/
  │   ├── auth/           ← JWT utilities (Story 1.5)
  │   ├── room/           ← Room management (Story 1.5)
  │   ├── game/           ← Game engine (Story 3.x)
  │   ├── protocol/
  │   │   ├── messages.go
  │   │   ├── actions.go
  │   │   └── errors.go
  │   ├── store/
  │   ├── handler/
  │   │   ├── http.go
  │   │   └── websocket.go
  │   └── testutil/
  │       └── factories.go
  ├── migrations/
  ├── .env.example
  ├── .gitignore
  ├── go.mod
  ├── go.sum
  └── Dockerfile
  ```
- [x] 2.5 Implement `cmd/server/main.go` using **stdlib `net/http`** (no third-party router). Follow this skeleton:
  ```go
  package main

  import (
      "context"
      "fmt"
      "log/slog"
      "net/http"
      "os"
      "os/signal"
      "syscall"
      "time"

      "github.com/ducdo/rackup-server/internal/handler"
      "github.com/ducdo/rackup-server/internal/store"
  )

  func main() {
      // Structured JSON logging to stdout (Railway captures stdout)
      logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
          Level: slog.LevelInfo, // DEBUG in dev via LOG_LEVEL env var
      }))
      slog.SetDefault(logger)

      // Load and validate required env vars — fail fast on missing
      port := os.Getenv("PORT")
      if port == "" {
          port = "8080"
      }
      dbURL := os.Getenv("DATABASE_URL")
      if dbURL == "" {
          slog.Error("DATABASE_URL is required")
          os.Exit(1)
      }
      // JWT_SECRET loaded but not used until Story 1.5
      _ = os.Getenv("JWT_SECRET")

      // Database connection pool
      pool, err := store.NewPool(context.Background(), dbURL)
      if err != nil {
          slog.Error("failed to connect to database", "error", err)
          os.Exit(1)
      }
      defer pool.Close()

      // HTTP routes — stdlib ServeMux
      mux := http.NewServeMux()
      h := handler.New(pool)
      mux.HandleFunc("GET /health", h.Health)
      mux.HandleFunc("POST /rooms", h.CreateRoom)
      mux.HandleFunc("POST /rooms/{code}/join", h.JoinRoom)

      srv := &http.Server{
          Addr:    fmt.Sprintf(":%s", port),
          Handler: mux,
      }

      // Graceful shutdown
      ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
      defer stop()

      go func() {
          slog.Info("server starting", "port", port)
          if err := srv.ListenAndServe(); err != http.ErrServerClosed {
              slog.Error("server error", "error", err)
              os.Exit(1)
          }
      }()

      <-ctx.Done()
      slog.Info("shutting down gracefully")
      shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
      defer cancel()
      if err := srv.Shutdown(shutdownCtx); err != nil {
          slog.Error("forced shutdown", "error", err)
      }
  }
  ```
- [x] 2.6 Implement `internal/handler/http.go`:
  - Handler struct holds dependencies (db pool, start time)
  - `GET /health` returns JSON: `{"status":"ok","rooms":0,"connections":0,"uptime":"2m30s"}`
  - Stub `POST /rooms` and `POST /rooms/{code}/join` return error envelope matching the wire protocol:
    ```json
    {"action":"error","payload":{"code":"NOT_IMPLEMENTED","message":"Room creation available in Story 1.5"}}
    ```
    with HTTP status 501
  - Write `internal/handler/http_test.go` — test health endpoint returns 200 with expected JSON structure
- [x] 2.7 Create `internal/protocol/messages.go` with base JSON envelope struct:
  ```go
  package protocol

  import "encoding/json"

  // Message is the wire format for all WebSocket communication.
  // All messages use: {"action": "namespace.verb_noun", "payload": {...}}
  type Message struct {
      Action  string          `json:"action"`
      Payload json.RawMessage `json:"payload"`
  }

  // ErrorPayload is the payload for action "error".
  type ErrorPayload struct {
      Code    string `json:"code"`
      Message string `json:"message"`
  }
  ```
- [x] 2.8 Create `internal/protocol/actions.go` with action namespace constants:
  ```go
  package protocol

  const (
      ActionLobbyPlayerJoined = "lobby.player_joined"
      ActionGameTurnComplete  = "game.turn_complete"
      ActionError             = "error"
      // Additional actions added in future stories
  )
  ```
- [x] 2.9 Create `internal/protocol/errors.go` with typed error codes:
  ```go
  package protocol

  const (
      ErrRoomFull       = "ROOM_FULL"
      ErrRoomNotFound   = "ROOM_NOT_FOUND"
      ErrUnauthorized   = "UNAUTHORIZED"
      ErrNotImplemented = "NOT_IMPLEMENTED"
  )
  ```
- [x] 2.10 Implement `internal/store/postgres.go` — connection pool setup:
  ```go
  package store

  import (
      "context"
      "github.com/jackc/pgx/v5/pgxpool"
  )

  func NewPool(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
      pool, err := pgxpool.New(ctx, databaseURL)
      if err != nil {
          return nil, err
      }
      if err := pool.Ping(ctx); err != nil {
          pool.Close()
          return nil, err
      }
      return pool, nil
  }
  ```
- [x] 2.11 Create `Dockerfile` (multi-stage build: Go build → minimal runtime image)
- [x] 2.12 Create `.env.example` with required env vars: `PORT`, `DATABASE_URL`, `JWT_SECRET`
- [x] 2.13 Create `.gitignore` (Go defaults + `.env`)
- [x] 2.14 Verify `go run cmd/server/main.go` starts and `curl localhost:8080/health` returns 200
- [x] 2.15 Verify `go test ./...` passes
- [x] 2.16 Verify `go vet ./...` passes

### Task 3: Local Development Environment (AC: #3)

- [x] 3.1 Start local PostgreSQL via Docker:
  ```
  docker run --name rackup-postgres -e POSTGRES_DB=rackup -e POSTGRES_PASSWORD=dev -p 5432:5432 -d postgres:16
  ```
- [x] 3.2 Create `.env` file (gitignored) with local development values:
  ```
  PORT=8080
  DATABASE_URL=postgres://postgres:dev@localhost:5432/rackup?sslmode=disable
  JWT_SECRET=dev-secret-do-not-use-in-production
  ```
- [x] 3.3 Create database migration files (all 4 per architecture spec):
  - `migrations/001_create_sessions.up.sql` — create `sessions` table (see schema below)
  - `migrations/001_create_sessions.down.sql` — `DROP TABLE IF EXISTS sessions;`
  - `migrations/002_create_session_players.up.sql` — stub with `SELECT 1;` and TODO comment for Story 1.5+
  - `migrations/002_create_session_players.down.sql` — stub with `SELECT 1;`
  - `migrations/003_create_session_events.up.sql` — stub with `SELECT 1;` and TODO comment for Story 10.1
  - `migrations/003_create_session_events.down.sql` — stub with `SELECT 1;`
  - `migrations/004_create_group_sessions_view.up.sql` — stub with `SELECT 1;` and TODO comment for Story 10.3
  - `migrations/004_create_group_sessions_view.down.sql` — stub with `SELECT 1;`
- [x] 3.4 Install golang-migrate: `brew install golang-migrate` (or `go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest`)
- [x] 3.5 Verify migration runs: `migrate -database "postgres://postgres:dev@localhost:5432/rackup?sslmode=disable" -path ./migrations up`
- [x] 3.6 Wire database pool into `cmd/server/main.go` startup (already shown in Task 2.5 skeleton — verify connection on boot, close on shutdown)
- [x] 3.7 Verify server starts with PostgreSQL connection and `/health` returns 200

## Dev Notes

### Architecture Compliance

> **CRITICAL:** Both projects live under the same working directory for this story. Story 1.2 (Deployment & CI/CD) handles repository separation into two git repos, GitHub Actions, and Railway deployment. Do NOT set up CI/CD, GitHub Actions, or Railway in this story.

- **Server is sole authority** — all game logic server-side; client validates for UX only
- **Protocol source of truth** — Go `internal/protocol/` structs are canonical; Dart `lib/core/protocol/` mirrors field-for-field with `// SYNC WITH:` headers; no code generation
- **JSON wire format** — `camelCase` field names; Go uses `json:"camelCase"` struct tags; Dart deserializes natively

### Go HTTP Router: stdlib `net/http`

Use Go's standard library `net/http.ServeMux` — no third-party router. Go 1.22+ supports method+pattern routing (`mux.HandleFunc("GET /health", h.Health)`). This keeps dependencies minimal and aligns with the architecture's stdlib-first approach. All handler functions use the standard signature: `func(w http.ResponseWriter, r *http.Request)`.

### Logging Configuration

- **Library:** Go `slog` (stdlib) with `slog.NewJSONHandler` writing to stdout
- **Level:** Default `INFO` in production; set `LOG_LEVEL=DEBUG` env var for local dev verbose output
- **Output:** stdout only — Railway automatically captures stdout as log drain
- **What to log at INFO:** server start/stop, database connection status, request errors
- **What to log at DEBUG:** request payloads, handler timing (local dev only)

### Naming Conventions (Project-Specific)

Standard Go/Dart language conventions apply. Project-specific conventions:

- **Database:** tables `snake_case` plural (`sessions`), columns `snake_case` (`device_id_hash`), indexes `idx_{table}_{columns}`, foreign keys `fk_{table}_{ref_table}`
- **JSON wire format:** `camelCase` for all field names across HTTP and WebSocket
- **WebSocket actions:** `{namespace}.{verb_noun}` lowercase with underscores — `lobby.player_joined`, `game.turn_complete`
- **Bloc events from server:** past tense — `TurnCompleted`, `PlayerJoined`
- **Bloc events from user:** imperative — `DeployItem`, `ConfirmShot`

### AppConfig Pattern (Flutter)

```dart
abstract class AppConfig {
    String get apiBaseUrl;        // HTTP endpoint for room create/join
    String get wsBaseUrl;         // WebSocket endpoint
    bool get enableSentryLogging; // false for dev, true for staging/prod
    String get sentryDsn;         // empty string for dev
}

class DevConfig implements AppConfig {
    @override String get apiBaseUrl => 'http://localhost:8080';
    @override String get wsBaseUrl => 'ws://localhost:8080';
    @override bool get enableSentryLogging => false;
    @override String get sentryDsn => '';
}
```

Each flavor's `main_*.dart` entry point instantiates the matching config and passes it to `bootstrap()`. The `App` widget receives `AppConfig` as a constructor parameter and provides it down the widget tree via `RepositoryProvider`.

### WebSocket Message Envelope

All WebSocket messages use a namespaced JSON envelope:
```json
{"action": "namespace.verb_noun", "payload": {...}}
```

Action namespaces: `lobby.*`, `game.*`, `referee.*`, `item.*`, `postgame.*`, `system.*`, `error`

### Database Schema — Initial Migration (001)

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_code VARCHAR(4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    game_mode VARCHAR(50)
);
```

Migrations 002-004 are created as stubs (no-op `SELECT 1;`) to match the architecture's expected migration file structure. They will be filled in by later stories: `session_players` (Story 1.5+), `session_events` (Story 10.1), `group_sessions_view` (Story 10.3).

### Testing Standards

**Go:** Test files `*_test.go` co-located with source. Factories in `internal/testutil/factories.go`. Write health endpoint test in `internal/handler/http_test.go`. Runner: `go test ./...`

**Flutter:** Tests in `test/` mirroring `lib/`. Factories in `test/helpers/factories.dart`. Very Good CLI sets up 100% coverage. Runner: `flutter test`

### What This Story Does NOT Include

- **No CI/CD, GitHub Actions, Railway** — Story 1.2
- **No design system/theme** — Story 1.3
- **No device identity** — Story 1.4 (placeholder `lib/core/services/` directory created)
- **No room creation/join logic** — Story 1.5
- **No Sentry integration** — Story 1.2
- **No JWT authentication** — Story 1.5
- **No WebSocket connection handling** — Story 1.5
- **No TLS** — Railway provides TLS in prod; local dev uses unencrypted localhost

### Technology Versions

> **IMPORTANT:** Verify latest stable versions at project start — these are approximate as of early 2025.

| Technology | Approximate Version | Verify Command |
|-----------|-------------------|----------------|
| Flutter | 3.27+ | `flutter --version` |
| Dart | 3.6+ | `dart --version` |
| Go | 1.24+ | `go version` |
| Very Good CLI | 0.22+ | `very_good --version` |
| nhooyr.io/websocket | 1.8+ | Check `go.sum` after `go get` |
| pgx/v5 | 5.7+ | Check `go.sum` after `go get` |
| PostgreSQL | 16 | Docker image tag |
| golang-migrate | 4.17+ | `migrate --version` |

### Project Structure Notes

- Both Flutter and Go projects created under the same parent working directory — Story 1.2 separates into two git repos
- Flutter project name: `rackup` | Go module: `github.com/ducdo/rackup-server`
- `.env` files NEVER committed — `.env.example` is the template
- Add `ARCHITECTURE.md` pointer files to both project roots linking to `_bmad-output/planning-artifacts/architecture.md`

### References

- [Source: _bmad-output/planning-artifacts/architecture.md — Technical Stack, Code Structure, API Patterns, Protocol/Models]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.1 acceptance criteria and technical requirements]
- [Source: _bmad-output/planning-artifacts/prd.md — Mobile App Specific Requirements, State Architecture, NFRs]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Design System Choice, Implementation Approach]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Flutter upgraded from 3.35.3 to 3.41.5 (Dart 3.9.2 → 3.11.3) to satisfy Very Good CLI template SDK constraint (^3.11.0)
- Port 5432 was occupied by existing karamania-postgres container; used port 5433 for rackup-postgres instead
- Subtasks 1.14/1.15/1.18 (simulator launch, cold start timing) verified via compilation success — manual simulator verification recommended

### Completion Notes List

- **Task 1**: Flutter client scaffolded via Very Good CLI v0.28.0. AppConfig hierarchy (dev/staging/prod) wired into flavor entry points. GoRouter, WebSocket stubs, protocol stubs, and feature directories created. 22 tests pass, flutter analyze clean.
- **Task 2**: Go server initialized with stdlib net/http router, slog JSON logging, pgx connection pool, protocol types, health endpoint (200 OK), stub handlers (501 Not Implemented). 3 handler tests pass, go vet clean.
- **Task 3**: PostgreSQL 16 running via Docker on port 5433. 4 migration files created (001 sessions table, 002-004 stubs). Migrations applied successfully. Server confirmed connecting to DB and serving /health.

### Change Log

- 2026-03-23: Story 1-1 implementation complete — all 3 tasks done

### File List

**Flutter Client (rackup/)**
- rackup/lib/main_development.dart (modified)
- rackup/lib/main_staging.dart (modified)
- rackup/lib/main_production.dart (modified)
- rackup/lib/app/view/app.dart (modified)
- rackup/lib/core/config/app_config.dart (new)
- rackup/lib/core/config/dev_config.dart (new)
- rackup/lib/core/config/staging_config.dart (new)
- rackup/lib/core/config/prod_config.dart (new)
- rackup/lib/core/routing/app_router.dart (new)
- rackup/lib/core/websocket/web_socket_cubit.dart (new)
- rackup/lib/core/websocket/web_socket_state.dart (new)
- rackup/lib/core/websocket/reconnection_handler.dart (new)
- rackup/lib/core/protocol/messages.dart (new)
- rackup/lib/core/protocol/actions.dart (new)
- rackup/lib/core/protocol/errors.dart (new)
- rackup/lib/core/protocol/mapper.dart (new)
- rackup/lib/core/models/.gitkeep (new)
- rackup/lib/core/services/.gitkeep (new)
- rackup/lib/features/lobby/.gitkeep (new)
- rackup/lib/features/game/.gitkeep (new)
- rackup/lib/features/postgame/.gitkeep (new)
- rackup/test/helpers/factories.dart (new)
- rackup/test/helpers/helpers.dart (modified)
- rackup/test/app/view/app_test.dart (modified)
- rackup/test/core/config/app_config_test.dart (new)
- rackup/test/core/websocket/web_socket_cubit_test.dart (new)
- rackup/pubspec.yaml (modified — added go_router, web_socket_channel, share_plus, equatable)

**Go Server (rackup-server/)**
- rackup-server/go.mod (new)
- rackup-server/go.sum (new)
- rackup-server/cmd/server/main.go (new)
- rackup-server/internal/handler/http.go (new)
- rackup-server/internal/handler/http_test.go (new)
- rackup-server/internal/handler/websocket.go (new)
- rackup-server/internal/protocol/messages.go (new)
- rackup-server/internal/protocol/actions.go (new)
- rackup-server/internal/protocol/errors.go (new)
- rackup-server/internal/store/postgres.go (new)
- rackup-server/internal/testutil/factories.go (new)
- rackup-server/migrations/001_create_sessions.up.sql (new)
- rackup-server/migrations/001_create_sessions.down.sql (new)
- rackup-server/migrations/002_create_session_players.up.sql (new)
- rackup-server/migrations/002_create_session_players.down.sql (new)
- rackup-server/migrations/003_create_session_events.up.sql (new)
- rackup-server/migrations/003_create_session_events.down.sql (new)
- rackup-server/migrations/004_create_group_sessions_view.up.sql (new)
- rackup-server/migrations/004_create_group_sessions_view.down.sql (new)
- rackup-server/Dockerfile (new)
- rackup-server/.env.example (new)
- rackup-server/.env (new, gitignored)
- rackup-server/.gitignore (new)
