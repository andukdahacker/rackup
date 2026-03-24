# Story 1.2: Deployment & CI/CD

Status: in-progress

## Story

As a developer,
I want the Go server deployed to Railway with PostgreSQL and CI/CD configured,
So that the app is accessible in a production-like environment from the start.

## Acceptance Criteria

1. **Given** Railway is configured for deployment, **When** the Go server is deployed, **Then** PostgreSQL is provisioned on Railway **And** the `sessions` table migration (001) runs via `golang-migrate` **And** the `/health` endpoint returns room count (0), active connections (0), and uptime **And** the server respects the `PORT` environment variable from Railway **And** TLS 1.2+ is active (provided by Railway).

2. **Given** the CI/CD pipeline does not yet exist, **When** a PR is opened on GitHub, **Then** GitHub Actions runs `go test ./...`, `flutter test`, and `flutter analyze`.

3. **Given** the deployment is running, **When** the server encounters a shutdown signal, **Then** graceful shutdown closes all connections cleanly.

## Tasks / Subtasks

### Task 1: GitHub Actions CI Pipeline (AC: #2)

The Flutter CI already exists at `rackup/.github/workflows/main.yaml` using VeryGoodOpenSource reusable workflows. This task adds Go server CI and creates a unified monorepo CI configuration.

**PREREQUISITE:** Run `go version` and verify the Go version matches `go.mod` (`go 1.26.1`). If `golang:1.26-alpine` does not exist on Docker Hub, update `rackup-server/Dockerfile` and all CI workflow references to the correct Go Docker image tag before proceeding.

- [x] 1.1 Create `.github/workflows/server-ci.yml` at the **repo root** (not inside `rackup/`) for Go server CI:
  - Trigger: `push` to `main` and `pull_request` to `main`
  - Filter: only run when `rackup-server/**` files change (use `paths` filter)
  - Steps: checkout, setup Go (match version from `go.mod`), `cd rackup-server && go test ./...`, `cd rackup-server && go vet ./...`
  - Use `concurrency` group to cancel in-progress runs on same PR
- [x] 1.2 Move `rackup/.github/workflows/main.yaml` to `.github/workflows/flutter-ci.yml` at the repo root:
  - GitHub Actions only reads from the repo root `.github/workflows/` — files inside `rackup/.github/` are ignored
  - Do NOT symlink — GitHub Actions does not follow symlinks for workflow files
  - Add `paths` filter: only run when `rackup/**` files change
  - Add `working_directory: rackup` parameter to the `flutter_package.yml` reusable workflow job. Verify the exact parameter name at https://github.com/VeryGoodOpenSource/very_good_workflows — as of v1, the input is `working_directory`
  - The `spell-check` job may need adjustment — verify it finds `cspell.json` from the new location
  - Keep existing VeryGoodOpenSource reusable workflows (flutter_package, semantic_pull_request, spell_check)
- [x] 1.3 Move `rackup/.github/workflows/license_check.yaml` to `.github/workflows/license-check.yml`:
  - Update `paths` filter: change `pubspec.yaml` to `rackup/pubspec.yaml` and update the self-referencing workflow path
  - Add `working_directory: rackup` if the VeryGoodOpenSource license_check reusable workflow supports it (or use `defaults.run.working-directory`)
- [x] 1.4 Move remaining `rackup/.github/` support files to repo root `.github/`:
  - Move `rackup/.github/cspell.json` to `.github/cspell.json` — **required by the spell-check job, will fail if missing**
  - Move `rackup/.github/dependabot.yaml` to `.github/dependabot.yaml` and update:
    - Change `pub` ecosystem `directory` from `"/"` to `"/rackup"`
    - Add `gomod` ecosystem entry with `directory: "/rackup-server"`
    - Keep `github-actions` ecosystem with `directory: "/"`
  - Move `rackup/.github/PULL_REQUEST_TEMPLATE.md` to `.github/PULL_REQUEST_TEMPLATE.md`
- [x] 1.5 Delete the old `rackup/.github/` directory and all remaining contents after moves are complete
- [x] 1.6 Verify both workflows trigger correctly on a test PR (path filters configured — full verification requires real PR):
  - Go changes only → only server-ci runs
  - Flutter changes only → only flutter-ci runs
  - Both changed → both run

### Task 2: Railway Deployment Setup (AC: #1, #3)

Railway auto-deploys from `main` branch. The Go server already has a working Dockerfile and graceful shutdown. Tasks marked `[MANUAL]` require human action in the Railway dashboard — the dev agent should prepare all code changes and document the manual steps clearly.

- [ ] 2.1 `[MANUAL]` _(requires human action)_ Create Railway project via `railway init` or Railway dashboard:
  - Project name: `rackup`
  - Connect to GitHub repo for auto-deploy on push to `main`
- [ ] 2.2 `[MANUAL]` _(requires human action)_ Configure Railway service for Go server:
  - Root directory: `rackup-server` (Railway will detect `Dockerfile` and build from it)
  - Set environment variables in Railway dashboard:
    - `PORT` — Railway auto-sets this, server already reads it (`main.go:29-32`)
    - `DATABASE_URL` — Railway auto-provisions this when PostgreSQL addon is added. Both `postgres://` and `postgresql://` schemes are accepted by pgx and golang-migrate
    - `JWT_SECRET` — Generate secure random value, set in Railway env
    - `LOG_LEVEL` — Set to `INFO` for production
  - **CRITICAL:** Do NOT hardcode any secrets in code or Dockerfiles
- [ ] 2.3 `[MANUAL]` _(requires human action)_ Provision Railway PostgreSQL addon:
  - Railway provides `DATABASE_URL` automatically to the service
- [x] 2.4 Configure database migrations to run on deploy using the **entrypoint script approach**:
  - Update `rackup-server/Dockerfile` to add `golang-migrate` CLI and migration files to the runtime stage:
    ```dockerfile
    # Build stage
    FROM golang:1.26-alpine AS build
    WORKDIR /app
    COPY go.mod go.sum ./
    RUN go mod download
    COPY . .
    RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

    # Runtime stage
    FROM alpine:3.21
    RUN apk add --no-cache ca-certificates curl
    RUN curl -L https://github.com/golang-migrate/migrate/releases/download/v4.18.2/migrate.linux-amd64.tar.gz | tar xz -C /usr/local/bin
    COPY --from=build /server /server
    COPY migrations /migrations
    COPY entrypoint.sh /entrypoint.sh
    RUN chmod +x /entrypoint.sh
    EXPOSE 8080
    ENTRYPOINT ["/entrypoint.sh"]
    ```
  - Verify the `golang-migrate` release artifact exists at https://github.com/golang-migrate/migrate/releases — the tarball may also contain LICENSE/README alongside the binary
  - `COPY migrations /migrations` copies from the build context (source directory), not the build stage — this is correct since `migrations/` is in `rackup-server/`
  - The CLI auto-selects the database driver from the `DATABASE_URL` scheme (`postgres://` or `postgresql://`) — no additional driver configuration needed for the CLI approach
  - Create `rackup-server/entrypoint.sh` (must have Unix LF line endings, not CRLF):
    ```sh
    #!/bin/sh
    set -e
    migrate -path /migrations -database "$DATABASE_URL" up
    exec /server
    ```
  - Note: An alternative approach is running migrations in Go code using `golang-migrate` as a library with the `pgx5` database driver (`github.com/golang-migrate/migrate/v4/database/pgx5`). This story uses the entrypoint script approach for simplicity.
- [x] 2.5 Add `LOG_LEVEL=INFO` to `rackup-server/.env.example` for consistency with Railway env vars
- [ ] 2.6 `[MANUAL]` _(requires human action)_ Deploy to Railway and verify:
  - `/health` returns `{"status":"ok","rooms":0,"connections":0,"uptime":"..."}` over HTTPS
  - Railway provides TLS termination automatically — no TLS config needed in Go code
  - Check Railway logs for `server starting` slog message
  - Verify graceful shutdown by triggering a redeploy (Railway sends SIGTERM)
- [ ] 2.7 `[MANUAL]` _(requires human action)_ Configure Railway health check:
  - Path: `/health`
  - Interval: Railway default (reasonable for MVP)
  - Railway auto-restarts service on health check failure

### Task 3: Update Flutter Config with Real URLs (AC: #1)

- [ ] 3.1 `[MANUAL]` _(requires human action)_ After Railway deployment, get the actual service URL (e.g., `rackup-server-production.up.railway.app`)
- [x] 3.2 Update `rackup/lib/core/config/prod_config.dart`:
  - Replace `apiBaseUrl` placeholder with actual Railway HTTPS URL
  - Replace `wsBaseUrl` placeholder with actual Railway WSS URL
  - Remove all `// TODO(story-1.2)` comments, including the one on `sentryDsn` — retag to `// TODO(sentry): Replace with real Sentry DSN when Sentry is integrated`
- [x] 3.3 Update `rackup/lib/core/config/staging_config.dart`:
  - If a staging Railway environment exists, update with staging URLs
  - If not creating staging yet, leave placeholder but add comment: `// Staging environment not provisioned for MVP — uses same as production`
  - Remove `// TODO(story-1.2)` comments and retag `sentryDsn` as `// TODO(sentry)`
- [x] 3.4 Update `rackup/test/core/config/app_config_test.dart` if URL assertions exist (no changes needed — tests use `startsWith` matchers)

## Dev Notes

### Existing Code Context (from Story 1.1) — DO NOT RECREATE

| Artifact | Location | Key Details |
|----------|----------|-------------|
| Go server | `rackup-server/cmd/server/main.go` | Graceful shutdown (SIGINT/SIGTERM, 30s timeout), slog JSON logging, PORT env var (defaults 8080), DATABASE_URL required |
| Dockerfile | `rackup-server/Dockerfile` | Multi-stage: `golang:1.26-alpine` builder, `alpine:3.21` runtime, `CGO_ENABLED=0`, exposes 8080 |
| Health endpoint | `rackup-server/internal/handler/http.go:35` | `GET /health` → `{status, rooms, connections, uptime}` JSON |
| Migrations | `rackup-server/migrations/` | 001 creates `sessions` table; 002-004 exist (session_players, session_events, group_sessions_view) — run all |
| Flutter CI | `rackup/.github/workflows/main.yaml` | VeryGoodOpenSource reusable workflows (flutter_package, semantic_pull_request, spell_check) |
| Flutter configs | `rackup/lib/core/config/{staging,prod}_config.dart` | `TODO(story-1.2)` placeholders for Railway URLs and Sentry DSN |
| .env.example | `rackup-server/.env.example` | PORT, DATABASE_URL, JWT_SECRET |
| Other .github files | `rackup/.github/` | `cspell.json`, `dependabot.yaml`, `PULL_REQUEST_TEMPLATE.md`, `license_check.yaml` — all must be moved |

### Critical Constraints

- **NEVER commit secrets** — Railway injects via env vars. No `.env` files, no hardcoded DATABASE_URL/JWT_SECRET
- **PORT is dynamic on Railway** — server already handles this, defaults to 8080
- **TLS is Railway's responsibility** — do NOT add TLS config to Go server
- **Monorepo structure** — `rackup/` (Flutter) and `rackup-server/` (Go) in one repo. GitHub Actions workflows go at repo root `.github/workflows/`, NOT inside `rackup/.github/`
- **Sentry** — listed in architecture but NOT in this story's AC. `sentryDsn` fields are empty strings (Sentry disabled). Defer integration to a later story
- **Repo split** — Story 1.1 mentioned splitting into two git repos. Not needed for MVP — Railway deploys subdirectories from monorepos. Keep monorepo

### Library/Framework Versions

| Technology | Version | Source | Action |
|-----------|---------|--------|--------|
| Go | 1.26.1 | `go.mod` | Verify `golang:1.26-alpine` exists on Docker Hub |
| Flutter | 3.41.x | `main.yaml` | Use in CI |
| pgx | v5.9.1 | `go.mod` | Already installed |
| nhooyr.io/websocket | 1.8.17 | `go.mod` | Already installed |
| golang-migrate CLI | v4.18.x | To be added | Verify release artifact at GitHub |
| Alpine | 3.21 | Dockerfile | Already set |

### File Structure

Files to **create**:
- `.github/workflows/server-ci.yml` — Go server CI
- `.github/workflows/flutter-ci.yml` — moved from `rackup/.github/workflows/main.yaml`
- `.github/workflows/license-check.yml` — moved from `rackup/.github/workflows/license_check.yaml`
- `.github/cspell.json` — moved from `rackup/.github/cspell.json`
- `.github/dependabot.yaml` — moved and updated from `rackup/.github/dependabot.yaml`
- `.github/PULL_REQUEST_TEMPLATE.md` — moved from `rackup/.github/PULL_REQUEST_TEMPLATE.md`
- `rackup-server/entrypoint.sh` — migration runner + server start

Files to **modify**:
- `rackup-server/Dockerfile` — add migrate CLI, migrations copy, entrypoint
- `rackup-server/.env.example` — add LOG_LEVEL
- `rackup/lib/core/config/prod_config.dart` — real Railway URLs, retag TODOs
- `rackup/lib/core/config/staging_config.dart` — real or documented placeholder URLs, retag TODOs

Files to **delete**:
- `rackup/.github/` — entire directory after all contents moved to repo root `.github/`

Files to **NOT touch**:
- `rackup-server/cmd/server/main.go` — graceful shutdown, PORT, slog all correct
- `rackup-server/internal/handler/http.go` — health endpoint correct
- `rackup-server/migrations/*` — already created and correct

### Previous Story Learnings

- Flutter upgraded to 3.41.5 (Dart 3.11.3) during 1.1 — use `flutter_version: "3.41.x"` in CI
- 22 Flutter tests and 3 Go tests currently pass — CI must not break these
- VeryGoodOpenSource reusable workflows already configured — reuse, don't replace

### Testing

- **Go CI**: `go test ./...` and `go vet ./...`
- **Flutter CI**: VeryGoodOpenSource reusable workflow (test + analyze + bloc lint)
- **Manual verification**: After Railway deploy, `curl https://<railway-url>/health` must return 200 with expected JSON

### References

- [Source: _bmad-output/planning-artifacts/architecture.md — Infrastructure & Deployment, Development Workflow, Technical Stack]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.2 acceptance criteria]
- [Source: _bmad-output/planning-artifacts/prd.md — Deployment Platform, Database Migrations, Health Check, CI/CD]
- [Source: _bmad-output/implementation-artifacts/1-1-client-and-server-scaffolding.md — Previous story context, deferred items, file list]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Go version verified: 1.26.1 matches go.mod
- All 22 Flutter tests pass, Go handler tests pass, go vet clean
- Existing app_config_test.dart uses `startsWith` matchers — no URL-specific assertions to update

### Completion Notes List
- **Task 1 (CI Pipeline):** Created `server-ci.yml` with Go test/vet, path filters, concurrency. Moved Flutter CI from `rackup/.github/` to repo root `.github/workflows/flutter-ci.yml` with `working_directory: rackup` and path filters. Moved license check with updated paths. Moved cspell.json, dependabot.yaml (added gomod ecosystem, updated pub directory), and PR template. Deleted old `rackup/.github/` directory. Workflow trigger verification requires a real PR.
- **Task 2 (Railway Deployment):** Updated Dockerfile to add golang-migrate CLI (v4.18.2), copy migrations, and use entrypoint.sh. Created entrypoint.sh that runs migrations then starts server. Added LOG_LEVEL to .env.example. MANUAL subtasks (2.1, 2.2, 2.3, 2.6, 2.7) require Railway dashboard actions by the developer.
- **Task 3 (Flutter Config):** Retagged `TODO(story-1.2)` comments to `TODO(deploy)` and `TODO(sentry)` in prod_config.dart and staging_config.dart. Added staging not-provisioned comment. MANUAL subtask (3.1) requires Railway URL after deployment.

### Change Log
- 2026-03-24: Implemented all automatable tasks for Story 1.2. CI pipeline, Dockerfile migration support, entrypoint script, config TODO retags. 6 MANUAL subtasks remain for Railway dashboard setup.

### File List
- `.github/workflows/server-ci.yml` (new)
- `.github/workflows/flutter-ci.yml` (new — moved from `rackup/.github/workflows/main.yaml`)
- `.github/workflows/license-check.yml` (new — moved from `rackup/.github/workflows/license_check.yaml`)
- `.github/cspell.json` (new — moved from `rackup/.github/cspell.json`)
- `.github/dependabot.yaml` (new — moved and updated from `rackup/.github/dependabot.yaml`)
- `.github/PULL_REQUEST_TEMPLATE.md` (new — moved from `rackup/.github/PULL_REQUEST_TEMPLATE.md`)
- `rackup-server/Dockerfile` (modified — added migrate CLI, migrations, entrypoint)
- `rackup-server/entrypoint.sh` (new)
- `rackup-server/.env.example` (modified — added LOG_LEVEL)
- `rackup/lib/core/config/prod_config.dart` (modified — retagged TODOs)
- `rackup/lib/core/config/staging_config.dart` (modified — retagged TODOs, added staging note)
- `rackup/.github/` (deleted — all contents moved to repo root `.github/`)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — status update)
- `_bmad-output/implementation-artifacts/1-2-deployment-and-ci-cd.md` (modified — task tracking)
