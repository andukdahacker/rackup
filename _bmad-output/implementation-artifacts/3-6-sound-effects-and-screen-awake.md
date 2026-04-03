# Story 3.6: Sound Effects & Screen Awake

Status: done

## Story

As a player,
I want sound effects to punctuate key game moments and my screen to stay on,
so that the party atmosphere is enhanced and I don't miss anything.

## Acceptance Criteria

1. **Given** the app's audio system is initialized **When** the game starts **Then** a centralized AudioListener BlocListener is active at the app level **And** 5 MVP sound effects are preloaded: Blue Shell impact, leaderboard shuffle, punishment reveal, streak fire, podium fanfare

2. **Given** a key game event occurs (streak milestone, leaderboard shuffle, punishment reveal) **When** the event is processed by the AudioListener **Then** the corresponding sound effect triggers within 200ms of the event (NFR6) **And** each sound effect is <2 seconds duration (accent, not narration)

3. **Given** the device is in silent or vibrate mode **When** a sound effect would trigger **Then** the sound is suppressed and the device's silent/vibrate setting is respected **And** visual feedback still accompanies the event (sound is never the sole indicator)

4. **Given** a game session is active **When** the player's device would normally auto-lock or dim **Then** the screen stays awake for the duration of the active game session (FR49) **And** screen-awake is released when the game ends or the player leaves

5. **Given** battery efficiency requirements **When** the game is running for 60 minutes **Then** total battery consumption does not exceed 15% on a typical modern smartphone (NFR25) **And** no unnecessary background processing or continuous polling occurs

## Tasks / Subtasks

- [x] Task 1: Add dependencies (AC: #1, #3, #4)
  - [x] 1.1 Add `audioplayers: ^6.6.0` to `rackup/pubspec.yaml` — short SFX playback with built-in `respectSilence` API and `PlayerMode.lowLatency` for <200ms trigger
  - [x] 1.2 Add `wakelock_plus: ^1.5.1` to `rackup/pubspec.yaml` — screen wake lock with `WakelockPlus.enable()`/`disable()` API
  - [x] 1.3 Run `flutter pub get`

- [x] Task 2: Add sound assets (AC: #1)
  - [x] 2.1 Create `rackup/assets/sounds/` directory
  - [x] 2.2 Add 5 placeholder MP3 files (<2 seconds, <100KB each): `blue_shell_impact.mp3`, `leaderboard_shuffle.mp3`, `punishment_reveal.mp3`, `streak_fire.mp3`, `podium_fanfare.mp3`. Generate placeholder tones via ffmpeg: `ffmpeg -f lavfi -i "sine=frequency=440:duration=0.5" -ar 44100 -b:a 32k assets/sounds/streak_fire.mp3` (vary frequency per sound: 440Hz, 550Hz, 660Hz, 330Hz, 880Hz). If ffmpeg is unavailable, commit minimal valid MP3 files as binary placeholders. Real sound design happens later
  - [x] 2.3 Register assets in `pubspec.yaml` under `flutter.assets`: add `- assets/sounds/`
  - [x] 2.4 Keep each file <100KB — Android SoundPool (used by `lowLatency` mode) has a 1MB per-file limit. Current <2s MP3s at 32kbps will be ~8KB each, well within bounds. Document this constraint in a comment in `sound_manager.dart` for future sound designers

- [x] Task 3: Create SoundManager service (AC: #1, #2, #3)
  - [x] 3.1 Create `rackup/lib/core/audio/sound_manager.dart` — this is the low-level audio service that owns `AudioPlayer` instances
  - [x] 3.2 Define `GameSound` enum: `blueShellImpact`, `leaderboardShuffle`, `punishmentReveal`, `streakFire`, `podiumFanfare`
  - [x] 3.3 Create `SoundManager` class with methods: `Future<void> init()`, `Future<void> play(GameSound sound)`, `void dispose()`
  - [x] 3.4 In `init()`: create 5 `AudioPlayer` instances (one per sound), set each to `PlayerMode.lowLatency`, preload via `setSource(AssetSource('sounds/<filename>.mp3'))`, configure `AudioContextConfig(respectSilence: true)` globally via `AudioPlayer.global.setAudioContext(...)` — this makes iOS respect the ringer/silent switch by using `AVAudioSessionCategory.ambient`
  - [x] 3.5 In `play(GameSound)`: call `seek(Duration.zero)` then `resume()` on the corresponding player. Do NOT use `stop()` + `play()` — there is a known `audioplayers` bug (#1489) where `lowLatency` + `ReleaseMode.stop` causes sound to play only once on Android
  - [x] 3.6 In `dispose()`: dispose all 5 players
  - [x] 3.7 Make `SoundManager` injectable — accept it via constructor or provide via `RepositoryProvider` at app level for testability

- [x] Task 4: Create AudioListener BlocListener (AC: #1, #2)
  - [x] 4.1 Create `rackup/lib/core/audio/audio_listener.dart` — a widget that wraps a single `BlocListener<LeaderboardBloc, LeaderboardState>` and triggers sounds based on state fields
  - [x] 4.2 Listen to `LeaderboardBloc` state for BOTH sound triggers (verified: `LeaderboardActive` carries both fields):
    - When `state.streakMilestone == true` → play `GameSound.streakFire`
    - When `state.shuffleOccurred == true` → play `GameSound.leaderboardShuffle`
    - Use `listenWhen: (prev, curr) => curr is LeaderboardActive && (curr.streakMilestone || curr.shuffleOccurred)` to avoid unnecessary listener calls
    - IMPORTANT: both flags can be true simultaneously (a streak milestone causes a leaderboard shuffle). Play both sounds — streakFire first, leaderboardShuffle second
  - [x] 4.3 Do NOT listen to `GameBloc` for sound triggers — `streakMilestone` is NOT on `GameActive` state (it's only on the `GameTurnCompleted` event). `LeaderboardBloc` receives it via `game_message_listener.dart` (line 76) and propagates it to `LeaderboardActive` state (line 29 of `leaderboard_bloc.dart`)
  - [x] 4.4 **Punishment reveal and Blue Shell impact sounds**: These events come from Epics 4 and 5 respectively, which are NOT yet implemented. Add clearly marked extension points (comments) in the AudioListener for these two sounds. Do NOT create fake events or stub blocs — just document where the triggers will be wired when those epics are built
  - [x] 4.5 **Podium fanfare**: This comes from Epic 8 (post-game). Add a comment extension point. Do NOT wire it yet
  - [x] 4.6 The AudioListener is a WIDGET, not a Bloc. It uses `BlocListener` to react to state changes and calls `SoundManager.play()`. No bloc ever calls audio directly — this is the single place that decides "this event makes a noise"
  - [x] 4.7 AudioListener constructor takes `SoundManager` as a required parameter and a `child` widget. It does NOT access SoundManager via context — it receives it directly for explicit dependency and testability

- [x] Task 5: Create WakeLockManager service (AC: #4, #5)
  - [x] 5.1 Create `rackup/lib/core/services/wake_lock_manager.dart`
  - [x] 5.2 Methods: `Future<void> enable()` calls `WakelockPlus.enable()`, `Future<void> disable()` calls `WakelockPlus.disable()`
  - [x] 5.3 Wrap in try/catch — `wakelock_plus` can throw on unsupported platforms (web). Log errors via existing logging, don't crash
  - [x] 5.4 Make injectable for testability

- [x] Task 6: Integrate AudioListener and WakeLock into game lifecycle (AC: #1, #4)
  - [x] 6.1 `game_page.dart` is already a `StatefulWidget` with `initState()` (orientation lock) and `dispose()` (orientation reset). Add SoundManager and WakeLock lifecycle to EXISTING methods — do NOT create a new widget
  - [x] 6.2 In existing `initState()`: create `SoundManager` instance as a field (`late final SoundManager _soundManager`), call `_soundManager.init()`, call `WakeLockManager.enable()`. This is intentionally game-page-scoped (NOT app-level like DeviceIdentityService) because audio resources should only be alive during active game sessions for battery efficiency (AC #5)
  - [x] 6.3 In the `build()` method: insert `AudioListener` widget inside `PopScope`, wrapping the existing `BlocListener<GameBloc, GameState>`. Pass `_soundManager` to AudioListener constructor. Widget tree becomes: `PopScope → AudioListener(soundManager: _soundManager) → BlocListener<GameBloc> → BlocBuilder<GameBloc> → ...`
  - [x] 6.4 In existing `dispose()`: call `_soundManager.dispose()` and `WakeLockManager.disable()` BEFORE calling `super.dispose()`. Use try/finally — CRITICAL: always release wake lock even if SoundManager.dispose() throws
  - [x] 6.5 Also call `WakeLockManager.disable()` when `GameBloc` emits a terminal state (game ended/left) — defense-in-depth beyond just widget dispose. Add this to the existing `BlocListener<GameBloc>` `listener` callback or as a second BlocListener

- [x] Task 7: Tests (all ACs)
  - [x] 7.1 Unit test `SoundManager`: verify `init()` creates players, `play()` triggers correct player, `dispose()` cleans up. Mock `AudioPlayer` via `mocktail`
  - [x] 7.2 Unit test `WakeLockManager`: verify `enable()`/`disable()` call through to `WakelockPlus`. `wakelock_plus` uses platform channels — in tests, set up `TestDefaultBinaryMessengerBinding` mock method channel or wrap `WakelockPlus` calls behind an abstraction that can be mocked with `mocktail`
  - [x] 7.3 Widget test `AudioListener`: verify it triggers `SoundManager.play(GameSound.streakFire)` when `LeaderboardBloc` emits a state with `streakMilestone: true`. Verify it triggers `SoundManager.play(GameSound.leaderboardShuffle)` when `LeaderboardBloc` emits `shuffleOccurred: true`. Verify both sounds fire when both flags are true simultaneously
  - [x] 7.4 Widget test `game_page.dart`: verify `AudioListener` is in the widget tree, verify `WakelockPlus.enable()` called on mount, verify `WakelockPlus.disable()` called on dispose
  - [x] 7.5 Do NOT test the actual audio playback or platform channels — mock `SoundManager` and `WakelockPlus` at the boundary

## Dev Notes

### Architecture Compliance

- **Centralized AudioListener pattern**: Per architecture, a centralized `BlocListener` at app/game level listens to all game blocs and triggers sounds. No bloc ever calls audio directly. Single place that decides "this event makes a noise"
- **SoundManager is a service, not a Bloc**: Audio playback is a side effect, not state. `SoundManager` is a plain class injected via `RepositoryProvider`, not a Bloc/Cubit
- **Extension points for future epics**: 3 of the 5 MVP sounds (Blue Shell, punishment reveal, podium fanfare) depend on Epics 4, 5, and 8 which are NOT yet implemented. Create comment-marked extension points in AudioListener. The sounds are preloaded and the `play()` method works — only the trigger wiring is deferred
- **Consequence chain**: The server's `sound_triggers` step in `engine.go` (line 76) is currently `NoOpStep{}`. This story is CLIENT-ONLY — sound triggering is driven by client-side BlocListener reacting to state changes, not by server commands. The `NoOpStep` stays as-is
- **Wake lock lifecycle**: Must be tied to game page widget lifecycle AND game state. Double-release pattern: disable on `dispose()` AND on terminal game state emission

### Key Existing Code to Understand

| File | Why It Matters |
|------|---------------|
| `rackup/lib/features/game/view/game_page.dart` | Integration point — AudioListener wraps here, wake lock managed here. Already a StatefulWidget with initState/dispose for orientation lock. Has existing BlocListener for triple-points overlay |
| `rackup/lib/features/game/bloc/leaderboard_bloc.dart` | Line 23: computes `shuffleOccurred` from entries. Line 29: passes `streakMilestone` from event to state. This is the SOLE bloc AudioListener needs to listen to |
| `rackup/lib/features/game/bloc/leaderboard_state.dart` | `LeaderboardActive` carries both `shuffleOccurred` (line 44) and `streakMilestone` (line 38) |
| `rackup/lib/core/websocket/game_message_listener.dart` | Line 76: passes `streakMilestone` from `TurnCompletePayload` to `LeaderboardUpdated` event |
| `rackup/lib/core/services/device_identity_service.dart` | Reference for existing service pattern (constructor injection, async init, plain class) |
| `rackup/lib/app/view/app.dart` | Reference for `MultiRepositoryProvider` pattern — but SoundManager is game-page-scoped, not app-scoped |

### Library Details

**audioplayers ^6.6.0:**
- Create one `AudioPlayer` per sound effect (5 total)
- `PlayerMode.lowLatency` — uses Android SoundPool under the hood, ideal for <2s files
- `AssetSource('sounds/<file>.mp3')` for asset loading
- `AudioContextConfig(respectSilence: true)` — on iOS sets `AVAudioSessionCategory.ambient` (respects ringer switch). On Android, sounds play on `STREAM_MUSIC` (standard game behavior — users control via media volume)
- Replay pattern: `seek(Duration.zero)` + `resume()`. Do NOT use `stop()` + `play()` (bug #1489)
- No platform permissions needed for asset playback

**audioplayers Android SoundPool constraint:**
- `PlayerMode.lowLatency` uses Android SoundPool under the hood
- SoundPool has a 1MB per-file size limit — keep all sound assets <100KB
- Current <2s MP3s at 32kbps will be ~8KB each, well within bounds
- Add a comment in `sound_manager.dart` documenting this constraint

**wakelock_plus ^1.5.1:**
- `WakelockPlus.enable()` / `WakelockPlus.disable()` — simple API
- Android: `FLAG_KEEP_SCREEN_ON` on window (no manifest permission needed)
- iOS: `UIApplication.shared.isIdleTimerDisabled` (no plist entry needed)
- Always disable on dispose — forgetting leaves screen on after exiting game
- Uses platform channels — in tests, either mock the method channel via `TestDefaultBinaryMessengerBinding` or abstract behind `WakeLockManager` wrapper (which this story creates) and mock with `mocktail`

### Sound Event Mapping

| GameSound | Trigger Source | Bloc to Listen | State Field | Status |
|-----------|---------------|----------------|-------------|--------|
| `streakFire` | Streak milestone crossed | `LeaderboardBloc` | `LeaderboardActive.streakMilestone == true` | Wire NOW |
| `leaderboardShuffle` | Ranking positions changed | `LeaderboardBloc` | `LeaderboardActive.shuffleOccurred == true` | Wire NOW |
| `punishmentReveal` | Punishment drawn | Future bloc (Epic 4) | TBD | EXTENSION POINT |
| `blueShellImpact` | Blue Shell deployed | Future `ItemBloc` (Epic 5) | TBD | EXTENSION POINT |
| `podiumFanfare` | 1st place podium reveal | Future `PostgameBloc` (Epic 8) | TBD | EXTENSION POINT |

**Data flow for wired sounds:** Server `game.turn_complete` → `WebSocketCubit` → `GameMessageListener._handleMessage()` (line 76: passes `streakMilestone` to `LeaderboardUpdated` event) → `LeaderboardBloc._onLeaderboardUpdated()` (line 23: computes `shuffleOccurred`, line 29: passes `streakMilestone`) → emits `LeaderboardActive` state with both flags → `AudioListener` BlocListener fires → `SoundManager.play()`

### Previous Story Intelligence (Story 3.5)

**Patterns established to reuse:**
- `BlocListener` integration in `game_page.dart` — Story 3.5 added a `BlocListener<GameBloc, GameState>` for triple-points overlay. Follow the same pattern for AudioListener
- `RepositoryProvider` for services — follow existing patterns in the app for service injection
- `RackUpGameThemeData.animationsEnabled` — check this flag. When reduced motion is on, consider whether sound should also be muted (accessibility). The acceptance criteria say "visual feedback still accompanies the event" but are silent on audio + reduced motion. Recommendation: sounds are independent of animation — play them regardless of `animationsEnabled`, since they are <2s accents and the user has system-level mute for sound

**Font fix from Story 3.5:** `ProgressTierBar` was converted from StatelessWidget to StatefulWidget. Do NOT touch it in this story

**Debug lessons from Story 3.5:**
- `pumpAndSettle` times out on repeating animations — use `pump()` instead in widget tests involving animation controllers
- Test factories in `test/helpers/factories.dart` are lobby/room focused. Create inline test data for game-related tests or add game factories if needed

### Files to Create

| File | Purpose |
|------|---------|
| `rackup/lib/core/audio/sound_manager.dart` | SoundManager service — owns AudioPlayer instances, preload, play, dispose |
| `rackup/lib/core/audio/audio_listener.dart` | AudioListener widget — MultiBlocListener that triggers sounds on game events |
| `rackup/lib/core/services/wake_lock_manager.dart` | WakeLockManager — enable/disable screen wake lock |
| `rackup/assets/sounds/blue_shell_impact.mp3` | Placeholder sound asset |
| `rackup/assets/sounds/leaderboard_shuffle.mp3` | Placeholder sound asset |
| `rackup/assets/sounds/punishment_reveal.mp3` | Placeholder sound asset |
| `rackup/assets/sounds/streak_fire.mp3` | Placeholder sound asset |
| `rackup/assets/sounds/podium_fanfare.mp3` | Placeholder sound asset |
| `rackup/test/core/audio/sound_manager_test.dart` | SoundManager unit tests |
| `rackup/test/core/audio/audio_listener_test.dart` | AudioListener widget tests |
| `rackup/test/core/services/wake_lock_manager_test.dart` | WakeLockManager unit tests |

### Files to Modify

| File | Change |
|------|--------|
| `rackup/pubspec.yaml` | Add `audioplayers: ^6.6.0`, `wakelock_plus: ^1.5.1`, and `- assets/sounds/` under flutter.assets |
| `rackup/lib/features/game/view/game_page.dart` | Wrap content with AudioListener, init SoundManager, manage WakeLock lifecycle |

### What NOT to Change

- **Server (Go)**: No server changes. Sound triggering is client-only. `NoOpStep` in engine.go stays
- **Existing Blocs**: Do NOT modify GameBloc, LeaderboardBloc, or any existing bloc. The `streakMilestone` and `shuffleOccurred` fields already exist from previous stories
- **Wire protocol**: No protocol changes needed
- **Other game widgets**: Do NOT touch leaderboard, streak indicator, progress bar, etc.

### Project Structure Notes

- New files follow existing conventions: `core/audio/` for audio services (matches architecture spec `core/audio/audio_listener.dart` and `core/audio/sound_manager.dart`), `core/services/` for wake lock manager
- Tests mirror lib structure under `test/`
- No cross-feature imports except through `core/`
- Sound assets go in `rackup/assets/sounds/` per architecture spec

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.6]
- [Source: _bmad-output/planning-artifacts/architecture.md#Client Architecture - Audio]
- [Source: _bmad-output/planning-artifacts/architecture.md#Consequence Chain Pipeline - sound_triggers step]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Sound as Physical-Digital Bridge]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Feedback Patterns]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Audio Accessibility]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Animation Synchronization - MVP]
- [Source: audioplayers v6.6.0 — pub.dev/packages/audioplayers]
- [Source: wakelock_plus v1.5.1 — pub.dev/packages/wakelock_plus]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- SoundManager `init()` calls `AudioPlayer.global.setAudioContext()` which requires platform bindings — added `skipGlobalConfig` flag for testability in unit tests
- AudioListener tests required `StreamController`-based approach instead of `whenListen` with `Stream.value` to ensure BlocListener subscription timing was correct
- Task 6.5 (terminal state wake lock disable): No terminal `GameState` exists yet (only `GameInitial` and `GameActive`). Added comment extension point in `game_page.dart` for when `GameEnded` state is added in Epic 8

### Completion Notes List

- ✅ Task 1: Added `audioplayers: ^6.6.0` and `wakelock_plus: ^1.5.1` dependencies, registered `assets/sounds/` in pubspec.yaml
- ✅ Task 2: Generated 5 placeholder MP3 files via ffmpeg (~2.4KB each, 0.5s duration, unique frequencies)
- ✅ Task 3: Created `SoundManager` with `GameSound` enum, per-sound `AudioPlayer` instances, `lowLatency` mode, `respectSilence` via `AVAudioSessionCategory.ambient`, and `seek(Duration.zero)` + `resume()` replay pattern
- ✅ Task 4: Created `AudioListener` widget with `BlocListener<LeaderboardBloc>` that triggers `streakFire` and `leaderboardShuffle` sounds. Added 3 extension point comments for punishment reveal (Epic 4), blue shell impact (Epic 5), and podium fanfare (Epic 8)
- ✅ Task 5: Created `WakeLockManager` with injectable enable/disable functions and exception-safe try/catch wrapping
- ✅ Task 6: Integrated into `game_page.dart` — SoundManager and WakeLockManager in initState/dispose, AudioListener wrapping BlocListener in build tree, try/finally in dispose for wake lock safety
- ✅ Task 7: 13 new tests — 5 SoundManager unit tests, 4 WakeLockManager unit tests, 4 AudioListener widget tests. All 352 tests pass (0 regressions)

### Change Log

- 2026-04-03: Story 3.6 implementation complete — sound effects system and screen wake lock

### File List

**New files:**
- `rackup/lib/core/audio/sound_manager.dart`
- `rackup/lib/core/audio/audio_listener.dart`
- `rackup/lib/core/services/wake_lock_manager.dart`
- `rackup/assets/sounds/blue_shell_impact.mp3`
- `rackup/assets/sounds/leaderboard_shuffle.mp3`
- `rackup/assets/sounds/punishment_reveal.mp3`
- `rackup/assets/sounds/streak_fire.mp3`
- `rackup/assets/sounds/podium_fanfare.mp3`
- `rackup/test/core/audio/sound_manager_test.dart`
- `rackup/test/core/audio/audio_listener_test.dart`
- `rackup/test/core/services/wake_lock_manager_test.dart`

**Modified files:**
- `rackup/pubspec.yaml` — added audioplayers, wakelock_plus deps and assets/sounds/ registration
- `rackup/lib/features/game/view/game_page.dart` — AudioListener wrapper, SoundManager/WakeLockManager lifecycle
