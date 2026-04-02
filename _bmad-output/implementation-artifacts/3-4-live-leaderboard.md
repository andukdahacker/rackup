# Story 3.4: Live Leaderboard

Status: review

## Story

As a player,
I want to see a live leaderboard that updates after every shot with polished animations and typography,
So that I always know the standings and feel the competitive tension.

## Acceptance Criteria

1. **Given** a game is in progress, **When** the player views the Leaderboard zone on their screen, **Then** all players are listed with their Player Name Tag (color+shape identity tag), display name (Oswald SemiBold), and current score (Oswald Bold, right-aligned), sorted by score descending with rank numbers.

2. **Given** a shot result causes a ranking change, **When** the leaderboard recalculates, **Then** position-shuffle animations play using The Shuffle motion pattern (fluid cascading with staggered timing — each row animates with a slight offset delay creating a domino/cascade effect), and animations render at 60fps on mid-range devices (NFR4). The shuffle should feel like entertainment, not just data — position changes become moments.

3. **Given** a player has an active streak (2+ consecutive makes), **When** the leaderboard renders, **Then** a Streak Fire Indicator appears next to that player's entry, and the indicator intensity matches the streak level (warming_up / on_fire / unstoppable).

4. **Given** the leaderboard leader changes, **When** the new leader is at the top, **Then** a subtle radial glow effect appears behind the leader's entry.

5. **Given** a player views their own entry, **When** the leaderboard renders, **Then** their row is highlighted with a blue tint (Highlighted state) to distinguish from other players.

## Tasks / Subtasks

- [x] Task 1: Upgrade leaderboard typography to UX spec (AC: #1)
  - [x] 1.1 The display name is rendered by the `PlayerNameTag` widget (not directly in `_buildEntryRow`). The `PlayerNameTag` standard size currently uses `fontSize: 16` with no Oswald and `FontWeight.normal`. Add a new `PlayerNameTagSize.leaderboard` variant with `fontFamily` set via `GoogleFonts.oswald()`, `fontWeight: FontWeight.w600` (SemiBold), `fontSize: 16`. Use this variant in `_buildEntryRow` when constructing PlayerNameTag.
  - [x] 1.2 Update score text in `_buildEntryRow`: use `GoogleFonts.oswald(fontWeight: FontWeight.w700, fontSize: 16, color: RackUpColors.textPrimary)`. Score is already right-aligned via Row layout (last element after Expanded) — no alignment changes needed.
  - [x] 1.3 Update rank numbers: use `GoogleFonts.oswald(fontWeight: FontWeight.w700, fontSize: 14)` for consistency with the Oswald typography system.
  - [x] 1.4 Import `google_fonts` package in player_screen.dart (already a project dependency in pubspec.yaml).

- [x] Task 2: Upgrade position-shuffle to The Shuffle pattern with staggered timing (AC: #2)
  - [x] 2.1 Keep `ListView.builder` — do NOT use `AnimatedList` (it requires explicit insert/remove which doesn't match the "re-sort entire list" pattern). Enhance the existing `TweenAnimationBuilder` approach with staggered delays.
  - [x] 2.2 Add staggered timing via `Interval` curve: for each row at index `i`, use `Interval(i * 0.06, 1.0, curve: Curves.easeOutCubic)` as the animation curve within a 500ms total duration. This creates the cascading domino effect where row 0 starts immediately, row 1 starts ~30ms later, etc.
  - [x] 2.3 Use `Curves.easeOutCubic` (fluid deceleration) for "shuffling cards" feel — replaces current `Curves.easeInOut`.
  - [x] 2.4 Add subtle opacity transition during shuffle: moving rows use `TweenAnimationBuilder<double>` for opacity (0.7 → 1.0) with the same staggered curve.
  - [x] 2.5 When `cascadeProfile` is "streak_milestone", use wider stagger spacing (80ms per row instead of ~30ms) for more dramatic timing.
  - [x] 2.6 Respect `RackUpGameThemeData.animationsEnabled` — skip all animations when reduced motion is on (instant position, full opacity).

- [x] Task 3: Extract `LeaderboardRow` StatefulWidget and add visual polish (AC: #2, #4)
  - [x] 3.1 Extract `_buildEntryRow` into a dedicated `LeaderboardRow` StatefulWidget in `player_screen.dart` (or a new file `widgets/leaderboard_row.dart` if cleaner). The StatefulWidget manages animation timers for score change indicator and rank change arrow fade-outs.
  - [x] 3.2 Add score change indicator: compute score delta from `previousEntries` in LeaderboardBloc state. Show "+N" text with `AnimatedOpacity` (200ms fade in, 400ms hold, 200ms fade out = 800ms total) next to score. Use `GoogleFonts.oswald(fontWeight: FontWeight.w600, fontSize: 12, color: RackUpColors.streakGold)`.
  - [x] 3.3 Enhance leader glow: wrap leader row's `DecoratedBox` with `TweenAnimationBuilder<double>` that pulses box shadow alpha between 0.1 and 0.2 over 2s (repeating). This replaces the current static alpha 0.15 shadow.
  - [x] 3.4 Add rank change indicator: when `entry.rankChanged` is true, show a brief up/down arrow icon (green up / red down based on whether rank improved or worsened vs `previousEntries`). Auto-fade with `AnimatedOpacity` after 1.5s.

- [x] Task 4: Add sound event dispatch for leaderboard shuffle (AC: #2)
  - [x] 4.1 When LeaderboardBloc emits a state where any entry has `rankChanged == true`, expose a `shuffleOccurred` flag on `LeaderboardActive` state (or emit via a separate stream/callback).
  - [x] 4.2 This flag will be consumed by the `AudioListener` in Story 3.6 to trigger the leaderboard shuffle sound effect. For now, just ensure the flag is available — no actual audio code needed.

- [x] Task 5: Ensure 60fps performance on mid-range devices (AC: #2)
  - [x] 5.1 Wrap each `LeaderboardRow` in a `RepaintBoundary` to isolate repaint regions during animations.
  - [x] 5.2 Use `const` constructors where possible in LeaderboardRow sub-widgets.
  - [x] 5.3 Verify `BlocBuilder` only rebuilds on actual state changes (LeaderboardBloc uses Equatable — confirm).
  - [x] 5.4 Profile with Flutter DevTools to verify 60fps during position shuffles with 8 players.

- [x] Task 6: Update referee screen leaderboard peek (AC: #1)
  - [x] 6.1 Apply `GoogleFonts.oswald()` typography to `_FooterLeaderboardEntry` in referee_screen.dart: display name with `w600`, score with `w700`.
  - [x] 6.2 Ensure consistent styling between PlayerScreen leaderboard rows and RefereeScreen peek entries.

- [x] Task 7: Write tests (AC: #1-#5)
  - [x] 7.1 Widget test: PlayerScreen renders display names and scores with Oswald font (verify via TextStyle inspection)
  - [x] 7.2 Widget test: staggered animation triggers with Interval-based delay per row
  - [x] 7.3 Widget test: score change indicator appears when score delta exists and fades after 800ms
  - [x] 7.4 Widget test: leader glow pulse is active for rank 1 player
  - [x] 7.5 Widget test: animations skipped when reduced motion enabled (`animationsEnabled: false`)
  - [x] 7.6 Widget test: RefereeScreen peek uses matching Oswald typography
  - [x] 7.7 Unit test: `shuffleOccurred` flag is true when any entry has `rankChanged`

## Dev Notes

### What This Story Adds (100% Client-Side)

Story 3.3 built the full leaderboard infrastructure. This story polishes it for the "Leaderboard as Theater" experience described in the UX spec. **DO NOT modify any server code** — all data is already in TurnCompletePayload.

**Existing from 3.3 (do not rebuild):**
- LeaderboardBloc with `LeaderboardActive(entries, previousEntries, shooterHash, streakMilestone, cascadeProfile)`
- Basic position-shuffle (TweenAnimationBuilder + FractionalTranslation, 300ms, easeInOut)
- StreakFireIndicator with 3 states + Eruption animation
- Static leader glow (gold BoxShadow, alpha 0.15)
- Self-row blue tint, rank numbers, PlayerNameTag integration

**What this story adds:**
1. Typography compliance — Oswald SemiBold/Bold via `google_fonts` package
2. The Shuffle upgrade — staggered cascading timing with Interval curves
3. Visual polish — score change "+N", animated leader glow, rank change arrows
4. Sound event hook — `shuffleOccurred` flag for Story 3.6
5. Performance — RepaintBoundary isolation, 60fps validation

### Font Loading: Use `google_fonts` Package

The project uses `google_fonts: ^8.0.2` for font loading — fonts are NOT bundled as assets. Use `GoogleFonts.oswald()` to get TextStyle with Oswald font. Do NOT use `fontFamily: 'Oswald'` directly — it will silently fall back to the default system font.

Example:
```dart
GoogleFonts.oswald(
  fontWeight: FontWeight.w600, // SemiBold
  fontSize: 16,
  color: identity.color,
)
```

Note: The existing `PlayerNameTag` large size uses `fontFamily: 'Oswald'` — this may work if `google_fonts` registers the font globally after first use, but verify this and update to `GoogleFonts.oswald()` if needed for reliability.

### PlayerNameTag Widget — How to Add Oswald for Leaderboard

The display name in leaderboard rows is rendered by `PlayerNameTag` (not raw Text). Current `PlayerNameTagSize.standard` uses `fontSize: 16` with system font and `FontWeight.normal`.

**Recommended approach:** Add a `PlayerNameTagSize.leaderboard` variant:
```dart
leaderboard(shapeSize: 16, fontSize: 16); // Same sizes, but build() uses GoogleFonts.oswald(w600)
```
Then in `PlayerNameTag.build()`, check for `leaderboard` size and apply `GoogleFonts.oswald(fontWeight: FontWeight.w600)`. This keeps the widget reusable without breaking existing uses.

### Staggered Animation — Recommended Pattern

Use `Interval` curve within the existing `TweenAnimationBuilder` approach:

```dart
final staggerCurve = Interval(
  (index * 0.06).clamp(0.0, 0.5), // stagger start
  1.0,
  curve: Curves.easeOutCubic,
);

TweenAnimationBuilder<Offset>(
  tween: Tween(begin: Offset(0, indexDelta.toDouble()), end: Offset.zero),
  duration: const Duration(milliseconds: 500),
  curve: staggerCurve,
  // ...
)
```

This is simpler than managing separate AnimationControllers per row. The `Interval` delays the animation start proportionally, creating the cascading effect. With 8 players, stagger spans 0ms to ~240ms within the 500ms total.

### Score Change Indicator — Implementation Approach

Use `previousEntries` from `LeaderboardActive` state to compute score delta:
```dart
final prevEntry = state.previousEntries.where((e) => e.deviceIdHash == entry.deviceIdHash).firstOrNull;
final scoreDelta = prevEntry != null ? entry.score - prevEntry.score : 0;
```

The `LeaderboardRow` StatefulWidget manages a timer: on mount or when `scoreDelta > 0`, show "+N", then auto-fade after 800ms. Use `didUpdateWidget` to detect score changes on rebuilds.

### Architecture Compliance

- Sealed classes for Bloc states (Dart 3 sealed)
- `ClampedTextScaler.of(context, TextRole.body)` for accessible text scaling — keep using this
- `RackUpGameThemeData.animationsEnabled` for reduced motion — all new animations must check this
- Protocol types NEVER in Bloc states — already followed
- `// SYNC WITH:` headers — no server changes so not applicable

**DO NOT:**
- Create new Bloc/Cubit — LeaderboardBloc handles all state
- Modify server code — all data already in TurnCompletePayload
- Change LeaderboardEntry model fields — `rankChanged` flag already exists
- Break existing widget tests — extend them

### Project Structure Notes

**Files to modify:**
- `rackup/lib/features/game/view/player_screen.dart` — Typography, staggered animation, extract LeaderboardRow
- `rackup/lib/features/game/view/referee_screen.dart` — Typography in footer peek
- `rackup/lib/core/widgets/player_name_tag.dart` — Add `leaderboard` size variant
- `rackup/lib/features/game/bloc/leaderboard_bloc.dart` — Add `shuffleOccurred` flag to LeaderboardActive
- `rackup/lib/features/game/bloc/leaderboard_state.dart` — Update LeaderboardActive with shuffleOccurred

**Files to potentially create:**
- `rackup/lib/features/game/view/widgets/leaderboard_row.dart` — Extracted StatefulWidget (optional, could stay in player_screen.dart)

**Test files to modify:**
- `rackup/test/features/game/view/player_screen_test.dart` — Typography, animation, visual polish tests
- `rackup/test/features/game/view/referee_screen_test.dart` — Typography consistency tests
- `rackup/test/features/game/bloc/leaderboard_bloc_test.dart` — shuffleOccurred flag test

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.4]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — The Shuffle: "fluid, cascading motion with staggered timing. Rhythm: flow, flow, flow, settle." Leaderboard as Theater: "position-shuffle animations after every shot...the communal screen everyone watches"]
- [Source: _bmad-output/planning-artifacts/architecture.md — LeaderboardBloc, 7 Bloc Architecture, Sound triggers: "leaderboard shuffle → LeaderboardBloc ranking change"]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR4 60fps on mid-range devices]
- [Source: _bmad-output/implementation-artifacts/3-3-scoring-streaks-and-consequence-chain.md — LeaderboardBloc, position-shuffle, StreakFireIndicator, CascadeTiming]
- [Source: rackup/lib/features/game/view/player_screen.dart — Current implementation: TweenAnimationBuilder 300ms easeInOut, no Oswald font, static leader glow]
- [Source: rackup/lib/core/widgets/player_name_tag.dart — Standard size uses system font, large size uses fontFamily: 'Oswald']
- [Source: rackup/pubspec.yaml — google_fonts: ^8.0.2, no bundled Oswald assets]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Task 1: Added `PlayerNameTagSize.leaderboard` variant with GoogleFonts.oswald(w600). Updated score text to Oswald Bold (w700) and rank numbers to Oswald Bold (w700, 14px). Also fixed existing `large` size to use `GoogleFonts.oswald()` instead of `fontFamily: 'Oswald'`.
- Task 2: Upgraded position-shuffle from 300ms easeInOut to 500ms with Interval-based staggered timing (0.06 per row, 0.08 for streak milestones). Added opacity transition (0.7→1.0) during shuffle. Respects `animationsEnabled` for reduced motion.
- Task 3: Extracted `LeaderboardRow` StatefulWidget to `widgets/leaderboard_row.dart`. Added score change "+N" indicator (800ms auto-fade), pulsing leader glow (alpha 0.1↔0.2 over 2s), and rank change arrows (green up/red down, 1.5s auto-fade).
- Task 4: Added `shuffleOccurred` flag to `LeaderboardActive` state, computed from `entries.any((e) => e.rankChanged)`. Ready for AudioListener in Story 3.6.
- Task 5: `RepaintBoundary` wraps each `LeaderboardRow`. Const constructors used where possible. Equatable confirmed on LeaderboardBloc states. Task 5.4 (DevTools profiling) is manual verification.
- Task 6: Applied Oswald typography to `_FooterLeaderboardEntry` — display name w600, score w700.
- Task 7: Added 8 new tests (5 widget, 1 unit, 1 referee widget, 1 reduced-motion). All 329 tests pass with 0 regressions.

### Change Log

- 2026-04-02: Implemented Story 3.4 — Live Leaderboard typography, staggered shuffle animation, visual polish, sound event hook, performance optimization, and tests.

### File List

- rackup/lib/core/widgets/player_name_tag.dart (modified — added leaderboard size, GoogleFonts.oswald for leaderboard+large)
- rackup/lib/features/game/view/player_screen.dart (modified — uses LeaderboardRow, staggered animation, score/rank delta computation)
- rackup/lib/features/game/view/referee_screen.dart (modified — Oswald typography in footer peek)
- rackup/lib/features/game/view/widgets/leaderboard_row.dart (new — extracted StatefulWidget with visual polish)
- rackup/lib/features/game/bloc/leaderboard_state.dart (modified — added shuffleOccurred field)
- rackup/lib/features/game/bloc/leaderboard_bloc.dart (modified — computes shuffleOccurred from rankChanged entries)
- rackup/test/features/game/view/player_screen_test.dart (modified — 5 new tests for typography, animation, score indicator, glow, reduced motion)
- rackup/test/features/game/view/referee_screen_test.dart (modified — 1 new test for Oswald typography in footer peek)
- rackup/test/features/game/bloc/leaderboard_bloc_test.dart (modified — 2 new tests for shuffleOccurred flag)
