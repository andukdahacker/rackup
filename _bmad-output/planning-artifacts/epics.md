---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-03-party-review, step-04-final-validation]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# RackUp - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for RackUp, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Host can create a new game room and receive a unique shareable join code
FR2: Players can join an existing room by entering the join code manually
FR3: Players can join an existing room via a deep link (rackup.app/join/CODE); if the app is not installed, the deep link redirects to the appropriate App Store for download, then opens directly into the room on launch
FR4: Players can enter a display name when joining a room (no account required)
FR5: Host can configure game length (number of rounds: 5, 10, or 15) before starting
FR6: Players can join a room mid-game and receive a catch-up starting score equal to the current lowest player's score plus a consolation item
FR7: Rooms support 2-8 concurrent players
FR8: All players must submit one custom punishment before the game starts; the host can start the game once all players have submitted or the configurable timeout has elapsed, whichever comes first
FR9: Host can start the game once all players have joined and the punishment submission phase is complete (all submitted or timeout elapsed)
FR10: All players can view a pre-game lobby showing connected players, each player's punishment submission status, and a waiting indicator until the host starts the game
FR11: The system terminates a room when the game ends; post-game report card data remains accessible to all players until they leave the results screen; room state is archived for analytics after all players exit
FR12: The system manages turn order across all players in the room
FR13: The referee can confirm each shot result as "made" or "missed"
FR14: The referee can undo a shot result within 5 seconds of confirmation
FR15: The system triggers the appropriate consequence chain based on shot result (made: points + streak; missed: streak reset + item drop chance + punishment)
FR16: The system activates triple-point scoring for the final 3 rounds and notifies all players
FR17: The system ends the game after the configured number of rounds and transitions to the post-game ceremony
FR18: The system assigns a referee role to one player at the start of the game
FR19: The referee receives a dedicated command center screen showing current shooter, mission delivery, shot confirmation, and consequence announcements
FR20: The referee can deliver secret missions to the current shooter (whisper prompt with confirmation)
FR21: The referee can announce punishments, item drops, and streak milestones from their screen
FR22: The system prompts referee rotation after each full round through all players
FR23: The current referee can hand off the role to the next player in rotation
FR24: The system skips the next referee in rotation if they are also the current shooter
FR25: The system detects when the referee disconnects and prompts the next player to take over
FR26: The system awards base points (+3) for each made shot
FR27: The system tracks consecutive made shots (streaks) per player and awards escalating streak bonuses (+1 for 2, +2 for 3, +3 for 4+)
FR28: The system resets a player's streak to zero on a miss
FR29: The system displays streak status indicators to all players (warming up, ON FIRE, UNSTOPPABLE)
FR30: The system awards mission bonus points when a shooter completes their assigned secret mission
FR31: The system triples all point values during the final 3 rounds
FR32: The system awards an item to a player on a missed shot with a default probability of 50%
FR33: The system applies rubber banding — last place draws from the full item deck; first place is excluded from Blue Shell draws
FR34: Each player can hold one item at a time (use-it-or-lose-it — current item is replaced if a new one is received)
FR35: Players can deploy their held item at any point during active gameplay, targeting another player when applicable (anytime deployment)
FR36a: Blue Shell — target first place player; they lose 3 points and must shoot off-handed next turn
FR36b: Shield — block the next punishment or item used against you
FR36c: Score Steal — take 5 points from a targeted player
FR36d: Streak Breaker — reset a targeted player's streak to zero
FR36e: Double Up — next made shot is worth double points
FR36f: Trap Card — the next player to miss receives your punishment instead
FR36g: Reverse — swap your score with a targeted player
FR36h: Immunity — skip your next punishment
FR36i: Mulligan — redo your last shot (group votes to allow via in-app poll)
FR36j: Wildcard — player enters a custom rule that the system displays to all players for 3 turns
FR37: The system randomly assigns a secret mission to the current shooter with a default probability of 33% per turn
FR38: Only the shooter and the referee can see the assigned mission
FR39: The system validates mission completion based on the referee's confirmation
FR40: The system supports the full 15-mission deck with varying difficulty and bonus point values (+2 to +8)
FR41: The system draws a punishment from the appropriate tier when a player misses a shot
FR42: The system escalates punishment tiers based on game progression percentage (first 30% mild, 30-70% medium, final 30% spicy)
FR43: Custom punishments submitted by players are shuffled into all tiers throughout the game
FR44: The referee screen displays the drawn punishment with its tier tag for announcement
FR45: All players can view the current leaderboard showing player names, scores, and rankings
FR46: The leaderboard displays position-shuffle animations when rankings change after a shot
FR47: The system displays streak fire indicators next to players on active streaks
FR48: The system plays sound effects on key events (Blue Shell impact, leaderboard shuffle, punishment reveal, streak fire, podium fanfare)
FR49: The system keeps the device screen awake during an active game session
FR50: The system generates a post-game report card displaying awards: MVP (highest score), Sharpshooter (best accuracy), Punching Bag (most punishments), Participant Trophy (lowest score), Hot Hand (longest streak), Mission Master (most missions completed)
FR51: The referee controls the post-game podium ceremony with sequential dramatic reveal (3rd → 2nd → 1st place)
FR52: Players can generate a styled shareable image of the report card in 9:16 (Instagram Stories) and 1:1 (general sharing) formats
FR53: Players can share the report card image via the device's native share sheet
FR54: The system displays "RECORD THIS" prompts on all players' screens when shareable moments occur (spicy punishments, Blue Shell deployments, streak breaks)
FR55: The report card includes Best Moments timestamps ("Blue Shell at 9:47 PM") so players can find their own recordings
FR56: The system presents a post-game micro-feedback prompt asking each player to rate the referee experience (thumbs up / thumbs down) for Referee Satisfaction measurement
FR57: The system detects when a player disconnects and displays a visual indicator on other players' screens
FR58: The system automatically skips disconnected players' turns and continues the game
FR59: The system preserves a disconnected player's score, items, and stats server-side
FR60: The system silently reconnects a returning player and syncs their state within 60 seconds of disconnection
FR61: The system notifies a reconnected player of any missed turns
FR62: The system generates a persistent device identifier for anonymous player tracking
FR63: The system tracks game completion events (started, finished, abandoned)
FR64: The system tracks share button taps on post-game report cards
FR65: The system fingerprints group identity by matching player composition across sessions (for 7-Day Group Return measurement)
FR66: The system tracks item deployment events (which items are used, how often)
FR67: The system tracks sequential room creation by the same host within a single session to measure Second Game Rate
FR68: The system tracks referee satisfaction feedback (thumbs up/down) from post-game micro-surveys
FR69: The host can initiate a "Play Again" flow after the game ends; the system creates a new room, automatically migrates all connected players (preserving display names and device ID associations), issues new JWTs, reuses existing WebSocket connections, and transitions all players to a new lobby with zero friction

### NonFunctional Requirements

NFR1: Room creation completes and returns a join code within 2 seconds of the host tapping "Create Room"
NFR2: Player join (code entry to visible in lobby) completes within 3 seconds
NFR3: Shot result confirmation (referee tap to leaderboard update on all devices) propagates within 2 seconds
NFR4: Leaderboard position-shuffle animations render at 60fps on mid-range devices (Samsung A-series, Xiaomi Redmi)
NFR5: Post-game report card and share image generate within 3 seconds of game end
NFR6: Sound effects trigger within 200ms of their associated event (perceptible delay kills the party atmosphere)
NFR7: App cold start to home screen loads within 3 seconds
NFR8: Deep link open (app already installed) to room lobby loads within 4 seconds
NFR9: All client-server communication encrypted via TLS 1.2+
NFR10: Device identifiers are hashed before storage — raw device IDs never stored on the server
NFR11: Player display names are not linked to real identities — no email, phone, or social login data collected in MVP
NFR12: Game session data (scores, items, punishments) retained for analytics for 90 days, then anonymized or purged
NFR13: Custom punishment text is visible only to players within the same room — never exposed to other rooms or public APIs
NFR14: Privacy policy published and accessible within the app before store submission
NFR15: GDPR: users can request deletion of their device identifier and associated analytics data. CCPA: same, with opt-out of data sale (though no data is sold)
NFR16: The system supports at least 100 concurrent active rooms without performance degradation (MVP launch target)
NFR17: The system scales to 1,000+ concurrent rooms without architecture changes (growth target — managed service selection should accommodate this)
NFR18: Room code generation remains collision-free up to 10,000 active rooms per day (4-character alphanumeric = 1.6M combinations)
NFR19: Analytics event ingestion handles burst writes (all players in a room generating events simultaneously at game end) without data loss
NFR20: Game state is persisted to a managed cloud service with provider-guaranteed uptime SLA (e.g., Firebase 99.95%, Supabase 99.9%) — not stored solely in application memory or on a single self-managed server
NFR21: The app recovers gracefully from backgrounding (user switches to camera app to record a moment, then returns) without losing game state or room connection
NFR22: Crash-free session rate >99% across both iOS and Android
NFR23: Failed room creation or join attempts display clear, actionable error messages (not generic errors)
NFR24: The system degrades gracefully under load — if capacity is exceeded, new room creation is rejected with a clear message rather than degrading active games
NFR25: A full game session (60 minutes) should consume no more than 15% battery on a typical modern smartphone — no unnecessary background processing, efficient WebSocket keep-alive intervals, no continuous polling

### Additional Requirements

- **Starter Template (Epic 1 Story 1):** Flutter client via Very Good CLI (`very_good create flutter_app`); Go backend with `nhooyr.io/websocket` initialized via `go mod init github.com/ducdo/rackup-server`
- **Deployment Platform:** Railway (single instance for MVP, 100 concurrent rooms target)
- **Database:** PostgreSQL on Railway with `pgx` driver
- **Database Migrations:** `golang-migrate` with SQL migration files (001: sessions, 002: session_players, 003: session_events, 004: group_sessions view)
- **Health Check Endpoint:** `/health` returning room count, active connections, uptime
- **Sentry Integration:** Flutter SDK (client) + Go SDK (server), single dashboard, >99% crash-free target
- **Deep Linking:** `rackup.app/join/CODE` via `go_router`
- **Share Integration:** Flutter `share_plus` package for native OS share sheet
- **Real-Time Communication:** `nhooyr.io/websocket` (server) ↔ `web_socket_channel` (client), JSON envelope protocol
- **Message Protocol:** Namespaced JSON envelope `{namespace}.{verb_noun}`, namespaces: lobby, game, referee, item, postgame, system, error
- **JWT Authentication:** HS256 with claims (roomCode, deviceIdHash, displayName, exp), short-lived tokens on room create/join
- **Device ID Management:** UUID v4 client-side, SHA-256 hashed server-side before storage
- **HTTP Endpoints:** POST /rooms → {roomCode, jwt}, POST /rooms/:code/join → {jwt}, GET /health
- **Room Codes:** 4-character alpha only (A-Z), ephemeral, released when room ends
- **Consequence Chain Pipeline:** Atomic `game.turn_complete` message with ALL consequences, deterministic execution order, within 2-second sync window across 8 devices
- **Reconnection Protocol:** 60-second hold, connection swap via JWT + device ID, exponential backoff (1s → 2s → 4s → 8s → 16s max)
- **Referee Authority Transfer:** Server tracks authoritative client, rejects non-authoritative actions, automatic failover on disconnect
- **Anytime Item Deployment:** Players deploy items at ANY point during active gameplay, optimistic-then-confirm with ~500ms animation masking, queue behind active cascades
- **Play Again Flow:** Host initiates, server creates new room + migrates players, preserves display names, issues new JWTs, reuses WebSocket connections
- **State Management:** Server-authoritative, game state in-memory (room goroutine), no persistent room state between sessions
- **Bloc Pattern (Flutter):** 7 Blocs (WebSocketCubit, RoomBloc, GameBloc, RefereeBloc, LeaderboardBloc, ItemBloc, EventFeedCubit), sealed classes for typed states
- **Audio System:** Centralized AudioListener BlocListener, 5 MVP sound effects, preload and respect silent mode
- **Theme Escalation:** RackUpGameTheme via InheritedWidget, takes game progression percentage
- **Share Image Generation:** RepaintBoundary + toImage() for PNG capture, 9:16 and 1:1 formats
- **Logging:** Go `slog` structured JSON, log levels (Debug/Info/Warn/Error), Railway log drain
- **CI/CD:** GitHub Actions for tests + lint on PR, Railway auto-deploys from main
- **Data Flow:** Game state in-memory during play → buffered Go channel → async drain to PostgreSQL on game end
- **No Hot-Path DB Access:** PostgreSQL is cold path only — never during active gameplay
- **Data Retention:** 90-day retention window (GDPR/CCPA compliance)
- **Graceful Shutdown:** Implemented in Go server for clean connection closure
- **App Size Constraint:** <50MB for cellular download at bars
- **Configuration Abstraction:** All environment-specific values via AppConfig abstract class
- **Naming Conventions:** snake_case DB, PascalCase/camelCase Go/Dart, camelCase JSON wire, UTC timestamps ISO 8601

### UX Design Requirements

UX-DR1: Implement custom design system with fixed deep dark base canvas (#0F0E1A) with purple undertone as Scaffold background across all screens. No light mode.
UX-DR2: Create 4-tier discrete color escalation palette tied to game progression: Lobby (#1A1832 deep indigo), Mild 0-30% (#0D2B3E cool teal-blue), Medium 30-70% (#3D2008 warm amber-brown), Spicy+Triple 70-100% (#3D0A0A hot deep red with #FFD700 gold accents). 500ms animated crossfade transitions.
UX-DR3: Define semantic color tokens: Green (#22C55E) Made/Success, Red (#EF4444) Missed/Danger, Gold (#FFD700) Achievements, Electric Blue (#3B82F6) Items/Power, Purple (#A855F7) Missions/Secret, Off-White (#F0EDF6) primary text, Muted Lavender (#8B85A1) secondary text.
UX-DR4: Establish 8-slot player identity system with redundant color+shape encoding for colorblind accessibility: Coral Circle, Cyan Square, Amber Triangle, Violet Diamond, Lime Star, Sky Hexagon, Rose Cross, Mint Pentagon. Verify through colorblind simulator.
UX-DR5: Implement typography using Google Fonts: Oswald (500/600/700) for display/headlines, Barlow Condensed (700) for referee script/punishment text, Barlow (400/500/600) for UI/body.
UX-DR6: Define type scale with 8 tokens: display-xl (64dp), display-lg (48dp), display-md (36dp), display-sm (32dp), heading (24dp), body-lg (20dp), body (16dp), caption (14dp).
UX-DR7: Create base spacing system using 8dp units: space-xs (4dp), space-sm (8dp), space-md (16dp), space-lg (24dp), space-xl (32dp), space-xxl (48dp).
UX-DR8: Minimum tap target 56x56dp for all interactive elements. Primary action buttons minimum 64dp height, full-width. Undo button 48x48dp (deliberately smaller).
UX-DR9: Big Binary Buttons (MADE/MISSED): two side-by-side full-width, Oswald Bold 28dp uppercase, minimum 100dp height, breathing pulse default state, scale 97% on press.
UX-DR10: Player Name Tag component with 3 size variants (compact/standard/large), color-filled geometric shape + Oswald SemiBold name. States: Default, Highlighted, Dimmed (disconnected), Targeted.
UX-DR11: Item Card component: dark card with electric blue 2dp border, 36dp item icon, Oswald SemiBold 14dp name, "TAP TO DEPLOY" text. States: Default, Pressable, Deploying, Empty.
UX-DR12: Streak Fire Indicator: 4 visual states — Hidden (0-1), Warming Up (2: single flame amber), ON FIRE (3: double flame gold glow), UNSTOPPABLE (4+: triple flame pulsing gold).
UX-DR13: Punishment Tier Tag: color-coded badges with text — MILD (neutral), MEDIUM (amber), SPICY (red), CUSTOM (purple). Never color alone.
UX-DR14: "RECORD THIS" Alert: camera emoji (80dp pulsing), "RECORD THIS" (Oswald Bold 36dp red), tier badge. Fires 3-5s before reveals. Storm pause effect. Auto-dismisses.
UX-DR15: Report card templates: 9:16 (Instagram Stories) and 1:1 (general sharing). RackUp branding, podium, awards, diagonal slash motif, no particles. RepaintBoundary capture.
UX-DR16: Lobby Player Row: color+shape tag, Oswald SemiBold name, optional HOST badge, status indicator. States: Joining (slide-in), Writing (amber), Ready (green checkmark).
UX-DR17: Punishment Input: text field (Barlow 14dp), rotating placeholder examples, "Random" button (purple). States: Empty, Focused, Filled, Submitted.
UX-DR18: Slide-to-Start: rounded track (52dp), circular thumb (44dp green gradient), "SLIDE TO START GAME" text. 70% threshold triggers. Accessibility fallback: 3-second long-press.
UX-DR19: Mission Delivery Card: purple accent, "SECRET MISSION" header, mission text, "Whisper this to [Player]" instruction, "Mission Delivered" button. The Reveal animation.
UX-DR20: Event Feed Item: compact row with 3dp colored left border (blue/red/gold/purple/green), event text (Barlow 13dp). Max 4 visible, 2-second minimum hold.
UX-DR21: Targeting Row: full-width tappable, rank + player tag + name + score. Blue Shell shows gold border + crosshair on 1st. One-tap deploy, no confirmation. 56dp+ height.
UX-DR22: Podium Reveal: full-screen, position number (Oswald Bold 64dp/48dp), player name/tag, score, background glow. States: Hidden, Revealing (1-2s), Revealed (1st with Eruption + fanfare). Referee taps sequentially.
UX-DR23: Progress/Tier Bar (~60dp fixed): tier tag (left), progress fill (4dp, tier-colored), round label "R5/10" (right). Tier states: Mild (teal), Medium (amber), Spicy (red), Triple (red pulsing gold "3X").
UX-DR24: Undo Button (48x48dp): circular icon + "Undo" text, shrinking ring countdown (5s). States: Visible (countdown), Tapped (reverts), Expired (fades, locks).
UX-DR25: Role Reveal Overlay: full-screen dark, microphone emoji (48dp), "YOU'RE THE REFEREE NOW" (Oswald Bold 42dp gold), new referee name, gold rule. 2-second hold, auto-dismiss.
UX-DR26: 3 core motion patterns: (1) The Reveal — anticipation + fast payoff, (2) The Shuffle — cascading staggered motion, (3) The Eruption — explosive outward burst.
UX-DR27: Ambient particle system with 4 discrete presets: Lobby (0), Mild (10 slow motes), Medium (25 warm embers), Spicy (50 glowing embers/sparks). 50-particle hard cap. Render only during active turns.
UX-DR28: Glow effects as escalation: radial glow behind leader, pulsing glow on punishment reveal, breathing glow on podium 1st, button pulse during shot phase, item card glow. Pre-rendered gradients for performance.
UX-DR29: Typography effects on peak moments: "UNSTOPPABLE" gold shimmer, "TRIPLE POINTS" pulsing, "BLUE SHELL" electric blue energy, player name glow highlights.
UX-DR30: Visual escalation principle: Lobby 0%, Mild 20%, Medium 50%, Spicy 100% visual intensity budget.
UX-DR31: "RECORD THIS" storm pause: particles freeze+dim, screen-edge red pulse, silence, then Eruption at full intensity, storm erupts back.
UX-DR32: Referee Screen 4-region layout: Status Bar (~60dp), Stage Area (~40%), Action Zone (~35%), Footer (~80dp). No scrolling.
UX-DR33: Player Screen 4-region layout: Header (~60dp), Leaderboard (~50%), Event Feed (~25%), My Status (~15%). No scrolling during gameplay.
UX-DR34: Portrait-locked, single-column, bottom-weighted interaction: primary actions in lower 40%, info in upper 60%. Edge-to-edge buttons with 32dp margin. No scroll during core loops.
UX-DR35: Responsive text scaling with clamped limits: body (14-20dp max 2.0x), display (32-64dp max 1.2x), referee punishment (20dp max 1.3x), button labels (28dp no scaling). Custom TextScaler utility.
UX-DR36: Reduced motion support (MediaQuery.disableAnimations): disable particles, snap leaderboard, skip animations to final state, instant tier color swap. Maintain game logic/sound/text/layouts/share.
UX-DR37: Screen reader support: full accessibility for navigable screens (Home, Join, Report Card), best-effort for game screens. All buttons labeled with purpose+context.
UX-DR38: Semantic accessibility labels on all interactive elements with purpose + context descriptions.
UX-DR39: Narrator Mode (Phase 2): text-to-speech for referee announcements, optional toggle, off by default.
UX-DR40: 2-tier action button hierarchy: Tier 1 primary (full-width/50-50, 64-100dp, bold gradient, Oswald Bold 28dp+), Tier 2 secondary (medium width, 44-52dp, accent fill, Oswald SemiBold 16dp).
UX-DR41: Tier 3 tertiary actions: compact 36-48dp, outline/ghost styling, Barlow 12-14dp. Never two Tier 1 competing.
UX-DR42: Feedback patterns for noisy bar: Success (green flash + Reveal + chime), Impact (Eruption + bold announcement), Fizzle (optimistic start + fizzle if rejected), System (subtle toast), Error (red inline, no sound, actionable).
UX-DR43: Never block gameplay with feedback. No modal dialogs, no OK buttons, all feedback ambient.
UX-DR44: 3 state transition patterns: Full-screen (Reveal/Eruption, 2s hold, auto-dismiss, max 1-2 per game), Zone (AnimatedSwitcher, only affected zone), Overlay (slide up, tap-outside dismiss, cancel path).
UX-DR45: Consistency: same transition type = same animation. Never interrupt input. Simultaneous transitions sequenced not stacked.
UX-DR46: Tier color transition: 500ms crossfade via AnimatedContainer on scaffold background only.
UX-DR47: Connection loading: full-screen spinner only during room join (10s timeout), in-game optimistic local updates + server confirm, item deployment server-confirmed with animation masking.
UX-DR48: Player disconnection UX: tag dims 40% + "reconnecting..." subtext, auto-skip turns, silent reconnect + toast, 60s timeout.
UX-DR49: Referee disconnection: immediate handoff prompt, one tap accept, Role Reveal plays, original returns as regular player on reconnect.
UX-DR50: Full connection loss: server preserves 5 min, pulsing "Reconnecting..." indicator, silent sync on reconnect, expiry message if >5 min.
UX-DR51: Error recovery: 5-second undo for shot errors, inline error for wrong room code, retry button for room creation failure, silent retries for mid-game errors.
UX-DR52: Social error handling: "Delivered" button always exits, "THE POOL GODS HAVE SPOKEN" depersonalizes punishment source.
UX-DR53: "Play Again" auto-migration: host taps → new room → all players auto-join → zero friction. Drives Second Game Rate >50%.
UX-DR54: Error tone: muted, low-key, informational. Drama reserved for game events only.
UX-DR55: Screen size adaptation for 375-430dp width, portrait-locked: Status Bar 52dp fixed, Stage/Leaderboard ~40-50% flex, Action Zone ~35% flex (100dp min MADE/MISSED), Footer 80dp fixed.
UX-DR56: Small screens (375dp): event feed max 3, targeting rows 52dp if 6+ players, punishment text 20→18dp, 8 leaderboard entries ~48dp each.
UX-DR57: Large screens (430dp+): extra padding/breathing room only.
UX-DR58: Notch/safe area via Flutter SafeArea wrapper. Status/Tier Bar below safe area insets.
UX-DR59: WCAG AA contrast minimum (4.5:1) for all text. Primary text (#F0EDF6 on #0F0E1A) achieves 14.8:1 AAA.
UX-DR60: Color accessibility: run 8 player identity colors through colorblind simulator. Coral/Rose may merge for protanopic users. Shape pairing provides redundant channel.
UX-DR61: No information conveyed by color alone: all color-coded elements have text or shape reinforcement.
UX-DR62: Minimum text size 14dp throughout entire app.
UX-DR63: Motor accessibility: no precision gestures (no swipes, pinches, long-press-drag). All single taps on large targets.
UX-DR64: Cognitive accessibility: one purpose per screen, progressive disclosure, consistent component patterns, no time pressure on referee input.
UX-DR65: Audio accessibility: sound effects supplementary only, visual feedback accompanies every sound, respect silent/vibrate mode, effects <2 seconds.
UX-DR66: Deep link deferred routing: App Store redirect preserves room code through install, post-install opens directly to lobby. "Share Invite" primary, room code secondary.
UX-DR67: Linear game flow with no back navigation during game. Forward-only: lobby → punishment → rounds → ceremony → report card.
UX-DR68: State-based screen transformation: phone changes based on role (player/referee) and game state. No tabs, no menus.
UX-DR69: Binary input with cascading consequences: MADE/MISSED single tap triggers full chain.
UX-DR70: Item targeting with social awareness: targeting animation shows who you're targeting, builds anticipation.
UX-DR71: Single-item slot inventory, use-it-or-lose-it. No inventory screens, no crafting, no menus.
UX-DR72: Leaderboard as entertainment: animated shuffles with sound, position changes become moments.
UX-DR73: Streak visualization escalation: warming up → ON FIRE → UNSTOPPABLE (2/3/4+ streaks).
UX-DR74: Share-optimized output: report card looks native to Instagram Stories, not like a screenshot. 2-second attention window.
UX-DR75: Highlight reel as viral engine: auto-compiled Best Moments timestamps (Phase 1.5+).
UX-DR76: 5-second undo window for shot confirmation with visual countdown ring.
UX-DR77: App home screen: "Turn pool night into chaos" headline, "Create Room" + "Join Room" buttons, subtext. No nav, no settings.
UX-DR78: Host lobby: room code (Oswald 36dp gold), "Share Invite Link" button, player list with stagger animations, punishment input + Random, round selector (5/10/15, default 10), slide-to-start at bottom.
UX-DR79: Join screen: 4-char code input (auto-uppercase, auto-advance), display name input, green "Join" button. Deep link skips this.
UX-DR80: Consequence cascade with dynamic timing: routine make <1s, streak milestone ~2s, mild punishment ~2s, item+medium ~4s, item+spicy ~5-8s, RECORD THIS ~8-12s.
UX-DR81: Cascade timing significance-scaled: routine fast, big moments get full theatrical treatment.
UX-DR82: Server state push + client-side local animation. Multiple phones firing within ~500ms creates communal moment.
UX-DR83: Rotation order management: system handles turn advancement, item drops, punishment tiers, streaks, leaderboard, disconnections, triple-points.
UX-DR84: Game telemetry: group identity fingerprinting (no PII), Best Moments timestamp recording.
UX-DR85: Cascade action zone using AnimatedSwitcher: consequences slide up from behind buttons.
UX-DR86: Player visibility: every player must have at least one positive attention moment per game.
UX-DR87: Punishment reveal as depersonalized theater: "THE POOL GODS HAVE SPOKEN" framing.
UX-DR88: Item drop emotional framing: empowering, not consolation.
UX-DR89: Escalation through copy and color: referee text 3 tiers (mild/medium/spicy), background color temperature shift.
UX-DR90: No-confirmation design on impulsive actions. Confirmation only on Start Game (slide-to-start).
UX-DR91: Performance guardrails: 50 particle max, 4 presets, glow via pre-rendered gradients, globally disable-able, <15% battery/60min.
UX-DR92: Walking skeleton stage priorities: Stage 1-2 (no particles/glow, solid colors), Stage 3 (glow first), Stage 4-5 (particles if needed, typography shimmer, performance tuning).
UX-DR93: Brand identity via diagonal slash motif: dividing element on report card, background pattern on share images, subtle accent throughout app.
UX-DR94: Report card as ownership signal: Spotify Wrapped format, every share is mini-billboard.
UX-DR95: Room creation as critical moment: >99% success, <3s join latency.
UX-DR96: Mission delivery with referee whisper: 33% trigger, "Whisper this to [Player]", "Mission Delivered" button gates mission activation.
UX-DR97: Blue Shell targeting as social predator moment: targeting animation builds face-to-face anticipation.
UX-DR98: Item drop probability rubber-banding: 50% base on miss, last place full deck, framed as gift.
UX-DR99: Punishment delivery as referee performance: teleprompter text, verbal announcement precedes digital display.
UX-DR100: Game state escalation: mild 0-30%, medium 30-70%, spicy+triple 70-100%, each tier shifts color/particles/language intensity.

### Known Discrepancies

**FR35 (Item Deployment Timing):** Previously the PRD stated "on their turn" while Architecture and UX specified anytime deployment. **Resolved:** PRD FR35 has been updated to "at any point during active gameplay" — all documents are now in sync.

### FR Coverage Map

FR1: Epic 1 - Host creates room with join code
FR2: Epic 1 - Players join via code entry
FR3: Epic 1 - Players join via deep link
FR4: Epic 1 - Display name entry (no account)
FR5: Epic 2 - Host configures round count
FR6: Epic 9 - Mid-game join with catch-up scoring
FR7: Epic 1 - Room supports 2-8 players
FR8: Epic 2 - Custom punishment submission before game
FR9: Epic 2 - Host starts game after submissions
FR10: Epic 2 - Pre-game lobby view
FR11: Epic 8 - Room termination and data archival
FR12: Epic 3 - Turn order management
FR13: Epic 3 - Referee confirms shot (made/missed)
FR14: Epic 3 - Referee undo within 5 seconds
FR15: Epic 3 - Consequence chain on shot result
FR16: Epic 3 - Triple-point activation final 3 rounds
FR17: Epic 3 - Game ends after configured rounds
FR18: Epic 3 - Referee role assignment at game start
FR19: Epic 3 - Referee command center screen
FR20: Epic 6 - Referee delivers secret missions
FR21: Epic 4 - Referee announces punishments
FR22: Epic 7 - Referee rotation prompt after each round
FR23: Epic 7 - Referee handoff to next player
FR24: Epic 7 - Skip referee if also current shooter
FR25: Epic 7 - Referee disconnect failover
FR26: Epic 3 - Base points (+3) for made shot
FR27: Epic 3 - Streak tracking with escalating bonuses
FR28: Epic 3 - Streak reset on miss
FR29: Epic 3 - Streak status indicators (warming up, ON FIRE, UNSTOPPABLE)
FR30: Epic 6 - Mission bonus points
FR31: Epic 3 - Triple all point values final 3 rounds
FR32: Epic 5 - Item drop on miss (50% probability)
FR33: Epic 5 - Rubber banding for item draws
FR34: Epic 5 - One item slot (use-it-or-lose-it)
FR35: Epic 5 - Deploy item on turn, targeting applicable
FR36a: Epic 5 - Blue Shell item
FR36b: Epic 5 - Shield item
FR36c: Epic 5 - Score Steal item
FR36d: Epic 5 - Streak Breaker item
FR36e: Epic 5 - Double Up item
FR36f: Epic 5 - Trap Card item
FR36g: Epic 5 - Reverse item
FR36h: Epic 5 - Immunity item
FR36i: Epic 5 - Mulligan item
FR36j: Epic 5 - Wildcard item
FR37: Epic 6 - Random secret mission assignment (33%)
FR38: Epic 6 - Mission visible to shooter + referee only
FR39: Epic 6 - Mission completion validation by referee
FR40: Epic 6 - Full 15-mission deck
FR41: Epic 4 - Punishment draw on miss
FR42: Epic 4 - Punishment tier escalation by game progress
FR43: Epic 4 - Custom punishments shuffled into tiers
FR44: Epic 4 - Referee screen displays punishment with tier tag
FR45: Epic 3 - Live leaderboard (names, scores, rankings)
FR46: Epic 3 - Leaderboard position-shuffle animations
FR47: Epic 3 - Streak fire indicators on leaderboard
FR48: Epic 3 - Sound effects on key events
FR49: Epic 3 - Screen awake during active game
FR50: Epic 8 - Post-game report card with awards
FR51: Epic 8 - Podium ceremony (3rd → 2nd → 1st reveal)
FR52: Epic 8 - Shareable report card images (9:16 and 1:1)
FR53: Epic 8 - Native share sheet integration
FR54: Epic 3 - "RECORD THIS" prompts on shareable moments (moved from Epic 8 — fires during active gameplay)
FR55: Epic 8 - Best Moments timestamps on report card
FR56: Epic 8 - Post-game referee satisfaction micro-feedback
FR57: Epic 9 - Disconnect visual indicator
FR58: Epic 9 - Auto-skip disconnected players
FR59: Epic 9 - Preserve disconnected player state
FR60: Epic 9 - Silent reconnection within 60 seconds
FR61: Epic 9 - Notify reconnected player of missed turns
FR62: Epic 1 - Persistent device identifier generation
FR63: Epic 10 - Track game completion events
FR64: Epic 10 - Track share button taps
FR65: Epic 10 - Group identity fingerprinting
FR66: Epic 10 - Track item deployment events
FR67: Epic 10 - Track sequential room creation (second game rate)
FR68: Epic 10 - Track referee satisfaction feedback
FR69: Epic 8 - Play Again flow (host initiates, auto-migrate players)

## Epic List

### Epic 1: Room Creation & Joining
Users can create a game room, share a join code or deep link, and friends can join with a display name. The foundation for gathering friends around a pool table. Includes design system, accessibility audit.
**FRs covered:** FR1, FR2, FR3, FR4, FR7, FR62

### Epic 2: Pre-Game Lobby & Punishment Submission
Players see who's joined, submit custom punishments, host configures round count, and starts the game with a deliberate slide-to-start.
**FRs covered:** FR5, FR8, FR9, FR10

### Epic 3: Core Gameplay & Referee
A referee is assigned, confirms shots turn-by-turn, the system awards points and tracks streaks, and all players watch the live leaderboard with animated shuffles and sound effects. Includes "RECORD THIS" moments and consequence chain with extension points.
**FRs covered:** FR12, FR13, FR14, FR15, FR16, FR17, FR18, FR19, FR26, FR27, FR28, FR29, FR31, FR45, FR46, FR47, FR48, FR49, FR54

### Epic 4: Punishment System
Missed shots trigger punishments from escalating tiers (mild → medium → spicy), with custom player-submitted punishments shuffled in. The referee announces from their screen.
**FRs covered:** FR21, FR41, FR42, FR43, FR44

### Epic 5: Items & Power-Ups
Players receive items on misses with rubber banding, hold one at a time, and deploy them targeting other players. Full 10-item deck with strategic effects.
**FRs covered:** FR32, FR33, FR34, FR35, FR36a-j

### Epic 6: Secret Missions
The referee delivers hidden objectives to shooters via whisper prompts, with bonus points for completion. Full 15-mission deck with varying difficulty.
**FRs covered:** FR20, FR30, FR37, FR38, FR39, FR40

### Epic 7: Referee Rotation & Resilience
Referee role rotates after each round with smooth handoff mechanics, shooter-skip logic, and automatic failover when the referee disconnects.
**FRs covered:** FR22, FR23, FR24, FR25

### Epic 8: Post-Game Ceremony & Sharing
Dramatic podium reveal (3rd → 2nd → 1st), report card with awards, shareable images for Instagram Stories, Best Moments timestamps, referee feedback, Play Again flow, and room cleanup.
**FRs covered:** FR11, FR50, FR51, FR52, FR53, FR55, FR56, FR69

### Epic 9: Connection Resilience & Mid-Game Join
Graceful disconnection handling with automatic reconnection, state preservation, turn skipping, and mid-game join with catch-up scoring.
**FRs covered:** FR6, FR57, FR58, FR59, FR60, FR61

### Epic 10: Analytics & Growth Metrics
Game telemetry tracking completion events, share taps, group identity fingerprinting, item usage, second game rate, and referee satisfaction — all feeding product health KPIs.
**FRs covered:** FR63, FR64, FR65, FR66, FR67, FR68

## Epic 1: Room Creation & Joining

Users can create a game room, share a join code or deep link, and friends can join with a display name. The foundation for gathering friends around a pool table.

### Story 1.1: Client & Server Scaffolding

As a developer,
I want the Flutter client and Go server scaffolded with production-grade structure,
So that all future stories have a working local development foundation.

**Acceptance Criteria:**

**Given** the Flutter project does not yet exist
**When** the developer scaffolds via Very Good CLI (`very_good create flutter_app rackup`)
**Then** the project is created with Bloc state management, flavors (dev/staging/prod), localization, and test infrastructure
**And** the project compiles and runs on both iOS and Android simulators

**Given** the Go server project does not yet exist
**When** the developer initializes with `go mod init github.com/ducdo/rackup-server`
**Then** the project is created with the architecture's directory structure (`cmd/server/`, `internal/`)
**And** the `nhooyr.io/websocket` dependency is added
**And** `go run cmd/server/main.go` starts the server locally

**Given** local development environment is configured
**When** the developer runs the server locally
**Then** a local PostgreSQL instance is used for development
**And** `.env` for local secrets exists (never committed)
**And** `DevConfig` with localhost endpoints and Sentry disabled is available

### Story 1.2: Deployment & CI/CD

As a developer,
I want the Go server deployed to Railway with PostgreSQL and CI/CD configured,
So that the app is accessible in a production-like environment from the start.

**Acceptance Criteria:**

**Given** Railway is configured for deployment
**When** the Go server is deployed
**Then** PostgreSQL is provisioned on Railway
**And** the `sessions` table migration (001) runs via `golang-migrate`
**And** the `/health` endpoint returns room count (0), active connections (0), and uptime
**And** the server respects the `PORT` environment variable from Railway
**And** TLS 1.2+ is active (provided by Railway)

**Given** the CI/CD pipeline does not yet exist
**When** a PR is opened on GitHub
**Then** GitHub Actions runs `go test ./...`, `flutter test`, and `flutter analyze`

**Given** the deployment is running
**When** the server encounters a shutdown signal
**Then** graceful shutdown closes all connections cleanly

### Story 1.3: Design System & Theme

As a developer,
I want the core design system established (colors, typography, spacing, player identity, tap targets),
So that all UI stories build on a consistent, accessible visual foundation.

**Acceptance Criteria:**

**Given** the design system does not yet exist
**When** the theme is implemented
**Then** the dark base canvas (#0F0E1A with purple undertone) is set as the Scaffold background across all screens (no light mode)
**And** semantic color tokens are defined: Green (#22C55E), Red (#EF4444), Gold (#FFD700), Electric Blue (#3B82F6), Purple (#A855F7), Off-White (#F0EDF6), Muted Lavender (#8B85A1)
**And** the 4-tier color escalation palette is defined: Lobby (#1A1832), Mild (#0D2B3E), Medium (#3D2008), Spicy (#3D0A0A with #FFD700 gold)

**Given** typography needs to be established
**When** Google Fonts are configured
**Then** Oswald (500/600/700) is available for display/headlines
**And** Barlow Condensed (700) is available for referee script/punishment text
**And** Barlow (400/500/600) is available for UI/body
**And** the 8-token type scale is defined: display-xl (64dp), display-lg (48dp), display-md (36dp), display-sm (32dp), heading (24dp), body-lg (20dp), body (16dp), caption (14dp)

**Given** spacing and interaction standards need to be set
**When** the spacing system is implemented
**Then** 6 spacing tokens are defined on 8dp base: space-xs (4dp), space-sm (8dp), space-md (16dp), space-lg (24dp), space-xl (32dp), space-xxl (48dp)
**And** minimum tap target is 56x56dp for all interactive elements
**And** primary action buttons are minimum 64dp height, full-width

**Given** the 8-slot player identity system needs to be created
**When** the identity system is implemented
**Then** 8 color+shape combos are defined: Coral Circle (#FF6B6B), Cyan Square (#4ECDC4), Amber Triangle (#FFB347), Violet Diamond (#9B59B6), Lime Star (#A8E06C), Sky Hexagon (#74B9FF), Rose Cross (#FD79A8), Mint Pentagon (#55E6C1)
**And** geometric shapes provide fully redundant identification (no color-only information)
**And** colors are verified through a colorblind simulator (Coblis or Sim Daltonism) — Coral/Rose adjusted if they merge for protanopic users

**Given** the app layout constraints
**When** screens render
**Then** all screens are portrait-locked with SafeArea wrapper
**And** the Status/Tier Bar sits below safe area insets
**And** all text meets WCAG AA contrast minimum (4.5:1) — primary text (#F0EDF6 on #0F0E1A) achieves 14.8:1 (AAA)
**And** minimum text size is 14dp throughout the entire app

### Story 1.4: Device Identity & App Home Screen

As a player,
I want to open RackUp and see a clear home screen with options to create or join a room,
So that I can immediately start gathering friends for a game.

**Acceptance Criteria:**

**Given** the player launches the app for the first time
**When** the app initializes
**Then** a UUID v4 device identifier is generated and persisted locally on the device
**And** the identifier is never transmitted in raw form (SHA-256 hashed before any server communication)

**Given** the player is on the home screen
**When** the screen renders
**Then** the headline "Turn pool night into chaos" is displayed in Oswald Bold
**And** a primary "Create Room" button and secondary "Join Room" button are visible
**And** subtext "Grab friends. Find a pool table. Let the chaos begin." is displayed
**And** the design system theme from Story 1.3 is applied (dark canvas, typography, spacing, tap targets)

**Given** the player has launched the app before
**When** they reopen the app
**Then** the same device identifier is loaded from local storage (not regenerated)

### Story 1.5: Room Creation

As a host,
I want to create a new game room and receive a unique join code,
So that I can invite friends to join my game.

**Acceptance Criteria:**

**Given** the player taps "Create Room" on the home screen
**When** the POST /rooms request is sent with the hashed device ID
**Then** the server creates a room goroutine, generates a unique 4-character alpha (A-Z) room code, and returns `{roomCode, jwt}`
**And** the JWT contains claims: roomCode, deviceIdHash, displayName, exp (HS256)
**And** room creation completes within 2 seconds (NFR1)
**And** communication is encrypted via TLS 1.2+ (NFR9)

**Given** the room is created successfully
**When** the host receives the response
**Then** a WebSocket connection is established using the JWT
**And** the host sees the room code displayed prominently
**And** the room code is collision-free against all currently active rooms (NFR18)

**Given** room creation fails (network error, server error)
**When** the server returns an error or the request times out
**Then** a clear, actionable error message is displayed inline (NFR23)
**And** a retry option is available without navigating away

**Given** the room is created
**When** the room goroutine is active
**Then** it supports 2-8 concurrent player connections (FR7)

### Story 1.6: Join Room via Code

As a player,
I want to enter a room code and display name to join my friend's game,
So that I can participate in the game session.

**Acceptance Criteria:**

**Given** the player taps "Join Room" on the home screen
**When** the join screen renders
**Then** a 4-character code input is displayed (large, auto-uppercase, auto-advance between characters)
**And** a display name input field is below the code input
**And** a full-width green "Join" button is visible
**And** the screen follows the dark base canvas with proper typography and contrast

**Given** the player enters a valid room code and display name
**When** they tap "Join"
**Then** POST /rooms/:code/join is sent with the hashed device ID and display name
**And** the server validates the room exists and is accepting players, returns `{jwt}`
**And** a WebSocket connection is established using the JWT
**And** the player joins the room within 3 seconds of tapping Join (NFR2)
**And** no account, email, phone, or social login is required (NFR11)

**Given** the player enters an invalid or expired room code
**When** they tap "Join"
**Then** an inline error "Room not found" is displayed below the input field (NFR23)
**And** the player can correct and retry without navigating away

**Given** the room already has 8 players
**When** a 9th player attempts to join
**Then** the server rejects the join with a clear "Room is full" message

### Story 1.7: Join Room via Deep Link

As a player,
I want to tap a shared link (rackup.app/join/CODE) to join a friend's game directly,
So that I don't have to manually enter a room code.

**Acceptance Criteria:**

**Given** the player has RackUp installed and taps a deep link (rackup.app/join/CODE)
**When** the app opens
**Then** go_router intercepts the deep link and routes directly to the join flow with the room code pre-filled
**And** the player only needs to enter their display name and tap Join
**And** the deep link to lobby flow completes within 4 seconds (NFR8)

**Given** the player does NOT have RackUp installed and taps a deep link
**When** the link opens in the browser
**Then** the player is redirected to the appropriate App Store (iOS App Store or Google Play)
**And** the room code is preserved through the install process
**And** after installation, the app opens directly into the join flow with the room code pre-filled (deferred deep link)

**Given** the deep link contains an invalid or expired room code
**When** the app attempts to join
**Then** the player sees the join screen with an inline error "Room not found"
**And** they can manually enter a different code

### Story 1.8: Accessibility Audit & Compliance

As a player with accessibility needs,
I want the app to be usable with reduced motion, screen readers, and diverse input abilities,
So that RackUp is inclusive and enjoyable for everyone.

**Acceptance Criteria:**

**Given** a player has reduced motion enabled on their device
**When** MediaQuery.disableAnimations is true
**Then** the particle system is disabled entirely
**And** leaderboard positions snap instantly (no shuffle animation)
**And** The Reveal, Eruption, and Shuffle animations show content at final state immediately
**And** tier color transitions swap instantly (no crossfade)
**And** lobby arrivals appear immediately (no slide-in)
**And** button breathing animations are disabled
**And** storm pause for "RECORD THIS" shows red edge flash only
**And** all game logic, sound effects, text content, layouts, and share image generation are maintained

**Given** a player uses a screen reader
**When** they navigate the app
**Then** all buttons are labeled with purpose + context (e.g., "Deploy Blue Shell", "Share report card to Instagram Stories")
**And** player tags announce name + current rank + score
**And** item cards announce name + effect description
**And** event feed entries are announced on arrival
**And** full accessibility is provided for navigable screens (Home, Join, Report Card)
**And** best-effort support is provided for active game screens

**Given** motor accessibility requirements
**When** a player interacts with the app
**Then** no precision gestures are required (no swipes, pinches, long-press-and-drag)
**And** all interactions are single taps on large targets (56dp+ minimum)
**And** full-width primary buttons allow tap anywhere in the lower region to hit target

**Given** cognitive accessibility requirements
**When** the app renders any screen
**Then** each screen has one primary purpose (no multi-modal interfaces)
**And** systems reveal through gameplay, not upfront explanation (progressive disclosure)
**And** the same Player Name Tag component is used consistently everywhere
**And** there is no time pressure on referee input

**Given** audio accessibility requirements
**When** sound effects play
**Then** every sound is supplementary — never the sole indicator of a game event
**And** visual feedback accompanies every sound
**And** device silent/vibrate mode is respected

**Given** the responsive text scaling system
**When** users have accessibility text scaling enabled
**Then** body text (14-20dp) scales up to max 2.0x
**And** display/headings (32-64dp) scale up to max 1.2x
**And** referee punishment text (20dp) scales up to max 1.3x
**And** button labels (28dp) do not scale (1.0x fixed)
**And** a custom clamped TextScaler utility enforces these limits

## Epic 2: Pre-Game Lobby & Punishment Submission

Players see who's joined, submit custom punishments, host configures round count, and starts the game with a deliberate slide-to-start.

### Story 2.1: Pre-Game Lobby Display

As a player,
I want to see who's in the room and their status while waiting for the game to start,
So that I know when everyone is ready.

**Acceptance Criteria:**

**Given** a player has joined a room via code or deep link
**When** the lobby screen renders
**Then** the room code is displayed prominently (Oswald 36dp, gold, letter-spaced)
**And** a large "Share Invite Link" button is the primary action
**And** a player list shows all connected players with Lobby Player Row components
**And** each player row shows: color+shape identity tag (20dp), Oswald SemiBold player name, and status indicator
**And** the host has a gold "HOST" badge next to their name

**Given** a new player joins the room
**When** the server broadcasts the `lobby.player_joined` event via WebSocket
**Then** the new player's row slides in with a 300ms stagger animation
**And** all connected players see the updated player list in real time

**Given** a player is in the lobby
**When** they view the player list
**Then** each player's row shows their current status: "Joining..." (muted), "Writing..." (amber), or "Ready" (green checkmark)

**Given** the lobby is displayed
**When** the screen renders
**Then** the layout is portrait-locked with dark base canvas (#0F0E1A)
**And** the screen follows the bottom-weighted interaction pattern (info top, actions bottom)

### Story 2.2: Punishment Submission

As a player,
I want to submit a custom punishment before the game starts,
So that the punishment deck includes personal, group-specific challenges.

**Acceptance Criteria:**

**Given** a player is in the pre-game lobby
**When** the punishment input area renders
**Then** a text field is displayed (Barlow 14dp) with rotating placeholder examples (e.g., "Do your best impression of someone here")
**And** a "Random" button (purple accent, small) is available to generate a punishment from the built-in deck

**Given** the player has not yet submitted a punishment
**When** they type in the punishment input
**Then** their lobby status changes to "Writing..." (amber) visible to all players
**And** the input field shows a focused state with blue border

**Given** the player has entered punishment text or tapped "Random"
**When** they submit the punishment
**Then** the input becomes read-only with a checkmark visible (Submitted state)
**And** their lobby status changes to "Ready" (green checkmark) visible to all players
**And** the punishment text is sent to the server and stored in the room's punishment deck
**And** the punishment is visible only to players within the same room (NFR13)

**Given** the player taps the "Random" button
**When** a random punishment is generated
**Then** the text field populates with a punishment from the built-in deck
**And** the player can edit it before submitting or submit as-is

### Story 2.3: Game Configuration & Start

As a host,
I want to configure the number of rounds and start the game when everyone is ready,
So that I control the game length and launch timing.

**Acceptance Criteria:**

**Given** the host is in the pre-game lobby
**When** the configuration area renders
**Then** a round count selector is displayed with options 5, 10, and 15 (default 10)
**And** the slide-to-start component is visible at the bottom of the screen

**Given** not all players have submitted punishments and the timeout has not elapsed
**When** the host views the slide-to-start
**Then** the component is disabled (30% opacity) and cannot be activated

**Given** all players have submitted punishments OR the configurable timeout has elapsed
**When** the host views the slide-to-start
**Then** the component becomes active with a shimmer animation along the track
**And** the rounded track (52dp height) shows a circular thumb (44dp, green gradient with play arrow)
**And** track text reads "SLIDE TO START GAME" (Oswald SemiBold 14dp, muted)

**Given** the host slides the thumb past the 70% threshold
**When** the threshold is crossed
**Then** the game starts with haptic feedback
**And** the server receives a `lobby.start_game` message with the configured round count
**And** all players are transitioned from lobby to the game state

**Given** the host slides the thumb but releases before the 70% threshold
**When** the thumb is released
**Then** the thumb snaps back to the starting position
**And** the game does NOT start

**Given** accessibility requirements
**When** a user cannot perform the slide gesture
**Then** a 3-second long-press hold alternative triggers the game start

**Given** the host is NOT the current player
**When** a non-host player views the lobby
**Then** the slide-to-start component is not visible
**And** a waiting indicator shows "Waiting for host to start..."

## Epic 3: Core Gameplay & Referee

A referee is assigned, confirms shots turn-by-turn, the system awards points and tracks streaks, and all players watch the live leaderboard with animated shuffles and sound effects.

### Story 3.1: Referee Assignment & Role Reveal

As a player,
I want to know who the referee is when the game starts,
So that everyone understands their role and the game can begin.

**Acceptance Criteria:**

**Given** the host has started the game
**When** the server initializes the game state
**Then** one player is assigned the referee role
**And** the server tracks which client holds referee authority
**And** the server rejects referee actions from non-authoritative clients

**Given** a player is assigned as referee
**When** the role is assigned
**Then** a full-screen Role Reveal Overlay displays: microphone emoji (48dp), "YOU'RE THE REFEREE NOW" (Oswald Bold 42dp, gold), the referee's name in their identity color, and a gold horizontal rule
**And** The Reveal animation plays with a 2-second hold
**And** the overlay auto-dismisses with no interaction required
**And** the referee's screen transitions to the 4-region Referee Command Center layout: Status Bar (~60dp top), Stage Area (~40% upper-middle showing current shooter), Action Zone (~35% lower-middle), Footer (~80dp bottom with leaderboard peek)

**Given** a player is NOT the referee
**When** the game starts
**Then** their screen displays the 4-region Player Screen layout: Header (~60dp with game progress), Leaderboard (~50% upper), Event Feed (~25% middle), My Status (~15% bottom)
**And** all screens are portrait-locked with dark base canvas

**Given** the game has started
**When** either screen layout renders
**Then** the Progress/Tier Bar shows at the top with the current round label ("R1/10" format)
**And** the tier is set to Mild with teal color
**And** no back navigation, settings menu, or navigation stack is available (linear flow)

### Story 3.2: Turn Management & Shot Confirmation

As a referee,
I want to confirm each player's shot as made or missed,
So that the game progresses accurately turn by turn.

**Acceptance Criteria:**

**Given** the game is in progress and it is a player's turn
**When** the referee views the Action Zone
**Then** the current shooter's name is displayed prominently in the Stage Area
**And** two Big Binary Buttons are displayed side-by-side: MADE (green gradient) and MISSED (red gradient)
**And** buttons are Oswald Bold 28dp uppercase, minimum 100dp height, with breathing pulse animation in default state

**Given** the referee taps MADE or MISSED
**When** the shot result is confirmed
**Then** the button scales to 97% on press
**And** the result is sent to the server as a `referee.confirm_shot` message
**And** the server validates the action comes from the authoritative referee client
**And** the result propagates to all players within 2 seconds (NFR3)

**Given** the referee has just confirmed a shot
**When** within 5 seconds of confirmation
**Then** an Undo Button appears (48x48dp, deliberately smaller than primary actions)
**And** a shrinking ring countdown animation shows remaining seconds
**And** tapping Undo reverts the shot result and returns MADE/MISSED buttons

**Given** 5 seconds have elapsed since shot confirmation
**When** the Undo window expires
**Then** the Undo Button fades to 0% opacity
**And** the shot result locks permanently
**And** the turn advances to the next player in rotation

**Given** the system manages turn order
**When** a turn completes
**Then** the next player in the room's turn order becomes the current shooter
**And** the referee screen updates to show the new shooter's name
**And** all player screens reflect whose turn it is

### Story 3.3: Scoring, Streaks & Consequence Chain

As a player,
I want to earn points for made shots and build streaks for bonus points,
So that consistent shooting is rewarded and the game stays competitive.

**Acceptance Criteria:**

**Given** the referee confirms a shot as MADE
**When** the server processes the shot result
**Then** the shooter receives +3 base points (FR26)
**And** the shooter's consecutive made shot count increments
**And** streak bonuses are awarded: +1 for 2 consecutive, +2 for 3 consecutive, +3 for 4+ consecutive (FR27)
**And** the total points (base + streak bonus) are added to the player's score

**Given** the referee confirms a shot as MISSED
**When** the server processes the shot result
**Then** the shooter's streak resets to zero (FR28)
**And** no points are awarded for the shot

**Given** a shot result has been processed
**When** the server completes the consequence chain
**Then** an atomic `game.turn_complete` message is sent to all clients containing: score update, streak status, leaderboard recalculation, and UI event triggers
**And** the consequence chain follows deterministic execution order: shot_result → streak_update → [punishment_slot] → [item_drop_slot] → [mission_check_slot] → score_update → leaderboard_recalc → UI_events → sound_triggers → [record_this_check_slot]
**And** the chain is designed with explicit extension points (marked with brackets above) so that Epics 4 (punishments), 5 (items), 6 (missions), and 8 ("RECORD THIS") can plug into the pipeline without modifying core chain logic
**And** the entire chain resolves within the 2-second sync window across all devices

**Given** a player has consecutive made shots
**When** their streak status changes
**Then** the appropriate streak indicator is displayed to all players: "Warming Up" (2 streak), "ON FIRE" (3 streak), "UNSTOPPABLE" (4+ streak)
**And** the Streak Fire Indicator component shows escalating visuals: single flame amber (2), double flame gold with glow (3), triple flame pulsing gold (4+)
**And** streak milestone transitions use The Eruption animation pattern

### Story 3.4: Live Leaderboard

As a player,
I want to see a live leaderboard that updates after every shot,
So that I always know the standings and feel the competitive tension.

**Acceptance Criteria:**

**Given** a game is in progress
**When** the player views the Leaderboard zone on their screen
**Then** all players are listed with their Player Name Tag (color+shape identity tag), display name (Oswald SemiBold), and current score (Oswald Bold, right-aligned)
**And** players are sorted by score descending with rank numbers

**Given** a shot result causes a ranking change
**When** the leaderboard recalculates
**Then** position-shuffle animations play using The Shuffle motion pattern (fluid cascading with staggered timing)
**And** animations render at 60fps on mid-range devices (NFR4)
**And** the shuffle feels like entertainment, not just data — position changes become moments

**Given** a player has an active streak (2+ consecutive makes)
**When** the leaderboard renders
**Then** a Streak Fire Indicator appears next to that player's entry
**And** the indicator intensity matches the streak level (warming up / ON FIRE / UNSTOPPABLE)

**Given** the leaderboard leader changes
**When** the new leader is at the top
**Then** a subtle radial glow effect appears behind the leader's entry

**Given** a player views their own entry
**When** the leaderboard renders
**Then** their row is highlighted with a blue tint (Highlighted state) to distinguish from other players

### Story 3.5: Game Progression & Triple Points

As a player,
I want the game to escalate in intensity as it progresses,
So that the final rounds feel climactic and high-stakes.

**Acceptance Criteria:**

**Given** a game is in progress
**When** the Progress/Tier Bar renders (~60dp fixed height, top of screen)
**Then** it displays: tier tag badge (left), progress bar fill (4dp, color matches current tier), round label "R{current}/{total}" format (right)

**Given** the game is in the first 30% of rounds
**When** the tier is evaluated
**Then** the tier is "Mild" with teal color (#0D2B3E)
**And** the tier tag badge displays "MILD"

**Given** the game is between 30-70% of rounds
**When** the tier transitions
**Then** the tier changes to "Medium" with amber color (#3D2008)
**And** a 500ms crossfade via AnimatedContainer transitions the scaffold background
**And** the tier tag badge updates to "MEDIUM"

**Given** the game is in the final 30% of rounds
**When** the tier transitions
**Then** the tier changes to "Spicy" with deep red color (#3D0A0A)
**And** the tier tag badge updates to "SPICY"

**Given** the game enters the final 3 rounds
**When** triple-point scoring activates (FR16)
**Then** all point values are tripled: base shots, streak bonuses, and mission bonuses (FR31)
**And** all players receive a notification of triple-point activation
**And** the Progress/Tier Bar shows a pulsing gold "3X" badge with red background
**And** gold accents (#FFD700) appear in the tier color scheme

### Story 3.6: Sound Effects & Screen Awake

As a player,
I want sound effects to punctuate key game moments and my screen to stay on,
So that the party atmosphere is enhanced and I don't miss anything.

**Acceptance Criteria:**

**Given** the app's audio system is initialized
**When** the game starts
**Then** a centralized AudioListener BlocListener is active at the app level
**And** 5 MVP sound effects are preloaded: Blue Shell impact, leaderboard shuffle, punishment reveal, streak fire, podium fanfare

**Given** a key game event occurs (streak milestone, leaderboard shuffle, punishment reveal)
**When** the event is processed by the AudioListener
**Then** the corresponding sound effect triggers within 200ms of the event (NFR6)
**And** each sound effect is <2 seconds duration (accent, not narration)

**Given** the device is in silent or vibrate mode
**When** a sound effect would trigger
**Then** the sound is suppressed and the device's silent/vibrate setting is respected
**And** visual feedback still accompanies the event (sound is never the sole indicator)

**Given** a game session is active
**When** the player's device would normally auto-lock or dim
**Then** the screen stays awake for the duration of the active game session (FR49)
**And** screen-awake is released when the game ends or the player leaves

**Given** battery efficiency requirements
**When** the game is running for 60 minutes
**Then** total battery consumption does not exceed 15% on a typical modern smartphone (NFR25)
**And** no unnecessary background processing or continuous polling occurs

### Story 3.7: Event Feed & Game End

As a player,
I want to see a feed of game events and know when the game ends,
So that I can follow the action and celebrate the conclusion.

**Acceptance Criteria:**

**Given** the game is in progress
**When** game events occur (shots, streaks, score changes)
**Then** Event Feed Items appear in the Event Feed zone as compact rows
**And** each row has a 3dp colored left border: blue for items, red for punishments, gold for streaks, purple for missions, green for scores
**And** event text is Barlow 13dp with optional emoji
**And** maximum 4 events are visible at a time

**Given** events are arriving rapidly (cascade sequence)
**When** multiple events arrive in quick succession
**Then** each event holds for a minimum of 2 seconds before older events scroll off
**And** this ensures readability during rapid cascade sequences

**Given** the configured number of rounds has been completed
**When** the final turn's consequence chain resolves
**Then** the server sends a `game.game_ended` message to all clients (FR17)
**And** the system transitions all players to the post-game state
**And** no more shots can be confirmed
**And** the game flow moves forward (no back navigation to active game)

### Story 3.8: "RECORD THIS" Moments

As a player,
I want to be alerted before shareable moments happen during gameplay,
So that I can start recording and capture the best parts of the game.

**Acceptance Criteria:**

**Given** a shareable moment is about to occur (spicy punishment, Blue Shell deployment, streak break)
**When** the server identifies the moment in the consequence chain (via the record_this_check extension point)
**Then** a "RECORD THIS" alert fires on all players' screens 3-5 seconds BEFORE the reveal
**And** the alert is NOT shown to the target player (to preserve surprise)

**Given** the "RECORD THIS" alert fires
**When** the alert renders
**Then** it displays: camera emoji (80dp with pulsing border), "RECORD THIS" text (Oswald Bold 36dp, red), descriptive subtext explaining what's about to happen, and a tier badge
**And** the storm pause mechanic activates: particles freeze and dim, screen-edge red pulse fires once (brief flash of red glow around phone border)
**And** silence of the storm serves as the alert

**Given** the storm pause is active
**When** the alert auto-dismisses and the reveal begins
**Then** the reveal hits with The Eruption pattern at full intensity
**And** the storm (particles, effects) erupts back to full activity
**And** the timestamp of the moment is recorded for the Best Moments list

**Given** the "RECORD THIS" alert is displayed
**When** the timer expires
**Then** the alert auto-dismisses without requiring any user interaction
**And** gameplay is never blocked by the alert (no modal dialogs, no OK buttons)

**Given** the consequence cascade includes a RECORD THIS trigger
**When** cascade timing is calculated
**Then** the RECORD THIS path gets ~8-12 seconds total (3-5s storm pause + reveal)

## Epic 4: Punishment System

Missed shots trigger punishments from escalating tiers (mild → medium → spicy), with custom player-submitted punishments shuffled in. The referee announces from their screen.

### Story 4.1: Punishment Draw & Tier Escalation

As a player,
I want missed shots to trigger punishments that escalate as the game progresses,
So that the stakes rise naturally and the game gets wilder over time.

**Acceptance Criteria:**

**Given** the referee confirms a shot as MISSED
**When** the server processes the consequence chain
**Then** the system draws a punishment from the punishment deck (FR41)
**And** the punishment draw is included in the atomic `game.turn_complete` message

**Given** the game is in the first 30% of rounds
**When** a punishment is drawn
**Then** it is drawn from the "Mild" tier

**Given** the game is between 30-70% of rounds
**When** a punishment is drawn
**Then** it is drawn from the "Medium" tier

**Given** the game is in the final 30% of rounds
**When** a punishment is drawn
**Then** it is drawn from the "Spicy" tier

**Given** players submitted custom punishments during the pre-game lobby
**When** the punishment deck is constructed
**Then** custom punishments are shuffled into all tiers throughout the game (FR43)
**And** custom punishments are tagged as "CUSTOM" tier

**Given** the punishment deck is active
**When** punishments are drawn throughout the game
**Then** the deck does not run out (punishments recycle if necessary)
**And** recently drawn punishments are deprioritized to avoid immediate repeats

### Story 4.2: Punishment Display & Referee Announcement

As a referee,
I want to see the drawn punishment on my screen and announce it dramatically,
So that punishments become theatrical moments that entertain the group.

**Acceptance Criteria:**

**Given** a punishment has been drawn from the deck
**When** the referee's Action Zone updates
**Then** the punishment text is displayed as teleprompter-style text (Barlow Condensed Bold) designed for reading aloud
**And** a "THE POOL GODS HAVE SPOKEN" header frames the punishment (depersonalizing the source)
**And** a Punishment Tier Tag badge is displayed: MILD (neutral background), MEDIUM (amber background), SPICY (red background), or CUSTOM (purple background)
**And** the tier tag always includes both color AND text label (never color alone)
**And** the punishment slides into view using The Reveal animation pattern

**Given** the referee has read the punishment aloud
**When** the referee taps the "Delivered" button
**Then** the game advances to the next turn
**And** the "Delivered" button always exists as an exit path regardless of whether the punishment was performed
**And** the punishment appears in all players' Event Feed with a red left border

**Given** the punishment is displayed to the referee
**When** the referee text renders
**Then** the copy style matches the current tier: neutral tone for Mild, heightened language for Medium, dramatic language for Spicy (FR42 escalation through copy)

**Given** the consequence cascade includes a punishment
**When** the cascade timing is calculated
**Then** a mild punishment gets ~2 seconds of reveal time
**And** a medium punishment with item drop gets ~4 seconds
**And** a spicy punishment with item drop gets ~5-8 seconds of build-up

## Epic 5: Items & Power-Ups

Players receive items on misses with rubber banding, hold one at a time, and deploy them targeting other players. Full 10-item deck with strategic effects.

### Story 5.1: Item Drop & Inventory

As a player,
I want to receive power-up items when I miss a shot,
So that misses feel like opportunities rather than pure punishment.

**Acceptance Criteria:**

**Given** the referee confirms a shot as MISSED
**When** the server processes the consequence chain
**Then** there is a 50% default probability of the player receiving an item (FR32)
**And** the item drop check is part of the atomic `game.turn_complete` message

**Given** the player is in last place
**When** an item is drawn
**Then** they draw from the full item deck including Blue Shell (FR33)
**And** the item drop is framed as empowering ("The pool gods smile upon you"), not consolation

**Given** the player is in first place
**When** an item is drawn
**Then** they are excluded from Blue Shell draws (FR33)
**And** they draw from the remaining 9 items

**Given** a player receives an item
**When** the item is assigned
**Then** the Item Card component displays in the My Status zone: dark card with electric blue (#3B82F6) 2dp border, 36dp item icon with accent color background, Oswald SemiBold 14dp item name, and "TAP TO DEPLOY" affordance text
**And** the card has a faint glow in default state

**Given** the player already holds an item
**When** they receive a new item
**Then** the new item replaces the current item (use-it-or-lose-it, FR34)
**And** the previous item is lost with no recovery

**Given** the player does not hold an item
**When** the Item Card zone renders
**Then** the card is hidden or shows a 30% opacity placeholder (Empty state)

### Story 5.2: Item Deployment & Targeting

As a player,
I want to deploy my held item at any time during the game, targeting another player when needed,
So that I can use items strategically for maximum impact.

**Acceptance Criteria:**

**Given** a player holds an item
**When** they tap the Item Card
**Then** the card border brightens (Pressable state)
**And** if the item requires a target, a Targeting overlay slides up from the bottom

**Given** the Targeting overlay is displayed
**When** the player views the target list
**Then** each Targeting Row shows: rank (Oswald 14dp), player tag (24dp), Oswald SemiBold name (18dp), Oswald Bold score (20dp right-aligned)
**And** rows are minimum 56dp height for tap targets
**And** tap-outside the overlay dismisses it (cancel path always available)

**Given** the player is deploying a Blue Shell
**When** the Targeting overlay displays
**Then** the first-place player's row has a gold border and crosshair animation (FR36a targeting)
**And** the social moment builds anticipation for both attacker and target

**Given** the player taps a target row (or deploys a non-targeted item)
**When** the deployment is initiated
**Then** deployment happens with ONE tap, no confirmation dialog (no-confirmation design)
**And** the Item Card border flashes gold with The Reveal animation (Deploying state)
**And** an optimistic animation plays immediately (~500ms masking server latency)
**And** the server validates item ownership and target validity

**Given** the server confirms the item deployment
**When** confirmation is received
**Then** the impact animation plays (The Eruption for high-impact items like Blue Shell)
**And** the item is removed from the player's inventory
**And** the event appears in all players' Event Feed with a blue left border

**Given** the server rejects the deployment (race condition, item already used)
**When** the rejection is received
**Then** a "fizzle" animation plays instead of the impact
**And** an optional event feed entry notes the fizzle
**And** gameplay is never blocked

**Given** a player deploys an item during another player's active cascade
**When** the deployment message reaches the server
**Then** the item deployment queues behind the active cascade to prevent state corruption

**Given** a player can deploy items at any time during active gameplay
**When** it is NOT the player's turn
**Then** the Item Card is still tappable and deployment is still available (anytime deployment)

### Story 5.3: Item Effects — Offensive Items

As a player,
I want offensive items that let me disrupt other players' scores and streaks,
So that I can strategically attack leaders and create dramatic comebacks.

**Acceptance Criteria:**

**Given** a player deploys a Blue Shell targeting the first-place player
**When** the effect resolves
**Then** the target loses 3 points (FR36a)
**And** the target must shoot off-handed on their next turn
**And** all players see the Blue Shell impact with The Eruption animation and Blue Shell sound effect
**And** the effect text throbs with electric blue energy

**Given** a player deploys a Score Steal targeting another player
**When** the effect resolves
**Then** 5 points transfer from the target to the deployer (FR36c)
**And** the leaderboard updates with position-shuffle animation if rankings change

**Given** a player deploys a Streak Breaker targeting another player
**When** the effect resolves
**Then** the target's streak resets to zero (FR36d)
**And** the target's Streak Fire Indicator disappears
**And** the event appears in all players' Event Feed

**Given** a player deploys a Reverse targeting another player
**When** the effect resolves
**Then** the deployer's score and the target's score are swapped (FR36g)
**And** the leaderboard updates with position-shuffle animation

**Given** a player deploys a Trap Card
**When** the effect is activated
**Then** the next player to miss a shot receives the deployer's punishment instead of a random draw (FR36f)
**And** the Trap Card activation is revealed to all players when triggered

### Story 5.4: Item Effects — Defensive & Self Items

As a player,
I want defensive and self-buff items that protect me or boost my scoring,
So that I have options beyond attacking others.

**Acceptance Criteria:**

**Given** a player deploys a Shield
**When** the shield is active
**Then** the next punishment or item effect targeting this player is blocked (FR36b)
**And** a visual shield indicator appears on the player's leaderboard entry
**And** when the shield blocks an effect, a "blocked" animation plays and the shield is consumed

**Given** a player deploys a Double Up
**When** the effect is active and the player makes their next shot
**Then** the shot is worth double points (base + streak bonus doubled) (FR36e)
**And** a visual indicator shows Double Up is active
**And** the effect expires after one shot attempt (made or missed)

**Given** a player deploys Immunity
**When** the immunity is active and the player misses a shot
**Then** the punishment draw is skipped for that miss (FR36h)
**And** a visual indicator shows Immunity is active
**And** the immunity expires after one punishment skip

**Given** a player deploys a Mulligan
**When** the Mulligan is activated
**Then** an in-app poll overlay slides up for all players to vote (allow/deny) (FR36i)
**And** if the group votes to allow, the player redoes their last shot
**And** if the group votes to deny, the Mulligan is consumed with no effect
**And** the overlay has a tap-outside dismiss (cancel path)

**Given** a player deploys a Wildcard
**When** the Wildcard is activated
**Then** the player enters a custom rule via text input (FR36j)
**And** the system displays the custom rule to all players for 3 turns
**And** the rule appears prominently with a gold border in the Event Feed

## Epic 6: Secret Missions

The referee delivers hidden objectives to shooters via whisper prompts, with bonus points for completion. Full 15-mission deck with varying difficulty.

### Story 6.1: Mission Assignment & Delivery

As a shooter,
I want to receive secret missions that add hidden objectives to my turn,
So that each shot has a chance to be more than just points — it becomes a performance.

**Acceptance Criteria:**

**Given** it is a player's turn to shoot
**When** the server determines mission assignment
**Then** there is a 33% default probability of a secret mission being assigned (FR37)
**And** mission assignment is determined server-side before the shot

**Given** a mission is assigned
**When** the referee's screen updates
**Then** a Mission Delivery Card appears with purple accent styling
**And** the card shows: "SECRET MISSION" header (Barlow Condensed 11dp, purple), mission text (Barlow Condensed Bold 16dp), and "Whisper this to [Player Name]" instruction
**And** The Reveal animation plays on the card's appearance
**And** a "Mission Delivered" button is displayed

**Given** the mission is displayed to the referee
**When** the referee and shooter view the mission
**Then** only the shooter and the referee can see the assigned mission (FR38)
**And** other players see no indication that a mission was assigned

**Given** the referee has whispered the mission to the shooter
**When** the referee taps "Mission Delivered"
**Then** the mission is activated for the current turn
**And** the Mission Delivery Card dismisses
**And** the referee proceeds to shot confirmation (MADE/MISSED)

**Given** a mission has been assigned
**When** the referee has NOT yet tapped "Mission Delivered"
**Then** the shot confirmation buttons (MADE/MISSED) are not yet available
**And** the mission delivery gates the shot phase

### Story 6.2: Mission Completion & Deck

As a player,
I want to earn bonus points for completing secret missions,
So that skilled play and showmanship are rewarded beyond basic scoring.

**Acceptance Criteria:**

**Given** the system has a mission deck
**When** the game initializes
**Then** the full 15-mission deck is loaded with varying difficulty levels and bonus point values ranging from +2 to +8 (FR40)
**And** harder missions award more bonus points

**Given** a shooter has an active mission and makes their shot
**When** the referee evaluates mission completion
**Then** the referee screen shows a mission completion prompt (completed / not completed)
**And** the referee confirms based on their observation of the shooter's performance (FR39)

**Given** the referee confirms mission completion
**When** the server processes the confirmation
**Then** the mission bonus points (+2 to +8 based on mission difficulty) are awarded to the shooter (FR30)
**And** the bonus is included in the turn's score calculation
**And** during triple-point rounds, mission bonuses are also tripled
**And** a mission completion event appears in all players' Event Feed with a purple left border

**Given** the referee indicates the mission was NOT completed
**When** the server processes the result
**Then** no bonus points are awarded
**And** the game proceeds normally with no penalty for failed missions

**Given** missions are drawn throughout the game
**When** a mission is selected
**Then** the system avoids repeating recently assigned missions
**And** the deck reshuffles if all missions have been used

## Epic 7: Referee Rotation & Resilience

Referee role rotates after each round with smooth handoff mechanics, shooter-skip logic, and automatic failover when the referee disconnects.

### Story 7.1: Referee Rotation & Handoff

As a player,
I want the referee role to rotate so everyone gets a turn playing,
So that no one is stuck as referee the entire game.

**Acceptance Criteria:**

**Given** a full round has completed (all players have taken their turn)
**When** the round ends
**Then** the system prompts the current referee that rotation is available (FR22)
**And** the prompt shows who the next referee in rotation would be

**Given** the current referee accepts the rotation
**When** they hand off the role
**Then** referee authority transfers to the next player in the rotation order on the server (FR23)
**And** the server updates which client holds referee authority
**And** the new referee sees the Role Reveal Overlay: microphone emoji (48dp), "YOU'RE THE REFEREE NOW" (Oswald Bold 42dp, gold), their name in identity color, gold horizontal rule
**And** The Reveal animation plays with a 2-second hold, then auto-dismisses
**And** the new referee's screen transitions to the Referee Command Center layout
**And** the previous referee's screen transitions to the Player Screen layout

**Given** the next player in rotation is the current shooter
**When** the system determines the next referee
**Then** that player is skipped and the following player in rotation becomes the candidate (FR24)

**Given** the current referee declines or ignores the rotation prompt
**When** the next turn begins
**Then** the current referee continues in the role
**And** rotation is prompted again after the next full round

### Story 7.2: Referee Disconnect Failover

As a player,
I want the game to continue smoothly if the referee disconnects,
So that one person's connection issue doesn't ruin the game for everyone.

**Acceptance Criteria:**

**Given** the referee's WebSocket connection drops
**When** the server detects the disconnection
**Then** the server holds the referee slot for up to 60 seconds (matching reconnection protocol)
**And** an immediate handoff prompt is sent to the next player in the rotation order (FR25)

**Given** the next player receives the referee handoff prompt
**When** the prompt displays
**Then** a single-tap "Accept" button is shown to take over as referee
**And** tapping Accept transfers referee authority to this player on the server
**And** the Role Reveal Overlay plays for the new referee
**And** the game continues without interruption

**Given** the original referee reconnects after handoff
**When** their connection is restored
**Then** they rejoin as a regular player (not as referee)
**And** their score, items, and turn position are preserved
**And** a toast notification informs them of the role change

**Given** the original referee reconnects before anyone accepts the handoff
**When** their connection is restored within the 60-second window
**Then** they resume as referee with full state sync
**And** the handoff prompt is dismissed for other players

**Given** no player accepts the handoff prompt
**When** the 60-second timeout elapses
**Then** the server automatically assigns the next connected player as referee
**And** the Role Reveal Overlay plays for the newly assigned referee

## Epic 8: Post-Game Ceremony & Sharing

Dramatic podium reveal (3rd → 2nd → 1st), report card with awards, shareable images for Instagram Stories, Best Moments timestamps, and referee feedback. ("RECORD THIS" moments moved to Epic 3, Story 3.8, as they fire during active gameplay.)

### Story 8.1: Podium Ceremony

As a player,
I want a dramatic reveal of the final standings,
So that the end of the game feels like a celebration with suspense and fanfare.

**Acceptance Criteria:**

**Given** the game has ended and all players transition to post-game
**When** the podium ceremony begins
**Then** the referee controls the sequential reveal with taps: 3rd place → 2nd place → 1st place (FR51)

**Given** a podium position is unrevealed
**When** the position renders
**Then** it displays as "?" in Hidden state (full-screen centered layout)

**Given** the referee taps to reveal the next position
**When** the reveal triggers
**Then** the Podium Reveal component shows: position number (Oswald Bold 64dp for 1st, 48dp for 2nd/3rd), player name with identity tag, final score
**And** background glow matches the placement tier
**And** The Reveal animation plays for 1-2 seconds (Revealing state → Revealed state)

**Given** 1st place is revealed
**When** the final reveal triggers
**Then** The Eruption animation plays at full intensity
**And** the podium fanfare sound effect triggers
**And** 1st place gets breathing glow effect

**Given** all three positions are revealed
**When** the ceremony completes
**Then** all players can view the complete podium
**And** the flow advances to the report card screen

### Story 8.2: Report Card & Awards

As a player,
I want to see a report card with fun awards after the game,
So that every player gets recognized and the game stats are celebrated.

**Acceptance Criteria:**

**Given** the podium ceremony is complete
**When** the report card screen renders
**Then** it displays the following awards with player names (FR50):
**And** MVP — highest score
**And** Sharpshooter — best accuracy (made/total shots ratio)
**And** Punching Bag — most punishments received
**And** Participant Trophy — lowest score
**And** Hot Hand — longest streak achieved during the game
**And** Mission Master — most missions completed

**Given** the report card is displayed
**When** Best Moments data is available
**Then** timestamps are listed (e.g., "Blue Shell at 9:47 PM") so players can find moments in their own recordings (FR55)
**And** timestamps are converted from UTC to local time for display

**Given** the report card renders
**When** the visual design is applied
**Then** RackUp branding appears in gold
**And** the diagonal slash brand motif is used as a dividing element
**And** no particles or visual storm effects are shown (clean clarity register)
**And** the report card is designed to look like a shareable ownership signal (Spotify Wrapped style)

**Given** the game has ended
**When** the report card data is generated
**Then** it completes within 3 seconds of game end (NFR5)

### Story 8.3: Share Image & Social Sharing

As a player,
I want to share a styled image of the report card on social media,
So that I can show off the game to friends and spread the word.

**Acceptance Criteria:**

**Given** the report card is displayed
**When** the player taps the share button
**Then** a styled shareable image is generated via RepaintBoundary + RenderRepaintBoundary.toImage() as PNG (FR52)

**Given** the share image is generated
**When** the image renders
**Then** two format options are available: 9:16 vertical (Instagram Stories, primary share target) and 1:1 square (general sharing)
**And** both formats include: RackUp branding (gold), event date, podium placements (1st/2nd/3rd), stacked awards with player names, diagonal slash brand motif
**And** the image looks native to Instagram Stories — not like a screenshot (2-second attention window optimized)

**Given** the player selects a format
**When** they confirm sharing
**Then** the device's native share sheet opens via `share_plus` package (FR53)
**And** the player can share to any app available on their device
**And** the share button tap is tracked for analytics (FR64)

**Given** the share image generation
**When** the same widget is used
**Then** the ceremony widget and share image widget are the same (consistent visual)

### Story 8.4: Referee Feedback

As a player,
I want to rate the referee experience after the game,
So that referee quality is tracked and can be improved.

**Acceptance Criteria:**

**Given** the report card is displayed
**When** the feedback prompt renders
**Then** each player sees a micro-feedback prompt: "How was the referee?" with thumbs up / thumbs down options (FR56)
**And** the prompt is non-blocking and optional

**Given** a player submits referee feedback
**When** the feedback is sent
**Then** the thumbs up/down is recorded server-side for Referee Satisfaction measurement
**And** the feedback is associated with the game session

### Story 8.5: Play Again

As a host,
I want to start a new game with the same group after the game ends,
So that the fun continues seamlessly without everyone re-joining manually.

**Acceptance Criteria:**

**Given** the host is on the post-game report card screen
**When** the host taps "Play Again"
**Then** the server creates a new room and migrates all connected players automatically (FR69)
**And** display names and device ID associations are preserved
**And** new JWTs are issued for each player
**And** existing WebSocket connections are reused (no new handshake)
**And** the old room goroutine shuts down after archival is confirmed
**And** all players land in the new lobby with zero friction

**Given** a non-host player is on the post-game screen
**When** the host initiates Play Again
**Then** the player is automatically migrated to the new lobby without any action required

### Story 8.6: Room Cleanup & Exit

As a player,
I want the game to clean up properly when I leave,
So that my data is preserved for analytics and the room resources are released.

**Acceptance Criteria:**

**Given** the game has ended
**When** the room state is evaluated
**Then** post-game report card data remains accessible to all players until they leave the results screen (FR11)
**And** once all players exit, room state is archived to PostgreSQL for analytics
**And** the room goroutine shuts down and the room code is released

**Given** a player wants to leave after the game
**When** they exit the results screen
**Then** they return to the app home screen
**And** their session data is preserved server-side for analytics

## Epic 9: Connection Resilience & Mid-Game Join

Graceful disconnection handling with automatic reconnection, state preservation, turn skipping, and mid-game join with catch-up scoring.

### Story 9.1: Player Disconnection & Turn Skipping

As a player,
I want the game to continue smoothly if someone disconnects,
So that one person's connection issue doesn't stop the fun for everyone else.

**Acceptance Criteria:**

**Given** a player's WebSocket connection drops
**When** the server detects the disconnection
**Then** the server marks the player as disconnected
**And** a `system.player_disconnected` message is broadcast to all other players (FR57)

**Given** other players receive the disconnection notification
**When** their screens update
**Then** the disconnected player's Player Name Tag dims to 40% opacity with "reconnecting..." subtext (Dimmed state)
**And** the visual indicator is visible on both the leaderboard and any other player references

**Given** it is the disconnected player's turn
**When** the turn order advances to them
**Then** the system automatically skips their turn and advances to the next connected player (FR58)
**And** no action is required from the referee or other players
**And** the game continues without interruption

**Given** a player has disconnected
**When** the server maintains their state
**Then** the player's score, held items, streak count, turn position, and all stats are preserved server-side (FR59)
**And** the player slot is held for 60 seconds before being marked as timed out

### Story 9.2: Reconnection & State Sync

As a player,
I want to seamlessly rejoin the game if my connection drops,
So that I don't lose my progress or miss what's happening.

**Acceptance Criteria:**

**Given** a player's connection has dropped
**When** the client detects the disconnection
**Then** the client initiates reconnection with exponential backoff: 1s → 2s → 4s → 8s → 16s max
**And** reconnection attempts continue for up to 60 seconds
**And** after 60 seconds without success, a "Connection Lost" screen is displayed

**Given** the player reconnects within 60 seconds
**When** the WebSocket connection is re-established using JWT + device ID hash
**Then** the server performs a connection swap (new connection replaces old) (FR60)
**And** a full game state snapshot is sent to the reconnected client
**And** the reconnection is silent — no disruptive UI for the reconnecting player
**And** the player's Name Tag is restored from Dimmed to normal state on all other screens
**And** a toast notification appears on other players' screens confirming the reconnection

**Given** the player missed turns while disconnected
**When** they reconnect and receive the state snapshot
**Then** a notification informs them of any turns that were skipped during their absence (FR61)

**Given** the player backgrounds the app (e.g., switches to camera to record)
**When** they return to the app
**Then** the app recovers gracefully without losing game state or room connection (NFR21)
**And** if the WebSocket dropped during backgrounding, automatic reconnection triggers
**And** the experience is seamless with no manual action required

### Story 9.3: Mid-Game Join & Connection Loss

As a player,
I want to join a game that's already in progress,
So that latecomers can still participate in the fun.

**Acceptance Criteria:**

**Given** a game is in progress and has fewer than 8 players
**When** a new player joins via room code or deep link
**Then** the player enters the game immediately (FR6)
**And** they receive a catch-up starting score equal to the current lowest player's score
**And** they receive a consolation item from the item deck
**And** they are added to the turn rotation at the next available position

**Given** a mid-game join occurs
**When** other players' screens update
**Then** the new player appears in the leaderboard with their catch-up score
**And** a Player Name Tag slides in with The Shuffle animation
**And** an event feed entry announces the late arrival

**Given** the player has fully lost connection (beyond 60-second reconnection window)
**When** the "Connection Lost" screen is displayed
**Then** a pulsing "Reconnecting..." indicator is shown
**And** the server preserves the room state for up to 5 minutes

**Given** the player reconnects after 60 seconds but within 5 minutes
**When** the connection is re-established
**Then** the player rejoins with full state sync
**And** the game resumes from the current state

**Given** more than 5 minutes have elapsed
**When** the player attempts to reconnect
**Then** the message "Game session expired. Start a new room?" is displayed
**And** the player can return to the home screen to create or join a new room

## Epic 10: Analytics & Growth Metrics

Game telemetry tracking completion events, share taps, group identity fingerprinting, item usage, second game rate, and referee satisfaction — all feeding product health KPIs.

### Story 10.1: Game Event Tracking & Data Pipeline

As a product owner,
I want game events tracked and persisted to a database,
So that I can measure product health and understand how games play out.

**Acceptance Criteria:**

**Given** a game starts
**When** the server initializes the game session
**Then** a "game started" event is recorded with timestamp, room code, player count, and configured round count (FR63)

**Given** a game ends normally (all rounds completed)
**When** the game transitions to post-game
**Then** a "game finished" event is recorded with timestamp, final scores, duration, and round count
**And** all buffered game events are drained from the Go channel to PostgreSQL asynchronously
**And** migrations 002 (`session_players` table) and 003 (`session_events` table) are created and run as part of this story
**And** session data is written to the `sessions` table (created in Story 1.2) and `session_players` table
**And** timestamped events are written to the `session_events` table

**Given** a game is abandoned (all players disconnect, host leaves mid-game)
**When** the room goroutine detects abandonment
**Then** a "game abandoned" event is recorded with timestamp, last known state, and player count at abandonment
**And** partial session data is still archived

**Given** game events are being written to PostgreSQL
**When** all players in a room generate events simultaneously at game end
**Then** the burst writes are handled without data loss (NFR19)
**And** the buffered Go channel absorbs the burst before async drain

**Given** session data is stored in PostgreSQL
**When** 90 days have elapsed since the session
**Then** the data is anonymized or purged per the retention policy (NFR12, GDPR/CCPA)

**Given** a user requests deletion of their data
**When** the GDPR/CCPA deletion request is processed
**Then** all records matching their device ID hash are deleted or anonymized (NFR15)

### Story 10.2: Player Engagement Metrics

As a product owner,
I want to track key player engagement actions,
So that I can measure feature adoption and optimize the game experience.

**Acceptance Criteria:**

**Given** a player taps the share button on the post-game report card
**When** the share action is initiated
**Then** a "share_tapped" event is recorded with timestamp, share format (9:16 or 1:1), and session ID (FR64)

**Given** a player deploys an item during gameplay
**When** the item effect resolves
**Then** an "item_deployed" event is recorded with: item type, deployer device ID hash, target device ID hash (if applicable), game progression percentage, and timestamp (FR66)
**And** item usage frequency can be queried per item type

**Given** the same host creates a new room immediately after a game ends (Play Again or manual)
**When** sequential room creation is detected
**Then** a "second_game" event is recorded linking the previous session to the new session (FR67)
**And** the Second Game Rate metric can be calculated (target: >50%)

**Given** a player submits referee satisfaction feedback (thumbs up/down)
**When** the feedback is recorded
**Then** a "referee_feedback" event is stored with: rating (up/down), session ID, referee device ID hash, and rater device ID hash (FR68)
**And** the Referee Satisfaction metric can be queried per session

### Story 10.3: Group Identity & Return Tracking

As a product owner,
I want to identify recurring friend groups across game sessions,
So that I can measure 7-Day Group Return rate and understand social retention.

**Acceptance Criteria:**

**Given** a game session ends and player data is archived
**When** session_players records are written
**Then** each record contains: device_id_hash, display_name, session_id, final_score, and awards
**And** the composite index `idx_session_players_device_id_session_id` on `(device_id_hash, session_id)` exists from day one

**Given** the system needs to identify a recurring group
**When** a group identity query runs
**Then** a self-join on `session_players` finds overlapping device ID hashes across sessions (FR65)
**And** groups of 3+ matching device IDs within a 7-day window are flagged as returning groups

**Given** the `group_sessions` materialized view exists
**When** the 7-Day Group Return KPI is queried
**Then** the view returns sessions where the same player composition (or significant overlap) played again within 7 days
**And** the query is performant through ~3,500 player rows/week (100 rooms/day target)

**Given** the group_sessions view does not yet exist
**When** this story is implemented
**Then** migration 004 creates the `group_sessions` materialized view
**And** the view is queryable and returns correct results against existing `sessions` and `session_players` tables (created in Stories 1.2 and 10.1)
**And** all database naming follows snake_case convention with `idx_` prefix for indexes and `fk_` prefix for foreign keys
