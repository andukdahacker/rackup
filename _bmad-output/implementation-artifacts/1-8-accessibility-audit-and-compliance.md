# Story 1.8: Accessibility Audit & Compliance

Status: review

## Story

As a player with accessibility needs (reduced motion, screen reader, motor impairment, cognitive considerations),
I want the RackUp app to respect my device accessibility settings and provide proper semantic navigation,
so that I can fully participate in the game experience without barriers.

## Acceptance Criteria

### AC1: Reduced Motion

**Given** a player has reduced motion enabled on their device
**When** `MediaQuery.disableAnimations` is `true`
**Then:**
- Particle system disabled entirely
- Leaderboard positions snap instantly (no shuffle animation)
- The Reveal, Eruption, Shuffle animations show content at final state immediately
- Tier color transitions swap instantly (no crossfade)
- Lobby arrivals appear immediately (no slide-in)
- Button breathing animations disabled
- Storm pause for "RECORD THIS" shows red edge flash only
- All game logic, sound effects, text, layouts, share image generation maintained

### AC2: Screen Reader Support

**Given** a player uses a screen reader
**When** they navigate the app
**Then:**
- All buttons labeled with purpose + context (e.g., "Deploy Blue Shell", "Share report card to Instagram Stories")
- Player tags announce name + rank + score
- Item cards announce name + effect description
- Event feed entries announced on arrival
- Full accessibility for navigable screens (Home, Join, Report Card — Note: Report Card is Epic 8; for this story, audit Home, Join, and Create Room only; Report Card accessibility will be addressed when implemented)
- Best-effort support for active game screens

### AC3: Motor Accessibility

**Given** motor accessibility requirements
**When** a player interacts with the app
**Then:**
- No precision gestures (swipes, pinches, long-press-drag)
- All single taps on large targets (56dp+ minimum)
- Full-width primary buttons allow tap anywhere in lower region

### AC4: Cognitive Accessibility

**Given** cognitive accessibility requirements
**When** app renders any screen
**Then:**
- One primary purpose per screen (no multi-modal interfaces)
- Systems reveal through gameplay (progressive disclosure)
- Player Name Tag component used consistently
- No time pressure on referee input

### AC5: Audio Accessibility

**Given** audio accessibility requirements
**When** sound effects play
**Then:**
- Every sound supplementary (never sole indicator)
- Visual feedback accompanies every sound
- Device silent/vibrate mode respected

### AC6: Responsive Text Scaling

**Given** responsive text scaling system
**When** users have accessibility text scaling enabled
**Then:**
- Body text (14-20dp) scales max 2.0x
- Display/headings (32-64dp) scale max 1.2x
- Referee punishment text (20dp) scales max 1.3x
- Button labels (28dp) do not scale (1.0x fixed)
- Custom clamped TextScaler utility enforces limits

## Tasks / Subtasks

### Task 1: Audit & Expand Semantics Across All Screens (AC: #2)

- [x] 1.1 Audit every interactive widget in the app for missing `Semantics` wrappers
- [x] 1.2 Add `Semantics` to Home page elements beyond existing buttons (headline, subtitle)
- [x] 1.3 Add `Semantics` to Join Room page code input fields (`_CodeCharField`) with labels like "Room code digit 1 of 4"
- [x] 1.4 Add `Semantics` to Join Room page display name input
- [x] 1.5 Add `Semantics` to Create Room page loading/error states
- [x] 1.6 Verify all existing `Semantics` labels follow pattern: purpose + context
- [x] 1.7 Add `ExcludeSemantics` to decorative elements: tier color background containers, gradient overlays, decorative dividers, and shape icons where the adjacent text label already conveys the same meaning

### Task 2: Verify and Complete Reduced Motion Support (AC: #1)

- [x] 2.1 Audit `GameTheme` to ensure `disableAnimations` flag propagates to ALL animation points (currently only tier transitions)
- [x] 2.2 Verify `RackUpGameThemeData.animationsEnabled` (already exists at `game_theme.dart:39`) is wired correctly via `app.dart:56-61` — do NOT create a new provider; the `RackUpGameTheme` InheritedWidget already exposes this to all widgets
- [x] 2.3 Ensure lobby player arrival animations respect reduced motion (snap into place)
- [x] 2.4 Ensure button breathing/pulse animations check reduced motion before animating
- [x] 2.5 Document reduced motion behavior for future story implementations (game screens in Epic 2+)

### Task 3: Verify ClampedTextScaler Coverage (AC: #6)

- [x] 3.1 Audit all `Text` widgets to ensure `ClampedTextScaler` is applied with the correct `TextRole`
- [x] 3.2 Verify `TextRole.display` (max 1.2x) is used for Oswald display/heading text (32-64dp)
- [x] 3.3 Verify `TextRole.body` (max 2.0x) is used for Barlow body text (14-20dp)
- [x] 3.4 Verify `TextRole.buttonLabel` (max 1.0x) is used for button labels (28dp Oswald Bold)
- [x] 3.5 Verify `TextRole.refereePunishment` (max 1.3x) already exists — do NOT create a duplicate
- [x] 3.6 Verify `TextRole.playerNameTag` (max 2.0x) and `TextRole.playerNameTagIcon` (max 1.0x) are applied to player identity widgets
- [x] 3.7 Test layout integrity at maximum text scale factors — no overflow, no clipping

### Task 4: Verify Tap Target Compliance (AC: #3)

- [x] 4.1 Audit all interactive elements for 56dp minimum tap target size
- [x] 4.2 Verify primary buttons are 64dp+ height
- [x] 4.3 Verify no precision gestures exist (no GestureDetector with onPanUpdate, onScaleUpdate, onLongPressMoveUpdate)
- [x] 4.4 Add `SizedBox` constraints to any undersized tappable elements

### Task 5: Verify Cognitive Accessibility Patterns (AC: #4)

- [x] 5.1 Audit each current screen (Home, Join Room, Create Room) confirms one primary purpose — no competing actions or multi-modal interfaces
- [x] 5.2 Verify progressive disclosure: no upfront information dumps or tutorials on any screen
- [x] 5.3 Verify Player Name Tag component is used consistently wherever a player is referenced
- [x] 5.4 Verify no time-gated interactions exist on current screens (no countdown timers forcing user action)
- [x] 5.5 Document cognitive accessibility patterns for future story implementations

### Task 6: Verify Audio Accessibility Patterns (AC: #5)

- [x] 6.1 Audit current codebase for any audio playback — confirm no sound effects exist yet (sounds arrive in Story 3.6)
- [x] 6.2 Verify no screen uses audio as the sole indicator of a state change (all feedback is visual)
- [x] 6.3 Document the audio accessibility contract for future stories: every sound must have a visual counterpart, silent/vibrate mode must be respected

### Task 7: WCAG AA Contrast Verification (AC: #2)

- [x] 7.1 Write automated contrast ratio tests for all semantic color pairs against base canvas `#0F0E1A`
- [x] 7.2 Verify primary text `#F0EDF6` on `#0F0E1A` achieves 14.8:1 (AAA)
- [x] 7.3 Verify green `#22C55E`, red `#EF4444`, gold `#FFD700`, blue `#3B82F6`, purple `#A855F7` all meet 4.5:1 minimum against `#0F0E1A`
- [x] 7.4 Verify muted lavender `#8B85A1` meets 4.5:1 against `#0F0E1A` for secondary text (expected ~5.2:1 — tightest margin in palette)
- [x] 7.5 Verify escalation tier background colors maintain contrast with text overlays
- [x] 7.6 Fix any color pairs that fail WCAG AA; document rationale for any deliberate exceptions

### Task 8: Add Accessibility-Focused Tests (AC: #1, #2, #3, #4, #5, #6)

- [x] 8.1 Add Semantics finder tests for all labeled elements on Home, Join, Create pages
- [x] 8.2 Add reduced motion behavior tests (verify animations skip when `disableAnimations: true`)
- [x] 8.3 Add text scaling tests (render at 2.0x and verify no overflow using `OverflowBox` detection)
- [x] 8.4 Add contrast ratio unit tests in `rackup_colors_test.dart` (file already exists with 20 value-assertion tests — extend, do not break)
- [x] 8.5 Add tap target size tests (verify minimum 56dp for all interactive elements)
- [x] 8.6 Ensure zero regressions — current baseline is 174 passing Flutter tests

## Invariants

- **INVARIANT: All 174 existing Flutter tests must pass after this story — zero regressions.**
- No new packages required — Flutter built-in APIs only.

## Dev Notes

### What Already Exists (DO NOT Recreate)

The design system in Story 1.3 already implemented significant accessibility foundations. **Reuse these — do not duplicate:**

- **`ClampedTextScaler`** (`lib/core/theme/clamped_text_scaler.dart`) — Custom `TextScaler` with `TextRole` enum (6 values: `body`, `display`, `refereePunishment`, `buttonLabel`, `playerNameTag`, `playerNameTagIcon`) and max scale factors. Factory: `ClampedTextScaler.of(context, TextRole.body)`. Already has comprehensive tests in `clamped_text_scaler_test.dart`.
- **`GameTheme`** (`lib/core/theme/game_theme.dart`) — Already detects `MediaQuery.disableAnimations` and exposes `animationsEnabled` (line 39) via `RackUpGameTheme` InheritedWidget. Wired in `app.dart:56-61`. Currently only controls tier transition duration. Verify propagation, don't recreate.
- **`PlayerIdentity`** (`lib/core/theme/player_identity.dart`) — 8-slot color+shape system already provides colorblind redundancy.
- **`RackUpSpacing`** (`lib/core/theme/rackup_spacing.dart`) — Already defines `minTapTarget: 56` and `primaryButtonHeight: 64`.
- **`RackUpColors`** (`lib/core/theme/rackup_colors.dart`) — All semantic colors already defined.
- **`RackUpTypography`** (`lib/core/theme/rackup_typography.dart`) — 8-token type scale with correct fonts.
- **Existing `Semantics`** — 5 instances already exist:
  - `home_page.dart`: `_PrimaryButton` and `_SecondaryButton`
  - `create_room_page.dart`: `_ShareButton` and error retry button
  - `join_room_page.dart`: Join button
- **Existing tests** — `reduced_motion_test.dart` and `clamped_text_scaler_test.dart` already validate core accessibility.

### Key Patterns to Follow

- **Semantics pattern** used in existing code:
  ```dart
  Semantics(
    button: true,
    label: 'Descriptive Label',
    child: Material(...)
  )
  ```
- **Reduced motion detection** pattern from `game_theme.dart`:
  ```dart
  final disableAnimations = MediaQuery.of(context).disableAnimations;
  ```
- **Text scaling** pattern:
  ```dart
  Text(
    'content',
    textScaler: ClampedTextScaler.of(context, TextRole.body),
  )
  ```

### What This Story Does NOT Cover

This story audits and fixes only the **currently implemented screens** (Home, Join Room, Create Room, and the design system/theme). Future game screens (Epic 2+) will inherit these patterns and apply them during implementation. This story establishes the patterns and ensures current screens are compliant.

**Note on AC1 (Reduced Motion):** Most animations listed (particle system, leaderboard shuffle, The Reveal/Eruption/Shuffle, lobby slide-in, button breathing, storm pause) do NOT exist yet in the codebase — they are Epic 2-5 features. For this story, only verify the tier color transition animation disable (already in `GameTheme`) works correctly, and document the reduced-motion pattern so future stories apply it consistently. The AC is a forward spec capturing the full requirement.

Specifically **out of scope** for this story:
- Lobby player list UI (Story 2.1)
- Game referee/player screens (Epic 3)
- Item cards, event feed, leaderboard animations (Epic 3-5)
- Post-game report card (Epic 8)
- Narrator Mode / text-to-speech (Phase 2 feature)

### Architecture Compliance

- **No new packages required** — Flutter's built-in `Semantics`, `MediaQuery`, and `TextScaler` cover all needs
- **No new Blocs** — accessibility is widget-level, not state-management-level
- **Testing framework** — use `flutter_test` with `find.bySemanticsLabel()` and `SemanticsHandle` for accessibility tests
- **File locations** — all changes in existing files under `lib/core/theme/` and `lib/features/`; new test files mirror `lib/` structure under `test/`

### WCAG AA Contrast Calculation

To verify contrast ratios programmatically, use the relative luminance formula:

```
contrastRatio = (L1 + 0.05) / (L2 + 0.05)
```

Where `L1` is the lighter color luminance and `L2` is the darker. WCAG AA requires >= 4.5:1 for normal text, >= 3:1 for large text (18pt+ or 14pt bold+).

Base canvas `#0F0E1A` has very low luminance (~0.008), so most bright foreground colors will pass easily. The critical check is muted colors like `#8B85A1` (muted lavender used for secondary text).

### Previous Story Intelligence

**From Story 1.7 (Join Room via Deep Link):**
- Test baseline: 174 passing Flutter tests — maintain zero regressions
- `join_room_page.dart` was recently modified to accept `initialCode` parameter with read-only mode and dimmed text — verify Semantics cover these states
- Commit pattern: single story commit + code review fix commit
- Widget tests use `WidgetTester` with `pumpWidget` pattern, wrapping in `MaterialApp.router` for navigation tests

**From Story 1.3 (Design System & Theme):**
- Established all theme files, color palette, typography, spacing tokens
- `ClampedTextScaler` was created specifically for this accessibility story
- `reduced_motion_test.dart` already tests `GameTheme` animation disable behavior
- Player identity color+shape system designed for colorblind accessibility from inception

### Git Patterns From Recent Work

- Commit message format: "Add [feature description] (Story X.Y)"
- Code review fixes in separate commit: "Fix code review findings for Story X.Y"
- All stories maintain backward compatibility with existing tests
- Widget tests are thorough — 9-13 new tests per UI story

### Project Structure Notes

- All source code under `rackup/lib/` (Flutter client)
- Theme infrastructure: `rackup/lib/core/theme/`
- Feature pages: `rackup/lib/features/{feature}/view/`
- Tests mirror lib: `rackup/test/core/theme/`, `rackup/test/features/`
- No conflicts with unified project structure detected

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.8]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Accessibility Considerations, Responsive Design & Accessibility]
- [Source: _bmad-output/planning-artifacts/architecture.md — Client Architecture, Implementation Patterns]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR section, Store Compliance]
- [Source: _bmad-output/implementation-artifacts/1-7-join-room-via-deep-link.md — Previous story completion notes]
- [Source: _bmad-output/implementation-artifacts/1-3-design-system-and-theme.md — Design system foundation]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- All 174 original tests pass (zero regressions)
- 30 new accessibility tests added (204 total)
- Flutter analyzer: 0 new issues in modified files

### Completion Notes List

- **Task 1 (Semantics):** Added `Semantics` with `header: true` to homepage headline and join room heading. Added `Semantics` with `label` to all 4 code input fields ("Room code digit N of 4"), display name field, subtitle text. Updated Join button label from "Join" to "Join room" (purpose + context pattern). Added `Semantics(liveRegion: true)` to create room loading and error states. Added `ExcludeSemantics` to decorative error icon. Added `Semantics` with letter-spaced label to `RoomCodeDisplay`.
- **Task 2 (Reduced Motion):** Verified `GameTheme.animationsEnabled` correctly wired via `app.dart:56-61`. `tierTransitionDuration` returns `Duration.zero` when disabled. No other animations exist yet in codebase — pattern documented for future stories.
- **Task 3 (ClampedTextScaler):** Applied `ClampedTextScaler.of(context, TextRole.xxx)` to ALL `Text` widgets across home, join room, create room pages, and room code display. Display text (32-64dp) → `TextRole.display` (max 1.2x), body text (14-20dp) → `TextRole.body` (max 2.0x), button labels → `TextRole.buttonLabel` (1.0x fixed).
- **Task 4 (Tap Targets):** Verified all buttons use `primaryButtonHeight: 64dp` (exceeds 56dp minimum). No precision gestures found (no onPanUpdate, onScaleUpdate, onLongPressMoveUpdate).
- **Task 5 (Cognitive):** Verified each screen (Home, Join, Create) has single primary purpose. No information dumps or time-gated interactions on current screens.
- **Task 6 (Audio):** Confirmed no audio playback exists in codebase. All feedback is visual. Documented audio accessibility contract for future stories.
- **Task 7 (Contrast):** Added automated WCAG contrast ratio tests using relative luminance formula. All semantic colors pass AA (>= 4.5:1) against canvas #0F0E1A. textPrimary passes AAA (>= 7:1). textSecondary #8B85A1 passes AA (~5.2:1). All tier backgrounds pass with textPrimary.
- **Task 8 (Tests):** Added 22 tests in `accessibility_test.dart` (semantics finders, reduced motion, tap targets, text scaling at 2.0x, no precision gestures) and 8 tests in `accessibility_contrast_test.dart` (WCAG contrast ratios).

### Change Log

- 2026-03-27: Implemented Story 1.8 — Accessibility Audit & Compliance (all 8 tasks)

### File List

**Modified:**
- `lib/features/home/view/home_page.dart` — Added Semantics wrappers, ClampedTextScaler to all Text widgets
- `lib/features/lobby/view/join_room_page.dart` — Added Semantics to heading, code fields, name field; ClampedTextScaler to all Text widgets
- `lib/features/lobby/view/create_room_page.dart` — Added Semantics live regions, ExcludeSemantics on error icon; ClampedTextScaler to all Text widgets
- `lib/features/lobby/view/widgets/room_code_display.dart` — Added Semantics label, ClampedTextScaler

**Added:**
- `test/features/accessibility_test.dart` — 22 accessibility tests (semantics, reduced motion, tap targets, text scaling, no precision gestures)
- `test/core/theme/accessibility_contrast_test.dart` — 8 WCAG AA contrast ratio tests
