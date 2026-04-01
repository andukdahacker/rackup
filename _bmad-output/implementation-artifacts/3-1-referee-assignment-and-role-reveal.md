# Story 3.1: Referee Assignment & Role Reveal

Status: done

## Story

As a player,
I want to know who the referee is when the game starts,
So that everyone understands their role and the game can begin.

## Acceptance Criteria

1. **Given** the host has started the game **When** the server initializes the game state **Then** one player is assigned the referee role **And** the server tracks which client holds referee authority **And** the server rejects referee actions from non-authoritative clients.

2. **Given** a player is assigned as referee **When** the role is assigned **Then** a full-screen Role Reveal Overlay displays: microphone emoji (48dp), "YOU'RE THE REFEREE NOW" (Oswald Bold 42dp, gold), the referee's name in their identity color, and a gold horizontal rule **And** The Reveal animation plays with a 2-second hold **And** the overlay auto-dismisses with no interaction required **And** the referee's screen transitions to the 4-region Referee Command Center layout: Status Bar (~60dp top), Stage Area (~40% upper-middle showing current shooter), Action Zone (~35% lower-middle), Footer (~80dp bottom with leaderboard peek).

3. **Given** a player is NOT the referee **When** the game starts **Then** their screen displays the 4-region Player Screen layout: Header (~60dp with game progress), Leaderboard (~50% upper), Event Feed (~25% middle), My Status (~15% bottom) **And** all screens are portrait-locked with dark base canvas.

4. **Given** the game has started **When** either screen layout renders **Then** the Progress/Tier Bar shows at the top with the current round label ("R1/10" format) **And** the tier is set to Mild with teal color **And** no back navigation, settings menu, or navigation stack is available (linear flow).

## Tasks / Subtasks

- [x] Task 1: Protocol layer — game initialization actions and payloads (AC: #1)
  - [x] 1.1 Add `gameInitialized` constant in `actions.dart` — server→client broadcast (`"game.initialized"`)
  - [x] 1.2 Add corresponding `ActionGameInitialized` in Go `actions.go`
  - [x] 1.3 Add `GameInitializedPayload` class in Dart `messages.dart` — fields: `roundCount: int`, `refereeDeviceIdHash: String`, `turnOrder: List<String>` (device ID hashes in play order), `currentShooterDeviceIdHash: String`, `players: List<GamePlayerPayload>` (with score=0, streak=0)
  - [x] 1.4 Add Go `GameInitializedPayload` struct in `messages.go` — fields: `RoundCount int`, `RefereeDeviceIdHash string`, `TurnOrder []string`, `CurrentShooterDeviceIdHash string`, `Players []GamePlayerPayload`
  - [x] 1.5 Add `GamePlayerPayload` in both Dart and Go — fields: `deviceIdHash: String`, `displayName: String`, `slot: int`, `score: int`, `streak: int`, `isReferee: bool`
  - [x] 1.6 Add `refereeAction` constant in `actions.dart` for future referee actions (`"referee.*"` namespace) — for now just define `refereeConfirmShot` placeholder to validate authority rejection in AC #1
  - [x] 1.7 Ensure Dart protocol files maintain `// SYNC WITH: rackup-server/internal/protocol/messages.go` header comment per architecture mandate

- [x] Task 2: Server game initialization logic (AC: #1)
  - [x] 2.1 Create `rackup-server/internal/game/game_state.go` — `GameState` struct with fields: `RoundCount int`, `CurrentRound int` (starts at 1), `RefereeDeviceIdHash string`, `TurnOrder []string`, `CurrentShooterIndex int`, `Players map[string]*GamePlayer` (deviceIdHash → player game state), `GamePhase string` ("playing", "ended")
  - [x] 2.2 Create `GamePlayer` struct — `DeviceIdHash string`, `DisplayName string`, `Slot int`, `Score int`, `Streak int`, `IsReferee bool`
  - [x] 2.3 Create `NewGameState(players map[string]*PlayerConn, slotAssignments map[string]int, roundCount int, hostDeviceHash string) *GameState` — builds turn order from slot assignments (sorted by slot number ascending), assigns first non-host player as referee (if only 2 players, host is referee), sets first player in turn order as current shooter
  - [x] 2.4 Add `gameState *GameState` field to Room struct in `room.go`
  - [x] 2.5 In `handleStartGame()` after existing validation: call `game.NewGameState(...)`, assign to `r.gameState`, broadcast `game.initialized` payload to all players (in addition to existing `lobby.game_started` broadcast)
  - [x] 2.6 Add referee authority validation: `func (gs *GameState) IsReferee(deviceIdHash string) bool` — returns true only if deviceIdHash matches current referee
  - [x] 2.7 Add a `game.*` action case in `handleClientMessage()` switch — for now, validate referee authority and reject with error code `"NOT_REFEREE"` if non-referee sends referee actions

- [x] Task 3: Game domain models (AC: #2, #3, #4)
  - [x] 3.1 Create `rackup/lib/core/models/game_player.dart` — `GamePlayer` domain model with: `deviceIdHash`, `displayName`, `slot`, `score`, `streak`, `isReferee`. Includes `copyWith()`. This is the game-phase player model (distinct from lobby `Player` model)
  - [x] 3.2 Create `rackup/lib/core/models/game_tier.dart` — `computeTier(int currentRound, int totalRounds)` helper that computes progression percentage (`(currentRound - 1) / totalRounds`) and delegates to existing `EscalationTier` enum from `core/theme/game_theme.dart` via `RackUpGameTheme.tierForProgression(percentage)` (static method on `RackUpGameTheme`, NOT on `RackUpGameThemeData`). DO NOT create a new tier enum — reuse `EscalationTier`
  - [x] 3.3 Add protocol→model mapper: `GameInitializedPayload` → list of `GamePlayer` + game metadata in `mapper.dart`

- [x] Task 4: GameBloc — game session state management (AC: #1, #4)
  - [x] 4.1 Create `rackup/lib/features/game/bloc/game_bloc.dart` — manages game session state
  - [x] 4.2 Create `rackup/lib/features/game/bloc/game_event.dart`:
    - `GameInitialized` (past tense — server event) with: `roundCount`, `refereeDeviceIdHash`, `turnOrder`, `currentShooterDeviceIdHash`, `players: List<GamePlayer>`
  - [x] 4.3 Create `rackup/lib/features/game/bloc/game_state.dart` — sealed states:
    - `GameInitial` (waiting for game data)
    - `GameActive` with: `roundCount`, `currentRound` (=1), `refereeDeviceIdHash`, `currentShooterDeviceIdHash`, `turnOrder`, `players: List<GamePlayer>`, `tier: EscalationTier` (=mild)
  - [x] 4.4 Handler `_onGameInitialized`: emit `GameActive` with all init data, compute initial tier

- [x] Task 5: GameMessageListener — route game messages to blocs (AC: #1)
  - [x] 5.1 Create `rackup/lib/core/websocket/game_message_listener.dart` — instance-based class matching `LobbyMessageListener` pattern: constructor takes `WebSocketCubit` and `GameBloc`, subscribes to `webSocketCubit.messages` stream, has `dispose()` method that cancels subscription
  - [x] 5.2 In `_handleMessage`: switch on `message.action`. Add case for `Actions.gameInitialized`: parse `GameInitializedPayload`, map to domain models via `mapper.dart`, dispatch `GameInitialized` event to GameBloc. Parse in try-catch, silently drop malformed payloads
  - [x] 5.3 Wire in `_RoomShellState` (in `app_router.dart`): create `GameMessageListener` in `didChangeDependencies` (after `GameBloc` is created), dispose in `dispose()`. Note: `LobbyMessageListener` is created in `_LobbyPageState` (lobby_page.dart), NOT in the shell — but `GameMessageListener` should be at the shell level so it receives `game.*` messages even before the game page renders (the `game.initialized` message arrives while navigating from lobby to game)

- [x] Task 6: Use existing RackUpGameTheme — DO NOT CREATE NEW (AC: #4)
  - [x] 6.1 `RackUpGameTheme` InheritedWidget ALREADY EXISTS at `rackup/lib/core/theme/game_theme.dart` with `RackUpGameThemeData`, `EscalationTier` enum, `of(context)` accessor, `tierForProgression()`, `backgroundForTier()`, and `fromProgression()`. DO NOT create a duplicate
  - [x] 6.2 In `GamePage`, wrap game screens with `RackUpGameTheme.fromProgression(percentage: progressionPercentage, animationsEnabled: !MediaQuery.disableAnimations)`. For Story 3.1: pass `percentage: 0.0` (round 1 of N = mild tier). Note: `fromProgression` is a STATIC METHOD on `RackUpGameTheme` (not `RackUpGameThemeData`) and requires TWO named parameters: `percentage` and `animationsEnabled`
  - [x] 6.3 Tier transitions (animating between tiers) are Story 3.5. This story only needs the mild tier

- [x] Task 7: Progress/Tier Bar component (AC: #4)
  - [x] 7.1 Create `rackup/lib/features/game/view/widgets/progress_tier_bar.dart` — ~60dp fixed height bar
  - [x] 7.2 Left side: tier tag badge (MILD text, teal background, Oswald SemiBold 14dp)
  - [x] 7.3 Center: progress bar fill (4dp height, color matches tier)
  - [x] 7.4 Right side: round label "R1/10" format (Oswald SemiBold 14dp)
  - [x] 7.5 Accessibility: `Semantics` label "Round 1 of 10, Mild tier"

- [x] Task 8: Role Reveal Overlay component (AC: #2)
  - [x] 8.1 Create `rackup/lib/features/game/view/widgets/role_reveal_overlay.dart` — full-screen dark overlay
  - [x] 8.2 Content: microphone emoji "🎤" (48dp), "YOU'RE THE REFEREE NOW" (Oswald Bold 42dp, gold — use `RackUpColors.streakGold`), referee's display name in their identity color (use `PlayerIdentity.forSlot(slot).color` from `core/theme/player_identity.dart`), gold horizontal rule divider
  - [x] 8.3 Animation: fade-in entry (300ms), 2-second hold, fade-out exit (300ms). Respect `MediaQuery.disableAnimations`
  - [x] 8.4 Auto-dismisses after animation completes — no tap handler, no interaction required
  - [x] 8.5 Accessibility: `Semantics` label "You are the referee now" with `liveRegion: true`
  - [x] 8.6 Expose `onDismissed: VoidCallback` to notify parent when overlay completes

- [x] Task 9: Referee Command Center scaffold (AC: #2)
  - [x] 9.1 Create `rackup/lib/features/game/view/referee_screen.dart` — 4-region layout
  - [x] 9.2 Status Bar region (~60dp top): `ProgressTierBar` widget
  - [x] 9.3 Stage Area region (~40% upper-middle): current shooter's name displayed with `PlayerNameTag` Large variant (24dp shape, Oswald 42dp name). For Story 3.1: static display, no interaction yet
  - [x] 9.4 Action Zone region (~35% lower-middle): placeholder text "Waiting for turn..." — MADE/MISSED buttons are Story 3.2
  - [x] 9.5 Footer region (~80dp bottom): leaderboard peek placeholder — "Leaderboard" text. Full leaderboard peek is Story 3.4
  - [x] 9.6 Dark base canvas (use `RackUpColors.canvas`), no back navigation

- [x] Task 10: Player Screen scaffold (AC: #3)
  - [x] 10.1 Create `rackup/lib/features/game/view/player_screen.dart` — 4-region layout
  - [x] 10.2 Header region (~60dp top): `ProgressTierBar` widget
  - [x] 10.3 Leaderboard region (~50% upper): list all players with `PlayerNameTag` Standard variant, score "0" right-aligned. Self-row highlighted with blue tint. For Story 3.1: static display, animations are Story 3.4
  - [x] 10.4 Event Feed region (~25% middle): placeholder "Game started!" event. Full event feed is Story 3.7
  - [x] 10.5 My Status region (~15% bottom): own player name, score "0", no item (items are Epic 5). Placeholder text "No items"
  - [x] 10.6 Dark base canvas (use `RackUpColors.canvas`), no back navigation

- [x] Task 11: Game Page — orchestrate role reveal and screen routing (AC: #2, #3)
  - [x] 11.1 Create `rackup/lib/features/game/view/game_page.dart` — replaces the placeholder `_GamePlaceholder` in `app_router.dart`
  - [x] 11.2 `GameBloc` is provided by `_RoomShellState` (see Task 12) — access via `context.read<GameBloc>()`
  - [x] 11.3 On `GameActive` state received: determine if current device is the referee (compare `state.refereeDeviceIdHash` with `context.read<DeviceIdentityService>().getHashedDeviceId()`)
  - [x] 11.4 If referee: show `RoleRevealOverlay` → on dismiss → show `RefereeScreen`
  - [x] 11.5 If player: show `PlayerScreen` immediately (no overlay)
  - [x] 11.6 Wrap both screens in `RackUpGameTheme` providing current tier data
  - [x] 11.7 Disable system back navigation using `PopScope(canPop: false)`

- [x] Task 12: Router and shell route updates (AC: #4)
  - [x] 12.1 Update `app_router.dart`: replace `_GamePlaceholder` widget with `GamePage`
  - [x] 12.2 In `_RoomShellState`: add `GameBloc` to the `MultiBlocProvider` alongside existing `WebSocketCubit` and `RoomBloc`. Create `GameBloc` in `initState`/`didChangeDependencies`, dispose in `dispose()`. Follow the exact same lifecycle pattern as the existing blocs
  - [x] 12.3 In `_RoomShellState`: create `GameMessageListener` (from Task 5) in `didChangeDependencies` (after both `WebSocketCubit` and `GameBloc` exist), dispose in `dispose()`. This wires `game.*` messages to `GameBloc` automatically via stream subscription. Note: this differs from `LobbyMessageListener` which lives in `_LobbyPageState` — game messages must be at the shell level because `game.initialized` fires during the lobby→game navigation transition

- [x] Task 13: PlayerNameTag widget (reusable component) (AC: #2, #3)
  - [x] 13.1 Create `rackup/lib/core/widgets/player_name_tag.dart` — new widget that REUSES existing `PlayerIdentity` system from `core/theme/player_identity.dart`. Use `PlayerIdentity.forSlot(slot)` to get color and `PlayerShape` — DO NOT re-implement the 8 color+shape mapping
  - [x] 13.2 Variants via enum: `PlayerNameTagSize.compact` (12dp shape, 13dp name), `PlayerNameTagSize.standard` (16dp/16dp), `PlayerNameTagSize.large` (24dp shape, Oswald 42dp name)
  - [x] 13.3 States: Default, Highlighted (self — blue tint), Dimmed (disconnected — 40% opacity). Pass as parameters
  - [x] 13.4 Check if shape rendering widget already exists at `core/theme/widgets/` — if `PlayerShapeWidget` or similar exists, reuse it for rendering geometric shapes. If not, create `CustomPainter` for each shape (circle, square, triangle, diamond, star, hexagon, cross, pentagon)
  - [x] 13.5 Accessibility: `Semantics` label combining player name and identity description (e.g., "Danny, coral circle")

- [x] Task 14: Comprehensive tests (all AC)
  - [x] 14.1 Go test: game state initialization assigns referee correctly — non-host gets referee when 3+ players, host gets referee when only 2 players (2 tests)
  - [x] 14.2 Go test: turn order is sorted by slot number ascending (1 test)
  - [x] 14.3 Go test: `IsReferee()` returns true only for assigned referee (1 test)
  - [x] 14.4 Go test: referee action from non-referee returns `NOT_REFEREE` error (1 test)
  - [x] 14.5 Go test: `game.initialized` payload broadcast includes all expected fields (1 test)
  - [x] 14.6 Bloc test: `GameInitialized` event → emits `GameActive` with correct state (1 test)
  - [x] 14.7 Bloc test: `GameActive.tier` is `mild` for round 1 (1 test)
  - [x] 14.8 Widget test: `ProgressTierBar` renders tier badge, progress bar, round label (1 test)
  - [x] 14.9 Widget test: `RoleRevealOverlay` displays correct text and auto-dismisses after animation (1 test)
  - [x] 14.10 Widget test: `RefereeScreen` renders all 4 regions with correct content (1 test)
  - [x] 14.11 Widget test: `PlayerScreen` renders all 4 regions with correct content, self-row highlighted (1 test)
  - [x] 14.12 Widget test: `GamePage` shows overlay for referee, player screen for non-referee (2 tests)
  - [x] 14.13 Widget test: `PlayerNameTag` renders correct shape and color for each variant size (3 tests)
  - [x] 14.14 Widget test: `GamePage` disables back navigation (1 test)
  - [x] 14.15 Listener test: `gameInitialized` message dispatches `GameInitialized` event (1 test)

## Dev Notes

### Architecture Compliance

- **Server-authoritative**: Server assigns the referee, tracks authority via `GameState.RefereeDeviceIdHash`, and rejects referee actions from non-authoritative clients with `NOT_REFEREE` error. Client only renders based on server-provided state.
- **New blocs introduced**: `GameBloc` manages game session state. Architecture specifies 6 blocs + 1 cubit — this story creates `GameBloc`. `RefereeBloc`, `LeaderboardBloc`, `ItemBloc`, and `EventFeedCubit` are created in later stories as needed.
- **Protocol separation**: `GameInitializedPayload` in `core/protocol/`, `GamePlayer` domain model in `core/models/`. GameBloc states use domain models, never protocol types.
- **InheritedWidget for theme**: `RackUpGameTheme` ALREADY EXISTS at `core/theme/game_theme.dart` — it's an InheritedWidget (not a Bloc). Use `RackUpGameTheme.fromProgression(percentage:, animationsEnabled:)` static method to wrap game screens. DO NOT create a new theme widget.
- **Message routing**: `GameMessageListener` follows the same instance-based pattern as `LobbyMessageListener` — constructor takes `WebSocketCubit` and `GameBloc`, subscribes to `webSocketCubit.messages` stream, has `dispose()`. Created in `_RoomShellState` (NOT in `GamePage`) because `game.initialized` fires during the lobby→game route transition. Note: `LobbyMessageListener` lives in `_LobbyPageState` — `GameMessageListener` intentionally differs by being shell-level.

### Existing Code Awareness — DO NOT DUPLICATE

These already exist and must NOT be re-created:
- `RoomStarting` state in `room_state.dart` — emitted when `lobby.game_started` is received
- `GameStarted` event in `room_event.dart` — triggers `RoomStarting`
- Stub `/game` route in `app_router.dart` — replace `_GamePlaceholder`, don't add a new route
- `Player` model in `core/models/player.dart` — lobby-phase model with `displayName`, `deviceIdHash`, `slot`, `isHost`, `status`
- `PlayerStatus` enum — lobby-phase only (joining/writing/ready). Do NOT extend for game phase
- `Actions.gameTurnComplete` — already defined as `"game.turn_complete"` in `actions.dart`
- `RackUpColors` in design system — player identity colors and semantic colors already defined
- `DeviceIdentityService` — already exists, use `context.read<DeviceIdentityService>()` for hashed device ID
- `WebSocketCubit` — already exists, sends/receives messages over the WebSocket
- Shell route in `app_router.dart` — already hoists `WebSocketCubit` and `RoomBloc` across `/create`, `/join`, `/lobby`, `/game`
- `ClampedTextScaler.of(context, TextRole.body)` — existing accessibility text scaling helper
- `RackUpGameTheme` + `RackUpGameThemeData` + `EscalationTier` at `core/theme/game_theme.dart` — tier-aware visual configuration InheritedWidget. Static methods on `RackUpGameTheme`: `tierForProgression(double)`, `backgroundForTier(EscalationTier)`, `fromProgression({required double percentage, required bool animationsEnabled})`. Instance method: `of(context)` returns `RackUpGameThemeData`. DO NOT create a new game theme
- `PlayerIdentity` + `PlayerShape` at `core/theme/player_identity.dart` — full 8-slot identity system with `PlayerIdentity.forSlot(slot)` returning color and shape. DO NOT re-implement color+shape mapping
- `RackUpColors.canvas` (`0xFF0F0E1A`) — dark base canvas color constant
- `RackUpColors.streakGold` (`#FFD700`) — gold color constant for achievements/highlights
- `Room.roundCount` field in `room.go` — already set by `handleStartGame()`, pass `r.roundCount` to `NewGameState()`

### Game Start Flow — Two-Phase Broadcast

The game start flow involves TWO server broadcasts:
1. **`lobby.game_started`** (already implemented in Story 2.3) — simple notification with `roundCount`. Triggers `RoomStarting` state → navigation to `/game`.
2. **`game.initialized`** (NEW in this story) — comprehensive game init payload with referee assignment, turn order, player game state, and current shooter. Triggers `GameActive` state → role-based screen rendering.

The client navigates to `/game` on `lobby.game_started` (already working), then `GameBloc` receives `game.initialized` to populate the actual game UI. This two-phase approach avoids changing the existing lobby→game transition.

### Referee Assignment Logic

- First referee: assign the first non-host player in slot order. Rationale: the host is busy setting up; letting another player referee first is better UX (matches Lena's journey in the PRD where the host hands off referee duty).
- Exception: if only 2 players, host is the referee (no other option — the other player needs to shoot).
- Turn order: players sorted by ascending slot number. This gives a deterministic, consistent ordering.

### Implementation Patterns from Previous Stories

- **Bloc event naming**: Past tense for server events (`GameInitialized`), imperative for user actions.
- **Message routing**: Instance-based listener class — constructor takes `WebSocketCubit` + target Bloc, subscribes to `webSocketCubit.messages` stream via `.listen()`, stores `StreamSubscription`, has `dispose()` that cancels it. Handler switches on `message.action`, parses payload in try-catch, silently drops malformed payloads. See `LobbyMessageListener` at `core/websocket/lobby_message_listener.dart` for exact pattern.
- **Widget accessibility**: `Semantics(...)` on all interactive and informational elements. `ClampedTextScaler.of(context, TextRole.body)` for text. `MediaQuery.disableAnimations` before any animation.
- **Test factories**: Use `createTestRoomBloc()` from `test/helpers/factories.dart` (Dart). Use `testutil.NewTestRoom(code, hostHash)` from `internal/testutil/factories.go` (Go).
- **Bloc testing**: `blocTest<GameBloc, GameState>()` with `build`, `act`, `expect` from `bloc_test` + `mocktail`.
- **Widget immutability**: Domain models use `copyWith()` for state updates.

### Key Design Decisions

- **Separate game-phase player model**: `GamePlayer` is distinct from lobby `Player`. Game phase adds `score`, `streak`, `isReferee` and drops `status` (lobby-only). Protocol→model mapping handles the conversion.
- **GameBloc lives in game feature**: `lib/features/game/bloc/`. It does NOT live in lobby feature. The shell route must provide it so it's accessible from the game route.
- **Role Reveal is a one-time overlay**: Shown only at game start for the referee. After auto-dismiss, it never re-appears (unless referee rotates in Story 7.1). Implemented as an overlay state in `GamePage`, not a separate route.
- **No leaderboard animations yet**: Player Screen shows a static player list with scores. `LeaderboardBloc` and shuffle animations are Story 3.4. This story just renders the scaffold.
- **No MADE/MISSED buttons yet**: Referee Command Center Action Zone shows placeholder. Story 3.2 adds the actual buttons.
- **Dark base canvas**: `Scaffold(backgroundColor: RackUpColors.canvas)` — use the constant, not a hardcoded hex value. Tier-based background color changes are Story 3.5.

### Project Structure Notes

**New files:**
- `rackup-server/internal/game/game_state.go`
- `rackup-server/internal/game/game_state_test.go`
- `rackup/lib/core/models/game_player.dart`
- `rackup/lib/core/models/game_tier.dart`
- `rackup/lib/core/widgets/player_name_tag.dart`
- `rackup/lib/core/websocket/game_message_listener.dart`
- `rackup/lib/features/game/bloc/game_bloc.dart`
- `rackup/lib/features/game/bloc/game_event.dart`
- `rackup/lib/features/game/bloc/game_state.dart`
- `rackup/lib/features/game/view/game_page.dart`
- `rackup/lib/features/game/view/referee_screen.dart`
- `rackup/lib/features/game/view/player_screen.dart`
- `rackup/lib/features/game/view/widgets/progress_tier_bar.dart`
- `rackup/lib/features/game/view/widgets/role_reveal_overlay.dart`
- `rackup/test/features/game/bloc/game_bloc_test.dart`
- `rackup/test/features/game/view/game_page_test.dart`
- `rackup/test/features/game/view/referee_screen_test.dart`
- `rackup/test/features/game/view/player_screen_test.dart`
- `rackup/test/features/game/view/widgets/progress_tier_bar_test.dart`
- `rackup/test/features/game/view/widgets/role_reveal_overlay_test.dart`
- `rackup/test/core/widgets/player_name_tag_test.dart`

**Modified files:**
- `rackup/lib/core/protocol/actions.dart` — add `gameInitialized`, `refereeConfirmShot` placeholder
- `rackup/lib/core/protocol/messages.dart` — add `GameInitializedPayload`, `GamePlayerPayload`
- `rackup/lib/core/protocol/mapper.dart` — add `GamePlayerPayload` → `GamePlayer` mapping
- `rackup/lib/core/routing/app_router.dart` — replace `_GamePlaceholder` with `GamePage`, provide `GameBloc`
- `rackup-server/internal/protocol/actions.go` — add `ActionGameInitialized`, `ActionRefereeConfirmShot`
- `rackup-server/internal/protocol/messages.go` — add `GameInitializedPayload`, `GamePlayerPayload`
- `rackup-server/internal/room/room.go` — add `gameState` field, call `game.NewGameState()` on start, broadcast `game.initialized`

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.1]
- [Source: _bmad-output/planning-artifacts/architecture.md — Bloc Architecture (7 blocs), RackUpGameTheme InheritedWidget, Message Protocol Namespaces, Protocol vs Models separation]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Component #18 Role Reveal Overlay, Component #16 Progress/Tier Bar, Component #2 Player Name Tag, Referee Screen Regions, Player Screen Regions, Color System, Typography System]
- [Source: _bmad-output/planning-artifacts/prd.md — FR12-FR14, FR18-FR25, NFR3]
- [Source: _bmad-output/implementation-artifacts/2-3-game-configuration-and-start.md — Dev Notes, Game Start Flow, File List]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Fixed existing `TestStartGame_DoubleStart` test to drain `game.initialized` message (second broadcast added by this story)
- Fixed `TestStartGame_AllPunishmentsSubmitted`, `TestStartGame_TimeoutElapsed`, and `TestStartGame_BroadcastsToAll` tests to drain `game.initialized` broadcast
- Used `find.byWidgetPredicate` for Semantics assertions instead of `find.bySemanticsLabel` (not enabled in test environment)
- `NewGameState` takes `map[string]string` (deviceHash→displayName) instead of `map[string]*PlayerConn` for testability

### Completion Notes List

- **Task 1**: Protocol layer — added `gameInitialized`, `refereeConfirmShot` actions and `GameInitializedPayload`/`GamePlayerPayload` in both Dart and Go. SYNC WITH headers maintained.
- **Task 2**: Server game initialization — `GameState` struct with `NewGameState()` referee assignment logic (first non-host for 3+ players, host for 2 players), `IsReferee()` authority check, `game.*`/`referee.*` action routing with `NOT_REFEREE` rejection. Broadcast `game.initialized` after `lobby.game_started` in `handleStartGame()`.
- **Task 3**: Game domain models — `GamePlayer` domain model with `copyWith()`, `computeTier()` helper delegating to `RackUpGameTheme.tierForProgression()`, `mapToGamePlayer()` mapper.
- **Task 4**: `GameBloc` with sealed states (`GameInitial`/`GameActive`), `GameInitialized` event handler computing initial tier.
- **Task 5**: `GameMessageListener` at shell level — routes `game.initialized` to `GameBloc`, follows `LobbyMessageListener` pattern.
- **Task 6**: Verified `RackUpGameTheme` exists — used `fromProgression()` in `GamePage`.
- **Task 7**: `ProgressTierBar` — 60dp bar with tier badge, 4dp progress bar, round label. Semantics label included.
- **Task 8**: `RoleRevealOverlay` — full-screen overlay with fade-in/hold/fade-out sequence (2.6s total), respects `disableAnimations`, auto-dismisses via `onDismissed` callback.
- **Task 9**: `RefereeScreen` — 4-region layout (StatusBar/Stage/ActionZone/Footer) with `PlayerNameTag` large variant for current shooter.
- **Task 10**: `PlayerScreen` — 4-region layout (Header/Leaderboard/EventFeed/MyStatus) with self-row highlighting.
- **Task 11**: `GamePage` — routes to overlay→referee or player screen based on device identity, wraps in `RackUpGameTheme`, `PopScope(canPop: false)`.
- **Task 12**: Router updates — replaced `_GamePlaceholder` with `GamePage`, added `GameBloc` and `GameMessageListener` to `_RoomShellState`.
- **Task 13**: `PlayerNameTag` — 3 size variants (compact/standard/large), 3 states (normal/highlighted/dimmed), reuses `PlayerShapeWidget` and `PlayerIdentity`.
- **Task 14**: 17 Go tests (4 new game_state + 2 new room integration + 4 existing fixed), 13 Dart tests (2 bloc + 1 progress bar + 1 overlay + 1 referee screen + 1 player screen + 3 game page + 3 name tag + 1 listener). All 296 Dart tests pass, all Go tests pass.

### Change Log

- Story 3.1 implementation completed (Date: 2026-04-01)

### File List

**New files:**
- `rackup-server/internal/game/game_state.go`
- `rackup-server/internal/game/game_state_test.go`
- `rackup/lib/core/models/game_player.dart`
- `rackup/lib/core/models/game_tier.dart`
- `rackup/lib/core/widgets/player_name_tag.dart`
- `rackup/lib/core/websocket/game_message_listener.dart`
- `rackup/lib/features/game/bloc/game_bloc.dart`
- `rackup/lib/features/game/bloc/game_event.dart`
- `rackup/lib/features/game/bloc/game_state.dart`
- `rackup/lib/features/game/view/game_page.dart`
- `rackup/lib/features/game/view/referee_screen.dart`
- `rackup/lib/features/game/view/player_screen.dart`
- `rackup/lib/features/game/view/widgets/progress_tier_bar.dart`
- `rackup/lib/features/game/view/widgets/role_reveal_overlay.dart`
- `rackup/test/features/game/bloc/game_bloc_test.dart`
- `rackup/test/features/game/view/game_page_test.dart`
- `rackup/test/features/game/view/referee_screen_test.dart`
- `rackup/test/features/game/view/player_screen_test.dart`
- `rackup/test/features/game/view/widgets/progress_tier_bar_test.dart`
- `rackup/test/features/game/view/widgets/role_reveal_overlay_test.dart`
- `rackup/test/core/widgets/player_name_tag_test.dart`
- `rackup/test/core/websocket/game_message_listener_test.dart`

**Modified files:**
- `rackup/lib/core/protocol/actions.dart` — added `gameInitialized`, `refereeConfirmShot`
- `rackup/lib/core/protocol/messages.dart` — added `GameInitializedPayload`, `GamePlayerPayload`
- `rackup/lib/core/protocol/mapper.dart` — added `mapToGamePlayer()`
- `rackup/lib/core/routing/app_router.dart` — replaced `_GamePlaceholder` with `GamePage`, added `GameBloc` + `GameMessageListener` to shell
- `rackup-server/internal/protocol/actions.go` — added `ActionGameInitialized`, `ActionRefereeConfirmShot`
- `rackup-server/internal/protocol/messages.go` — added `GameInitializedPayload`, `GamePlayerPayload`
- `rackup-server/internal/room/room.go` — added `gameState` field, game init + broadcast in `handleStartGame()`, `handleGameAction()` for referee authority
- `rackup-server/internal/room/room_test.go` — added 2 new tests, fixed 4 existing tests to drain `game.initialized` broadcast
