# Story 1.4: Device Identity & App Home Screen

Status: done

## Story

As a player,
I want to open RackUp and see a clear home screen with options to create or join a room,
So that I can immediately start gathering friends for a game.

## Acceptance Criteria

1. **Given** the player launches the app for the first time, **When** the app initializes, **Then** a UUID v4 device identifier is generated and persisted locally on the device, **And** the identifier is never transmitted in raw form (SHA-256 hashed before any server communication).

2. **Given** the player is on the home screen, **When** the screen renders, **Then** the headline "Turn pool night into chaos" is displayed in Oswald Bold, **And** a primary "Create Room" button and secondary "Join Room" button are visible, **And** subtext "Grab friends. Find a pool table. Let the chaos begin." is displayed, **And** the design system theme from Story 1.3 is applied (dark canvas, typography, spacing, tap targets).

3. **Given** the player has launched the app before, **When** they reopen the app, **Then** the same device identifier is loaded from local storage (not regenerated).

## Tasks / Subtasks

- [x] Task 1: Add dependencies (AC: 1, 3)
  - [x] Add `shared_preferences: ^2.5.0` to pubspec.yaml for persistent local storage
  - [x] Add `uuid: ^4.5.1` to pubspec.yaml for UUID v4 generation
  - [x] Add `crypto: ^3.0.6` to pubspec.yaml for SHA-256 hashing
  - [x] Run `flutter pub get` to verify dependency resolution

- [x] Task 2: Implement DeviceIdentityService (AC: 1, 3)
  - [x] Create `lib/core/services/device_identity_service.dart`
  - [x] Generate UUID v4 on first launch, persist via SharedPreferences under key `device_id`
  - [x] On subsequent launches, read existing ID from SharedPreferences (never regenerate)
  - [x] Provide `getDeviceId()` returning the raw local UUID (for local use only)
  - [x] Provide `getHashedDeviceId()` returning SHA-256 hex digest of the UUID (for server communication)
  - [x] Service must be initialized before the app renders (call in bootstrap or app startup)

- [x] Task 3: Create Home Screen UI (AC: 2)
  - [x] Create `lib/features/home/view/home_page.dart`
  - [x] Headline: "Turn pool night into chaos" using `RackUpTypography.displayLg` with Oswald Bold (700)
  - [x] Subtext: "Grab friends. Find a pool table. Let the chaos begin." using `RackUpTypography.body` in `RackUpColors.textSecondary`
  - [x] Primary "Create Room" button: full-width, `RackUpSpacing.primaryButtonHeight` (64dp) min height, `RackUpColors.madeGreen` background, text styled with `RackUpTypography.bodyLg.copyWith(fontFamily: RackUpFontFamilies.display, fontWeight: FontWeight.w700, color: Colors.white)`
  - [x] Secondary "Join Room" button: full-width, `RackUpSpacing.primaryButtonHeight` (64dp) min height, outlined style with `RackUpColors.textPrimary` border, text styled same as above but with `color: RackUpColors.textPrimary`
  - [x] All tap targets 56dp+ minimum
  - [x] Dark canvas background via Scaffold default (`RackUpColors.canvas` — already set in ThemeData). No use of `tierLobby` on home screen — the escalation palette only applies during active gameplay
  - [x] Bottom-weighted layout: buttons in lower portion of screen, headline/subtext upper-center
  - [x] Portrait-locked, SafeArea wrapped
  - [x] Spacing uses `RackUpSpacing` tokens (space-xl for edge padding, space-lg between sections, space-md between buttons)

- [x] Task 4: Wire routing (AC: 2)
  - [x] Replace `_PlaceholderHome` in `lib/core/routing/app_router.dart` with `HomePage`
  - [x] Add placeholder routes for `/create` and `/join` (empty screens with back navigation — implemented in Stories 1.5 and 1.6)
  - [x] Buttons use `context.push('/create')` and `context.push('/join')` (push, not go — enables back navigation from placeholder screens)

- [x] Task 5: Initialize DeviceIdentityService at app startup (AC: 1, 3)
  - [x] Add `WidgetsFlutterBinding.ensureInitialized()` as the first line in `bootstrap()` in `bootstrap.dart` (required before SharedPreferences)
  - [x] Create `SharedPreferences` instance and `DeviceIdentityService` in `bootstrap()`, call `await service.init()` to generate/load the device ID
  - [x] Add `DeviceIdentityService` as a required parameter to `App` widget (alongside existing `config`)
  - [x] Update `main_development.dart`, `main_staging.dart`, `main_production.dart` to pass the service to `App`
  - [x] In `app.dart`, wrap the existing `RepositoryProvider<AppConfig>` with a `MultiRepositoryProvider` that also provides `DeviceIdentityService`
  - [x] Ensure device ID is generated/loaded before the home screen renders

- [x] Task 6: Write tests (AC: 1, 2, 3)
  - [x] Unit tests for `DeviceIdentityService`:
    - Generates UUID v4 on first call when no stored ID exists
    - Returns same ID on subsequent calls (persistence)
    - `getHashedDeviceId()` returns valid SHA-256 hex string (64 chars)
    - Hash is deterministic (same input UUID produces same hash)
  - [x] Widget tests for `HomePage`:
    - Headline text renders correctly
    - Subtext renders correctly with `RackUpColors.textSecondary` color (use `.copyWith(color:)` on `RackUpTypography.body`)
    - "Create Room" button is visible and tappable
    - "Join Room" button is visible and tappable
    - Design system tokens applied (font family, colors, spacing)
    - Buttons navigate to correct routes
  - [x] All tests use `pump_app.dart` helper with `RackUpGameTheme` wrapper
  - [x] Run full `flutter test` and confirm all existing 106 tests + new tests pass (zero regressions)

## Dev Notes

### Architecture Compliance

- **DeviceIdentityService** goes in `lib/core/services/` — this is shared infrastructure, not feature-specific
- **HomePage** goes in `lib/features/home/view/` — follows the feature-based organization pattern
- Device ID is a **core service**, not a Bloc. It's a simple read/write with no event/state ceremony needed. Provide it via `RepositoryProvider<DeviceIdentityService>`
- The home screen does NOT need a Bloc — it's a static screen with two navigation buttons. No async state, no server calls. A plain `StatelessWidget` is correct
- SHA-256 hashing happens **client-side before any transmission**. The raw UUID never leaves the device. Server never sees the raw ID (architecture requirement: NFR10)

### Technical Requirements

- **UUID v4 format:** Standard RFC 4122 UUID (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- **SHA-256 output:** Lowercase hex string, 64 characters (e.g., `a1b2c3...`)
- **SharedPreferences key:** `device_id` — simple string storage
- **Initialization order:** SharedPreferences must be initialized before the app widget tree builds. Use `WidgetsFlutterBinding.ensureInitialized()` then `SharedPreferences.getInstance()` in bootstrap
- **DO NOT** use `flutter_secure_storage` — the device ID is not a secret credential; it's a persistent anonymous identifier. SharedPreferences is the correct choice per the architecture spec

### Library & Framework Requirements

- **`shared_preferences`**: Use latest stable version compatible with Flutter 3.41+. This is the standard Flutter local key-value storage plugin
- **`uuid`**: Use `Uuid().v4()` to generate RFC 4122 v4 UUIDs
- **`crypto`**: Use `sha256.convert(utf8.encode(rawId)).toString()` for hashing. This is the `dart:convert` + `package:crypto` pattern
- **`go_router`**: Already at ^17.1.0 — use `context.push('/create')` and `context.push('/join')` for navigation (push enables back button on placeholder screens)

### File Structure Requirements

New files to create:
```
lib/
├── core/
│   └── services/
│       └── device_identity_service.dart    # NEW — replace .gitkeep
├── features/
│   └── home/
│       └── view/
│           └── home_page.dart              # NEW
test/
├── core/
│   └── services/
│       └── device_identity_service_test.dart  # NEW
├── features/
│   └── home/
│       └── view/
│           └── home_page_test.dart            # NEW
```

Files to modify:
```
lib/core/routing/app_router.dart           # Replace _PlaceholderHome with HomePage, add /create and /join placeholder routes
lib/bootstrap.dart                         # Add WidgetsFlutterBinding.ensureInitialized(), SharedPreferences + DeviceIdentityService init
lib/app/view/app.dart                      # Add DeviceIdentityService param, MultiRepositoryProvider
lib/main_development.dart                  # Pass DeviceIdentityService to App
lib/main_staging.dart                      # Pass DeviceIdentityService to App
lib/main_production.dart                   # Pass DeviceIdentityService to App
pubspec.yaml                               # Add shared_preferences, uuid, crypto
```

### Testing Standards

- Use `mocktail` for mocking SharedPreferences in unit tests
- Widget tests use `pump_app.dart` helper (wraps with RackUpGameTheme + ThemeData)
- **Navigation tests caveat:** `pump_app.dart` uses `MaterialApp(home:)` without GoRouter. To test button navigation to `/create` and `/join`, either: (a) use `MockGoRouter` from `package:go_router` and inject via `GoRouter.of` or `InheritedGoRouter`, or (b) set up a test-specific `MaterialApp.router` with a real GoRouter that includes the test routes. Option (a) is simpler — verify `context.push` was called with the correct path
- Test file structure mirrors lib/ per Very Good CLI conventions
- All tests must pass: `flutter test`, `flutter analyze`
- Follow Dart naming: test files end with `_test.dart`

### UI Design Specifications

**Home screen layout (portrait, single-column):**

```
┌─────────────────────────┐
│       SafeArea          │
│                         │
│                         │
│   "Turn pool night      │  ← RackUpTypography.displayLg, Oswald Bold
│    into chaos"          │    RackUpColors.textPrimary
│                         │
│   "Grab friends. Find   │  ← RackUpTypography.body, Barlow 400
│    a pool table. Let    │    RackUpColors.textSecondary
│    the chaos begin."    │
│                         │
│         ...             │
│                         │
│  ┌───────────────────┐  │  ← Full-width, primaryButtonHeight (64dp)
│  │   Create Room     │  │    RackUpColors.madeGreen bg, bold white text
│  └───────────────────┘  │
│       space-md (16dp)   │
│  ┌───────────────────┐  │  ← Full-width, primaryButtonHeight (64dp)
│  │    Join Room      │  │    Outlined, textPrimary border, textPrimary text
│  └───────────────────┘  │
│       space-xl (32dp)   │
└─────────────────────────┘

Background: RackUpColors.canvas (#0F0E1A)
Edge padding: RackUpSpacing.spaceXl (32dp) horizontal
```

**Button styling:**
- Primary (Create Room): `RackUpColors.madeGreen` (#22C55E) fill, white text, `RackUpFontFamilies.display` (Oswald) Bold, rounded corners
- Secondary (Join Room): Transparent fill, `RackUpColors.textPrimary` (#F0EDF6) 1.5dp border, textPrimary text, Oswald Bold
- Both buttons: full-width minus `RackUpSpacing.spaceXl` (32dp) horizontal padding each side, `RackUpSpacing.primaryButtonHeight` (64dp) minimum height
- No Material elevation/shadow — flat design per the custom design system

**Accessibility:**
- Headline contrast: textPrimary (#F0EDF6) on canvas (#0F0E1A) = 14.8:1 (AAA)
- Buttons `RackUpSpacing.primaryButtonHeight` (64dp) exceeds `RackUpSpacing.minTapTarget` (56dp)
- Screen reader labels: "Turn pool night into chaos", "Create Room button", "Join Room button"
- Buttons are full-width — impossible to miss

### Project Structure Notes

- Alignment with architecture spec's Flutter folder structure: `lib/features/home/` for the home screen, `lib/core/services/` for device identity
- The `features/lobby/` folder is reserved for Stories 1.5 (Create Room) and 1.6 (Join Room) — do NOT put home screen there
- Home screen is its own feature because it's the app entry point, not part of the lobby flow. Note: `features/home/` is not in the architecture spec's folder listing (which shows lobby, game, postgame), but it's the correct place for the landing screen — it doesn't belong in any of the existing feature folders
- The `.gitkeep` in `lib/core/services/` should be deleted when `device_identity_service.dart` is created

### Previous Story Intelligence (Story 1.3)

**Patterns to follow:**
- All design tokens accessed via static constants: `RackUpColors.canvas`, `RackUpTypography.displayLg`, `RackUpSpacing.spaceXl`
- Typography uses const `TextStyle` with explicit `fontFamily` strings (not `GoogleFonts.oswald()` calls) — avoids async font loading issues in tests
- Widget tests wrap with `RackUpGameTheme` via `pump_app.dart` helper
- 106 tests established — maintain test quality bar

**Files from Story 1.3 to reference (not modify):**
- `lib/core/theme/rackup_colors.dart` — all color constants
- `lib/core/theme/rackup_typography.dart` — all type scale constants
- `lib/core/theme/rackup_spacing.dart` — spacing tokens + tap targets
- `lib/core/theme/game_theme.dart` — RackUpGameTheme InheritedWidget
- `test/helpers/pump_app.dart` — test wrapper helper

### Anti-Patterns to Avoid

- DO NOT create a Bloc/Cubit for the home screen — it's a static screen with no async state
- DO NOT use `GoogleFonts.oswald()` in widgets — use `RackUpTypography` constants (Story 1.3 pattern)
- DO NOT store the device ID in flutter_secure_storage — SharedPreferences is correct
- DO NOT transmit the raw device UUID anywhere — always hash first
- DO NOT add any server calls in this story — the "Create Room" and "Join Room" buttons navigate to placeholder screens only
- DO NOT add Material Design buttons (ElevatedButton, OutlinedButton) with default styling — build custom styled buttons using the design system tokens
- DO NOT put inline hex color values or magic number spacing — always reference `RackUpColors` and `RackUpSpacing` constants

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 1.4, lines 485-508]
- [Source: _bmad-output/planning-artifacts/architecture.md — Authentication & Security, lines 200-207]
- [Source: _bmad-output/planning-artifacts/architecture.md — Flutter Client Structure, lines 544-662]
- [Source: _bmad-output/planning-artifacts/architecture.md — State Management, lines 138-141]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — App Home Screen, lines 839-846]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Player Identity System, lines 621-634]
- [Source: _bmad-output/planning-artifacts/prd.md — Authentication Model, lines 437-449]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR9-NFR11, device ID hashing]
- [Source: _bmad-output/implementation-artifacts/1-3-design-system-and-theme.md — patterns and file structure]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Fixed GoRouter mock: `push` returns `Future<T?>` not `Future<void>`, required `extra` named param matching
- Fixed lint issues: const constructors, line lengths, raw string rules

### Completion Notes List
- Task 1: Added `shared_preferences: ^2.5.0`, `uuid: ^4.5.1`, `crypto: ^3.0.6` to pubspec.yaml. `flutter pub get` resolved successfully.
- Task 2: Created `DeviceIdentityService` in `lib/core/services/`. Generates UUID v4 on first launch, persists via SharedPreferences under key `device_id`. Provides `getDeviceId()` (raw local) and `getHashedDeviceId()` (SHA-256 hex digest for server communication).
- Task 3: Created `HomePage` StatelessWidget in `lib/features/home/view/`. Bottom-weighted layout with headline, subtext, and two full-width buttons using design system tokens. Custom `_PrimaryButton` and `_SecondaryButton` widgets with flat design (no Material elevation). Semantic labels for accessibility.
- Task 4: Replaced `_PlaceholderHome` with `HomePage` in router. Added `/create` and `/join` placeholder routes with back navigation. Buttons use `context.push()`.
- Task 5: Added `WidgetsFlutterBinding.ensureInitialized()` to `bootstrap()`. Service created and initialized before app renders. `App` widget now requires `DeviceIdentityService` parameter. Used `MultiRepositoryProvider` to provide both `AppConfig` and `DeviceIdentityService`. Updated all three main entry points.
- Task 6: 4 unit tests for DeviceIdentityService (UUID generation, persistence, SHA-256 format, deterministic hash). 7 widget tests for HomePage (headline, subtext color, button visibility/tappability, design tokens, button heights, route navigation). Updated existing `app_test.dart` for new `App` constructor. All 126 tests pass, `flutter analyze` clean.

### Change Log
- 2026-03-25: Implemented Story 1.4 — Device Identity & App Home Screen. Added DeviceIdentityService with UUID v4 generation and SHA-256 hashing, HomePage UI with design system compliance, routing with placeholder screens, bootstrap initialization, and comprehensive test coverage.

### File List
- `rackup/pubspec.yaml` (modified) — added shared_preferences, uuid, crypto dependencies
- `rackup/lib/core/services/device_identity_service.dart` (new) — persistent device identity with UUID v4 and SHA-256 hashing
- `rackup/lib/features/home/view/home_page.dart` (new) — home screen with Create Room and Join Room buttons
- `rackup/lib/core/routing/app_router.dart` (modified) — replaced placeholder with HomePage, added /create and /join routes
- `rackup/lib/bootstrap.dart` (modified) — added WidgetsFlutterBinding, SharedPreferences, DeviceIdentityService init
- `rackup/lib/app/view/app.dart` (modified) — added DeviceIdentityService param, MultiRepositoryProvider
- `rackup/lib/main_development.dart` (modified) — passes DeviceIdentityService to App
- `rackup/lib/main_staging.dart` (modified) — passes DeviceIdentityService to App
- `rackup/lib/main_production.dart` (modified) — passes DeviceIdentityService to App
- `rackup/lib/core/services/.gitkeep` (deleted) — replaced by device_identity_service.dart
- `rackup/test/core/services/device_identity_service_test.dart` (new) — 4 unit tests
- `rackup/test/features/home/view/home_page_test.dart` (new) — 7 widget tests
- `rackup/test/app/view/app_test.dart` (modified) — updated for new App constructor
