---
stepsCompleted: ["step-01-init", "step-02-discovery", "step-02b-vision", "step-02c-executive-summary", "step-03-success", "step-04-journeys", "step-05-domain-skipped", "step-06-innovation", "step-07-project-type", "step-08-scoping", "step-09-functional", "step-10-nonfunctional", "step-11-polish", "step-12-complete"]
workflowCompleted: true
classification:
  projectType: mobile_app
  domain: entertainment_social_gaming
  complexity: low-medium
  projectContext: greenfield
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-rackup-2026-03-20.md
  - _bmad-output/planning-artifacts/research/market-rackup-global-bar-game-market-research-2026-03-02.md
  - _bmad-output/planning-artifacts/research/market-vietnam-pool-culture-research-2026-03-02.md
  - _bmad-output/planning-artifacts/research/party-game-market-research-report-2026-03-02.md
  - rackup-pitch.txt
  - rackup-game-script.txt
documentCounts:
  briefs: 1
  research: 3
  brainstorming: 0
  projectDocs: 0
  additional: 2
workflowType: 'prd'
date: 2026-03-20
author: Ducdo
---

# Product Requirements Document - RackUp

**Author:** Ducdo
**Date:** 2026-03-20

## Executive Summary

RackUp is a mobile party platform that layers structured chaos onto real bar games — starting with pool. Players join a room on their phones via a shareable code, play real pool at a real table, and the app orchestrates secret missions, Mario Kart-style items, escalating punishments, and a dramatic leaderboard on top. The core design principle: **missing is fun, not failure.** Bad players have the best time — every miss drops consolation items, triggers punishments, and fuels chaos. RackUp turns a forgettable bar night into a story your friends retell for weeks.

The target user is the friend group already at the bar (ages 21-34) — specifically the "Social Organizer" who texts the group chat every Thursday and needs a reason to make the night an event. RackUp's acquisition funnel is champion-driven: one person discovers, downloads, and creates a room; everyone else joins via code with zero friction. Viral growth is powered by shareable post-game report cards (MVP, Sharpshooter, Participant Trophy) designed for Instagram Stories and group chats.

The problem: most people at a pool table are bored 70-80% of the time. If you're not shooting, you're standing around. For casual players — the vast majority — it's worse: they miss, they disengage, and by the third game someone suggests leaving. No product exists that makes bar games fun for everyone at the table regardless of skill level. RackUp fills that gap.

### What Makes This Special

1. **Blue ocean — zero competition.** No app overlays party mechanics onto real-world bar games. Not for pool, not for darts, not for any bar sport. RackUp creates an entirely new product category at the intersection of the $8.46B party game market and the competitive socializing mega-trend (93% Gen Z participation).

2. **Skill-equalizing emotional design.** Rubber banding, consolation items, and escalating punishments ensure the worst player has the most memorable night. This inverts every competitive game ever built — the emotional hook is that bad play creates the best moments.

3. **Democratized competitive socializing.** Flight Club proved tech-enhanced bar games generate £80.4M/year — but requires multi-million-pound venue buildouts. RackUp delivers a comparable experience with just phones and a pool table that already exists. Software scales; real estate doesn't.

Pool is the launch sport. The platform engine is designed to expand to darts, beer pong, cornhole, and other bar sports — each unlocking new geographic markets. Year 1: the default app for pool night. Year 3: "The Jackbox of real-world bar games."

## Project Classification

- **Project Type:** Mobile app (mobile-first party platform, phone-based room creation, item management, leaderboard, and social sharing)
- **Domain:** Entertainment / Social Gaming (party gaming bridging physical bar games with digital mechanics)
- **Complexity:** Low-Medium (no regulatory requirements; complexity lies in game balance, social mechanics, and viral loop design)
- **Project Context:** Greenfield (new product, no existing codebase; validated by a working manual game script prototype)

## Success Criteria

### User Success

**During the Game:**
- **Game completion rate >80%** — % of rooms that finish a full game vs. abandoned mid-game. If groups aren't finishing, the experience isn't compelling enough. (Benchmark: Jackbox ~75% completion)
- **Second game rate >50%** — % of groups that start a second game the same night. Proves the first-game experience triggers "one more round."
- **Active participation >90%** — % of players who interact beyond just shooting (referee actions, item use, reactions). If people are just watching, the chaos layer isn't working.
- **Non-shooter engagement (The Lena Metric)** — % of players who never take a shot but remain active for the full game through referee duties, voting, and reactions. If Lena is engaged, the product works for everyone.
- **Referee satisfaction >70% positive** — % of players who enjoy the referee role vs. see it as a chore. If refereeing feels like work, players stop rotating into it and the game dies.

**After the Game:**
- **Share rate >40%** — % of games where the share button is tapped on the post-game report card. Target: 40% (success), 70%+ (north star). (Benchmark: Picolo estimated <15% — beating this by 3x validates the physical-digital sharing thesis)
- **7-Day Group Return** — % of groups that create a new room within 7 days. The single most important user success metric. Requires group identity fingerprinting (matching player composition across sessions). (Benchmark: Among Us ~30% 7-day retention at peak)

**The Aha Moments:**
- Jake: The first time the leaderboard flips and the whole group erupts
- Danny: He misses, draws a Blue Shell, nukes first place, and the table loses it
- Lena: She realizes she's been laughing for an hour straight and hasn't checked her phone once
- Maya: The post-game report card roasts the worst player — she screenshots and shares immediately

### Business Success

**3-Month Goals (Validation):**
- Consistent week-over-week organic download growth without paid acquisition
- Active rooms per week growing alongside downloads — downloads without rooms means onboarding is broken
- 7-Day Group Return measurable and trending upward
- Share rate >40% proving the viral loop works

**12-Month Goals (Product-Market Fit):**
- Weekly active groups as the core business metric — recurring sessions prove habit, not novelty
- Viral coefficient >1 — each active group generates at least one new group organically
- Retention curve flattens — groups that play 3+ times continue indefinitely (the "standing weekly bar night" behavior)
- Monetization signal — early data on willingness to pay for premium features (theme packs, cosmetics, additional game modes)

**The Nightmare Metric:** Downloads without rooms = the product is failing. Rooms without return = the first-night experience isn't compelling enough.

### Technical Success

- **Room creation success rate >99%** — if creating a room fails, the champion looks foolish in front of friends and adoption dies
- **Join latency <3 seconds** — code entry to active in the room, zero friction
- **Leaderboard sync <2 seconds** — leaderboard updates propagate to all clients within 2 seconds of referee confirmation. Eventual consistency is acceptable for a bar environment; strict millisecond sync is unnecessary.
- **Network resilience: 60-second recovery** — game state recoverable after network interruption up to 60 seconds without data loss. Bars have terrible WiFi; basement pool halls have worse cell signal. Graceful degradation on poor connectivity is a bar environment requirement, not a nice-to-have.
- **Crash-free session rate >99%** — a crash mid-game with friends is unrecoverable; the group won't retry
- **Support 2-8 concurrent players per room** — the defined player range
- Instrument max concurrent rooms from day one but defer scaling targets until post-launch data exists

### Measurable Outcomes

| KPI | Target | Benchmark | Why It Matters |
|-----|--------|-----------|----------------|
| Game Completion Rate | >80% | Jackbox ~75% | Basic health — is the experience compelling enough to finish? |
| Second Game Rate | >50% | No direct comp | Stickiness — does one game create demand for another? |
| 7-Day Group Return | Trending upward | Among Us ~30% at peak | The make-or-break metric for product-market fit |
| Share Rate | >40% | Picolo <15% | Viral loop — 3x the best drinking app validates the model |
| Referee Satisfaction | >70% positive | No direct comp | Referee role is the engagement engine — it can't feel like a chore |
| Room Creation Success | >99% | Industry standard | Champion confidence — first impression can't fail |
| Join Latency | <3 seconds | Jackbox ~5s | Zero-friction onboarding for guests |
| Leaderboard Sync | <2 seconds | N/A | Everyone sees the same dramatic moment at the same time |
| Network Recovery | 60s interruption | N/A | Bar environments demand connectivity resilience |
| Item Use Rate (Phase 2) | Track from launch | N/A | If items aren't deployed, the chaos engine isn't working |
| Viral Replication (Phase 2) | Track from launch | N/A | % of guests who later create their own room as host |

## Product Scope

### Scope Constraint: Never Split the Party

Whatever the revenue model, it must not fragment the group experience. If one player pays and others don't, everyone must still access the same game. Either one person pays for the whole group (Jackbox model) or premium features are cosmetic/additive only — never access-gating core game modes during a live session. This constraint shapes every monetization and premium feature decision.

### MVP, Growth & Vision

See **Project Scoping & Phased Development** for the complete MVP feature set, phased roadmap, walking skeleton build order, authentication model, and risk mitigation strategy. The full scoping section is the authoritative reference for what's in and out of each phase.

## User Journeys

### Journey 1: Jake — The First Night (Champion Acquisition Path)

**Who:** Jake, 27. The group chat organizer. Downloads every party app, brings card games to bars, always looking for the thing that makes Thursday night legendary. Not the best pool player — doesn't care.

**Opening Scene:** Thursday, 8:30 PM. Jake's friend group is at their usual bar. Two people are playing pool, four are standing around checking their phones. Jake overheard a guy at work talking about this app that "turned pool night into chaos." He downloaded it during lunch.

**Rising Action:** Jake opens RackUp, taps "Create Room," and gets a 4-letter code. He holds up his phone: "Everyone join this — trust me." Five friends scan the code or type it in. They're in within seconds. The app asks everyone to submit one custom punishment before the game starts. Danny writes "loser has to text their ex." Lena writes "sing the chorus of whatever song is playing." Already laughing.

**Late Joiner Beat:** Round 3. Jake's friend Marcus texts: "just parked, omw." He arrives, Jake shares the room code, and Marcus joins mid-game. The app slots him in with a starting score equal to the current lowest player's score and drops him a consolation item — instant catch-up mechanic. The game doesn't pause; Marcus is in the rotation starting next turn. No friction, no restart.

**Climax:** Round 4. Danny misses his shot — again — but this time the app drops him a Blue Shell. He targets Jake, who's in first place. Jake loses 3 points and has to shoot off-handed next turn. The leaderboard shuffles with an animation. The table erupts. Danny is screaming. Lena, who's been refereeing, announces it like a boxing match knockout. Jake misses his off-handed shot, draws a spicy punishment: "Group composes and sends ONE text from your phone." Five people huddle around Jake's phone composing the most embarrassing text they can think of. Nobody has looked at Instagram in two hours.

**Resolution:** Game ends. The post-game report card drops: Danny wins MVP (somehow), Jake gets "Punching Bag" for most punishments received, Maya screenshots it and posts to her Instagram story with "pool night hits different now 🎱." Jake texts the group chat before he's even left the bar: "Same time next Thursday?"

**Requirements revealed:** Room creation flow, join-by-code onboarding, custom punishment submission, item system (Blue Shell targeting), referee turn management, leaderboard animations, post-game report card generation, share functionality, mid-game player joining with catch-up scoring, dynamic player list management.

---

### Journey 2: Maya — The Viral Loop (Content & Sharing Path)

**Who:** Maya, 24. Decent at pool but she's really here for the moments. Everything is potential content. If it's not on her story, did it even happen?

**Opening Scene:** Maya joins Jake's room by typing in the code. She sees the player list populate — fun. The app asks for a custom punishment; she writes something spicy because she knows it'll be funny when it lands on someone else.

**Rising Action:** Maya's shooting well — she's in second place after round 3, riding a streak. The app assigns her a secret mission: "Shoot with your eyes closed for +6 bonus." Only she can see it. She closes her eyes, takes the shot, and somehow banks it in. The app explodes with a mission complete animation. She gets +6 bonus and jumps to first place. She yells "DID YOU SEE THAT?!" — nobody knows she had a secret mission. She's glowing.

**Climax:** Round 7. The "RECORD THIS" prompt flashes on everyone's screens — someone just drew a spicy punishment. It's Danny: "Read your last 3 sent texts out loud." Maya already has her phone camera up. Danny's reading his texts to his mom about forgetting to buy groceries. The table is dying. Maya's recording everything.

**Resolution:** Post-game report card drops. Maya taps the share button immediately — it generates a styled image in **9:16 Instagram Stories aspect ratio** with everyone's stats, awards, and the "Participant Trophy" roast for the worst player. She posts it to her Instagram story and sends it to three group chats. Two friends who weren't there DM her: "What is this?? We need to come next week." The viral loop closes.

**Requirements revealed:** Share button and styled image generation in 9:16 (Instagram Stories) and 1:1 (general sharing) formats, "RECORD THIS" prompt system, secret mission private display, mission completion animation, Best Moments timestamps on report card, social media-optimized image templates.

---

### Journey 3: Danny — The Underdog (Skill-Equalizing Path)

**Who:** Danny, 29. Loves competition, terrible at pool. In a normal game, he's out after three turns and standing around with nothing to do. With RackUp, he's the chaos agent.

**Opening Scene:** Danny joins the room. He knows he's going to miss most of his shots. In a normal pool game, that means 45 minutes of watching other people play. He's already resigned.

**Rising Action:** Round 1 — Danny misses. But instead of the usual embarrassment, the app drops him an item: Score Steal. He pockets it (well, holds it — use-it-or-lose-it). Round 2 — he misses again. The app gives him a mild punishment: "Compliment the person to your left." Easy. He also gets assigned a secret mission for his next shot: "Shoot with your non-dominant hand for +7." Round 3 — he switches to his left hand, takes a wild shot... and misses. But the group respects the attempt. He draws another item: Reverse. He's collecting power while everyone else is just scoring points.

**Climax:** Round 5. Danny deploys Reverse — swapping his score with Jake's, who's in first place. Jake drops from 24 points to Danny's 6. Danny jumps to 24. The leaderboard animation goes insane. Jake is shouting. Danny is standing on a chair. Lena is announcing "THE BIGGEST UPSET IN RACKUP HISTORY!" Danny deploys Score Steal next turn and takes 5 more points from Maya. He's in first place and hasn't made a single shot all night.

**Resolution:** Danny finishes second overall (Jake clawed back in the triple-points final rounds). But Danny had the best night of anyone. He used every item, caused maximum chaos, and has three stories to tell at work tomorrow. The app gave him agency that real pool never could.

**Requirements revealed:** Item drop mechanics on miss, rubber banding (last place draws better items), use-it-or-lose-it inventory flow, Reverse and Score Steal item effects, streak reset on miss, leaderboard position-shuffle animations, consolation item probability system.

---

### Journey 4: Lena — The Reluctant Convert (Non-Player Engagement Path)

**Who:** Lena, 26. Got dragged here. Doesn't play pool. Already thinking about checking Instagram. The litmus test for whether RackUp works for *everyone*.

**Opening Scene:** Lena's at the bar because Jake asked. She's holding a drink, watching people set up pool, and quietly wishing she'd stayed home. Jake hands her his phone: "You're the referee first round. Just tap the buttons." She takes it skeptically.

**Rising Action:** The referee screen lights up. It shows her whose turn it is, what to announce, and two big buttons: "MADE IT" and "MISSED." She taps "MISSED" after Danny's shot. The app triggers an item drop and a punishment — the phone tells her to announce: "Danny, your punishment is: do your best impression of someone in the group." She reads it out loud in a flat voice. Everyone laughs at Danny's impression. Next turn, the app gives her a secret mission to whisper to Maya. She leans over: "Bank shot for +5." She's a conspirator now.

**Climax:** Round 4. Lena's been rotating in and out of the referee role for two rounds. She's now announcing turns like a WWE commentator — "LADIES AND GENTLEMEN, stepping up to the table, with a streak of ZERO, the one, the only, DANNY 'THE DISASTER' NGUYEN!" The group is feeding off her energy. She's controlling the vibe without ever touching a cue. When a spicy punishment drops ("Group composes and sends ONE text from your phone"), Lena is the one who grabs the phone and starts typing.

**Resolution:** Game ends. Lena never took a single shot. She's the loudest person at the table. She texts the group chat on the way home: "When are we doing this again?" The Lena Metric is validated — RackUp converted a reluctant non-player into the heart of the night.

**Requirements revealed:** Referee screen UX (clear, fun, dramatic — not administrative), referee rotation mechanics, mission whisper/delivery flow, punishment announcement display, referee role as engagement mechanism for non-players, accessibility of referee role to people who don't know pool.

---

### Journey 5: The Referee Experience (In-Game Role Journey)

**Who:** Any player during their referee rotation. This journey maps the *functional experience* of being referee, not the emotional arc (covered in Lena's journey).

**Opening Scene:** The app notifies the player: "You're the referee this round!" The screen transforms from the player view to the referee command center.

**Rising Action:**

*Turn Start:* The referee screen shows the current shooter's name prominently. Below it: a mission probability check has already run. If triggered, the screen shows the secret mission text with an instruction: "Whisper this to [Player Name]" and a "Mission Delivered" confirmation button. If no mission triggered, it skips straight to the shot phase.

*Shot Phase:* Two large buttons dominate the screen — "MADE IT" (green) and "MISSED" (red). The referee watches the real shot and taps the result. **Undo window:** For 5 seconds after tapping, a small "Undo" button appears in case the referee fat-fingers the wrong result. After 5 seconds, the result locks and consequences trigger.

*Post-Shot — Made:* The screen shows points awarded (base + streak bonus + mission bonus if applicable). A dramatic "ON FIRE!" or "UNSTOPPABLE!" banner if streak qualifies. Referee taps "Announce" to push the update to all players' leaderboards.

*Post-Shot — Missed:* The screen shows the consequence chain: (1) streak reset notification, (2) item drop result (if triggered) — "Danny receives: Blue Shell" — referee announces it, (3) punishment draw — the punishment text appears with escalation tier tag (MILD/MEDIUM/SPICY or CUSTOM). Referee reads it aloud and taps "Punishment Delivered."

*Turn End:* Leaderboard updates push to all phones. Referee screen shows the next shooter's name. The cycle repeats.

**Referee Rotation:** After a configurable number of turns (default: one full round through all players), the app prompts the current referee: "Pass the whistle?" with a "Next Referee: [Player Name]" display. The current referee taps "Hand Off" and the next player's screen transforms into the referee command center. The outgoing referee's screen transitions back to the player view. The rotation follows player order so everyone gets a turn. If the next referee in rotation is also the current shooter, the app skips to the next person and circles back.

**Punishment Escalation Logic:** Tiers are based on game progression percentage, not fixed round numbers — ensuring the escalation arc works regardless of game length:
- **Mild:** First 30% of total rounds
- **Medium:** 30-70% of total rounds
- **Spicy:** Final 30% of total rounds
- **Custom punishments** are shuffled into all tiers throughout the game

For a 5-round game: rounds 1-2 mild, round 3 medium, rounds 4-5 spicy. For a 10-round game: rounds 1-3 mild, 4-7 medium, 8-10 spicy. For a 15-round marathon: rounds 1-5 mild, 6-10 medium, 11-15 spicy. The escalation arc always builds to a peak regardless of session length.

**Climax:** Final 3 rounds — the referee screen flashes "TRIPLE POINTS ACTIVATED" with instructions to announce it dramatically. Every made shot shows the tripled score. The energy ratchets up.

**Resolution:** Game ends. Referee role passes or game concludes. The referee screen transitions to the post-game ceremony flow — the referee controls the dramatic reveal: 3rd place → 2nd place → 1st place, tapping to reveal each with a pause for suspense.

**Requirements revealed:** Referee screen state machine (turn start → mission delivery → shot result → consequences → turn end), mission probability trigger and display, two-button shot confirmation UX, 5-second undo window for shot result correction, streak status display and announcement triggers, item drop display for referee announcement, punishment text display with tier tagging, percentage-based punishment escalation engine adapting to variable game length, referee rotation system with configurable interval and skip logic, referee handoff UX, leaderboard push trigger, triple-points mode UI, post-game ceremony flow with sequential reveal controls.

---

### Journey 6: Jake — The Return (Week 2 Retention Path)

**Who:** Jake again. It's been 6 days since the first game. He's been thinking about it all week.

**Opening Scene:** Tuesday. Jake's at his desk. He gets a push notification from RackUp: "Your group hasn't played in 6 days. Danny still holds the Blue Shell record. Time for a rematch?" He screenshots it and sends it to the group chat: "Thursday. Same bar. Run it back." Three people respond within minutes.

**Rising Action:** Thursday, 9 PM. Jake opens RackUp and taps "Create Room." New code generated. He shares it. Five people join — four from last week plus one new friend, Marcus, who saw Maya's Instagram story and has been asking about it all week. Marcus joins the room for the first time. The app onboards him with a 10-second tutorial: "Real pool. App chaos. Submit a punishment to start." He's in.

**Climax:** The group is faster this time — they know the flow. Referee rotations are smooth. When someone draws a Blue Shell, the whole table pre-reacts because they know what's coming. The new player Marcus is confused for exactly one round, then he's all in. He draws a Wildcard and invents a rule: "Everyone has to narrate their shot in a British accent for 3 turns." The group is in tears. Marcus is already a convert.

**Resolution:** Post-game report card drops. This time the app shows a "Group Stats" section — "Session #2 with this crew. Returning players: 4. New recruit: 1." Jake feels ownership. This is *his* thing now — the weekly bar night tradition. Marcus asks to be added to the group chat. The flywheel accelerates.

**Requirements revealed:** Push notification re-engagement system, group identity recognition (returning player composition matching), new player onboarding within an existing room, "Group Stats" on report card (session count, returning vs. new players), room creation for returning champions, invite link sharing, first-time player tutorial overlay.

---

### Journey 7: The Crash Landing (Graceful Failure Path)

**Who:** The whole group — but the bar's basement has terrible cell signal, and things go sideways.

**Opening Scene:** Round 6 of a 10-round game. Everyone's invested — Danny is in first place for the first time ever, Lena is refereeing with full WWE energy, Maya has been recording highlights. The game is peaking. Then Marcus's phone shows a spinning indicator. His signal dropped.

**Rising Action — Disconnection:** The app detects Marcus is offline. On everyone else's screen, Marcus's avatar dims with a small "reconnecting..." indicator. The game does NOT pause — the referee skips Marcus's turn automatically and moves to the next player. Marcus's score, items, and stats are preserved server-side. The group barely notices; the energy keeps going.

**Recovery — 40 seconds later:** Marcus's phone reconnects. The app silently syncs his state — he sees the current leaderboard, his score is intact, and his turn slot is restored in the rotation. A small toast notification: "You're back! You missed 1 turn." No drama, no restart, no data loss. Marcus jumps right back into heckling Danny.

**Escalation — Referee Disconnect:** Two rounds later, Lena (currently refereeing) walks to the bar to grab a drink and her signal drops. The app detects the referee is offline and prompts the next player in rotation: "Lena stepped away — take over as referee?" One tap and the referee screen transfers. When Lena comes back, she's slotted back as a regular player. Seamless.

**The Undo Save:** Round 8. The new referee, Maya, accidentally taps "MADE IT" when Jake clearly missed. She immediately taps the undo button (within the 5-second window). The result reverts. Jake's miss processes correctly — streak resets, item drops, punishment draws. Crisis averted. Without undo, the group would have argued for 3 minutes and the energy would have died.

**Resolution:** The game finishes. Nobody talks about the disconnections because nobody noticed. The post-game report card shows Marcus was "offline for 1 turn" in a minor stat footnote. The night is remembered for Danny's comeback, not for technical hiccups. The app survived a real bar environment.

**Requirements revealed:** Player disconnection detection and visual indicator, automatic turn-skipping for disconnected players, server-side state preservation during disconnection, silent reconnection with state sync, referee disconnection handling with automatic handoff prompt, 5-second undo window for shot result correction, graceful degradation on poor connectivity, game continuation without full player count, reconnection state recovery within 60-second window, offline turn tracking for post-game stats.

---

### Journey Requirements Summary

| Journey | Key Capabilities Revealed | Scope |
|---------|--------------------------|-------|
| **Jake — First Night** | Room creation, join-by-code, custom punishments, item targeting, referee management, leaderboard animations, report card, sharing, mid-game joining with catch-up scoring | MVP |
| **Maya — Viral Loop** | Share image generation (9:16 + 1:1 formats), "RECORD THIS" prompts, secret mission privacy, mission completion animation, social media-optimized templates | MVP |
| **Danny — Underdog** | Item drops on miss, rubber banding, use-it-or-lose-it inventory, item effects (Reverse, Score Steal), consolation mechanics | MVP |
| **Lena — Reluctant Convert** | Referee UX (fun, not administrative), referee rotation, mission whisper flow, punishment announcement, non-player engagement | MVP |
| **Referee Experience** | Referee state machine, shot confirmation with 5s undo, mission/item/punishment display, streak announcements, percentage-based punishment escalation, referee rotation with handoff UX, triple-points mode, ceremony controls | MVP |
| **Jake — The Return** | Push notifications, group identity fingerprinting, new player onboarding, first-time tutorial overlay | MVP (analytics), Post-MVP (group stats UX, re-engagement notifications) |
| **The Crash Landing** | Disconnection detection, auto turn-skip, server-side state preservation, silent reconnection, referee failover, 60s recovery window, game continuation without full player count | MVP |

**Critical design themes across all journeys:**
1. **Zero dead time** — every journey shows every person always doing something
2. **Chaos creates stories** — the memorable moments come from items, punishments, and upsets, not from skilled play
3. **The referee is the energy** — the referee role appears in every journey as the emotional amplifier
4. **Sharing is built into the arc** — the report card isn't an afterthought, it's the climax of Maya's journey and the acquisition hook for new players
5. **Bar-proof resilience** — the app survives terrible connectivity, fat-fingered inputs, and people wandering away from the table
6. **The game never stops** — disconnections, late joiners, and referee handoffs all resolve without pausing the action

## Innovation & Novel Patterns

### Detected Innovation Areas

1. **Physical-Digital Bridge (Category Creation)** — No app overlays digital party mechanics onto a real-world physical game in progress. This isn't an incremental improvement; it's a new product category. Virtual pool games (8 Ball Pool, 800M downloads) replace the real game. Drinking apps (Picolo, 7.7M downloads) are disconnected from any activity. RackUp is the first to *enhance* the physical game with digital chaos. The constraint (must be physically together at a pool table) is also the moat — digital-first competitors can't replicate the experience.

2. **Inverted Skill Design (Emotional Innovation)** — Every competitive game in history rewards the best player. RackUp inverts this: rubber banding, consolation items, and escalating punishments ensure the worst player creates the most chaos and has the most memorable night. "Missing is fun, not failure" challenges the fundamental assumption of competitive gaming. This is the emotional hook that makes RackUp work for friend groups where skill levels vary widely.

3. **Democratized Competitive Socializing (Access Innovation)** — Flight Club proved tech-enhanced bar games = £80.4M/year, but requires multi-million-pound venue buildouts. RackUp delivers the same emotional experience — technology-enhanced social competition with viral sharing — using just phones and a pool table that already exists. Same experience, radically lower infrastructure cost. Software scales; real estate doesn't.

### Validation Approach

- The manual game script IS the prototype — if groups have fun with paper and dice, the digital version amplifies it
- Game completion rate >80% validates the physical-digital bridge works
- Danny's journey (worst player, best night) validates inverted skill design
- Share rate >40% vs. Picolo's <15% validates democratized competitive socializing creates viral moments
- 7-Day Group Return validates the experience is repeatable, not just a novelty

### Risk Mitigation

- **Referee honesty risk** — shot results are self-reported. Mitigated by social pressure (everyone is watching) and the 5-second undo button for corrections. Future: optional photo/video shot verification.
- **Skilled player frustration** — inverted design could frustrate good players who feel "punished for winning." Mitigated by streak bonuses (+1/+2/+3 for consecutive makes) and mission bonus points that still reward skill. The best player can still win — they just can't coast.
- **Venue dependency** — requires a bar with a pool table. Mitigated by multi-sport expansion (darts, cornhole, beer pong use different venues) and the sheer ubiquity of pool tables in bars (38.5% of global pool table market is in North America alone).
- **App Store positioning** — must avoid "drinking game" classification. Mitigated by positioning as "party game," no alcohol imagery, punishments framed as "challenges" not "drinks."

## Mobile App Specific Requirements

### Project-Type Overview

RackUp is a mobile-first party platform built with Flutter for cross-platform delivery (iOS + Android from a single codebase). The app is screen-based — no camera, GPS, or Bluetooth required. The core technical challenge is real-time multiplayer state synchronization in bar environments with poor connectivity.

### Platform Requirements

- **Framework:** Flutter (cross-platform, single codebase for iOS + Android)
- **Minimum OS:** iOS 15+ / Android 10+ (API 29+) — covers 95%+ of target demographic devices
- **Screen orientation:** Portrait-locked (one-handed bar use)
- **Target devices:** Standard smartphones — no tablet-specific layouts for MVP
- **App size:** Target <50MB initial download — bar discovery means people download on the spot over cell data

### Guest Join Decision

**MVP: App-required (Among Us model).** All players download the Flutter app to join a room. Deep links (rackup.app/join/ABCD) direct to the App Store if not installed, then open directly into the room on launch.

**Why app-required for MVP:**
- Server-authoritative state with WebSockets is cleaner when all clients run the same native code
- A web client adds a second platform to build and maintain — doubles the surface area for bugs
- Full native experience for all players: haptics, sound effects, animations, push notification permission path
- The champion (Jake) is motivated enough to get friends to download — the game script prototype already proved groups will adopt when one person pushes

**Phase 2: Web join (Jackbox model).** Lightweight browser-based guest experience for players who won't download. Reduced feature set (no haptics, no push path) but zero-friction join. Evaluate based on MVP data — if download friction kills adoption (rooms created but guests don't join), prioritize web join. If adoption is healthy, deprioritize.

### Device Permissions & Features

- **Required:** Internet access (cellular + WiFi)
- **Fast-follow:** Push notification permission (requested after first completed game, not on install)
- **Haptic feedback** — subtle vibration on key moments:
  - Blue Shell impact (targeted player feels it)
  - Leaderboard position change (your rank shifts)
  - Streak milestones (ON FIRE!, UNSTOPPABLE!)
  - Punishment delivery (the recipient's phone buzzes)
- **Haptic strategy:** Use platform-native haptics (iOS Taptic Engine, Android vibration API). Degrade gracefully on devices without haptic support — visual-only is fine.
- **Screen wake lock:** Keep screen awake during active game sessions. Players hold their phones at a bar for 30-60 minutes — screen dimming or locking mid-game breaks the referee flow, misses turn notifications, and kills momentum. Use Flutter's `wakelock_plus` or equivalent. Release wake lock when game ends or app backgrounds.
- **Not required:** Camera, microphone, GPS, Bluetooth, contacts, photo library

### Audio

- **Short, punchy sound effects** on key game events — designed to cut through bar ambient noise. **MVP essential (5 sounds)** marked with ★, remainder added in Phase 1.5:
  - ★ Leaderboard shuffle (whoosh/slide)
  - ★ Streak milestones ("ON FIRE!" chime, "UNSTOPPABLE!" escalation)
  - ★ Blue Shell launch and impact
  - ★ Punishment reveal
  - ★ Post-game ceremony (podium reveal fanfare)
  - Item received
  - Mission complete
  - Triple points activation
- **Volume behavior:** Respects device silent/vibrate mode — no sound when muted. When unmuted, volume controllable within app settings.
- **Design principle:** Sounds are *accents*, not narration. Each effect is <2 seconds. No background music for MVP (bar already has music). Sound effects amplify the party atmosphere without competing with it.
- **Implementation:** Flutter `audioplayers` package or equivalent. Preload all sound assets on game start to avoid mid-game loading latency.

### State Architecture & Offline Mode

- **Server-authoritative game state** — the server is the source of truth for scores, items, streaks, leaderboard positions, and turn order. Client devices render state received from the server.
- **Why server-authoritative:** Prevents score disputes, enables reconnection without data loss, supports group identity analytics, and ensures all players see consistent state.
- **Backend technology:** The specific backend stack (managed real-time service like Firebase/Supabase, custom WebSocket server in Node.js/Go/Elixir, or game-specific platform like Nakama/Colyseus) is an **architecture-phase decision**. The PRD defines the requirements the backend must meet:
  - Real-time bidirectional communication (WebSocket or equivalent)
  - Support 2-8 concurrent connections per room
  - Game state persistence for the duration of a session
  - Session archival for analytics after game completion
  - <2 second state propagation to all clients
  - 60-second disconnection recovery without data loss
- **Room lifecycle:** Rooms are **ephemeral** — created, played, ended, archived for analytics. New game = new room = new code. Rooms do not persist between sessions. This simplifies server state management and avoids stale room cleanup. If the same group plays next Thursday, Jake creates a fresh room with a new code.
- **Connectivity resilience (bar environment design):**
  - Game state recoverable after network interruption up to 60 seconds
  - Disconnected players auto-skipped in turn rotation, restored on reconnect
  - Referee disconnect triggers automatic handoff prompt to next player
  - Client-side optimistic updates for responsiveness, server reconciliation for accuracy
  - Offline queue: actions taken during brief disconnects are queued and synced on reconnect
- **No true offline mode** — the game requires at least one connected device (the server connection) to function. This is acceptable because the use case (group at a bar) inherently requires multiple connected phones.

### Push Notification Strategy (Fast-Follow)

- **Not in MVP** — defer push notification implementation to post-launch
- **MVP prerequisite:** Instrument group identity fingerprinting from day one so re-engagement notifications have context when push is added
- **Fast-follow notification types:**
  - Re-engagement: "Your group hasn't played in 6 days. Time for a rematch?" (with group-specific context like "Danny still holds the Blue Shell record")
  - Social proof: "Maya shared your last game's report card — 3 new people saw it"
  - New feature announcements: "Saboteur Mode just dropped. Who's the traitor?"
- **Permission strategy:** Request notification permission after first completed game (not on install) — the user has context for why they'd want notifications after experiencing the product

### Store Compliance

- **App Store positioning:** "Party game" category — never "drinking game," "bar game," or any alcohol-adjacent framing
- **Content guidelines:**
  - No alcohol imagery in screenshots, icons, or marketing materials
  - Punishments framed as "challenges" — no references to drinking as a punishment mechanic
  - Pre-built punishment deck reviewed against Apple App Store Review Guidelines 1.1.4 and Google Play Developer Policy
- **Custom punishment moderation:** **No automated content filtering for MVP.** Custom punishments are submitted within private friend groups — the social context self-moderates. Players are writing punishments for people they're standing next to. Over-engineering moderation for a private, friends-only experience adds complexity without value. Add a simple **report/flag mechanism** so players can flag inappropriate content if needed. Defer automated moderation (keyword blocklist, AI moderation API) to when/if RackUp introduces public rooms or user-generated content shared beyond the immediate group.
- **Age rating:** Target 12+ (Apple) / Teen (Google Play). Spicy punishments (read your texts, group sends a text from your phone) may push to 17+ / Mature — evaluate during submission. No sexual content, no gambling mechanics, no real-money transactions tied to game outcomes.
- **Privacy:**
  - Minimal data collection — player names (user-chosen, not real names), game scores, group composition hashes for analytics
  - No contact list access, no social media login required
  - GDPR/CCPA compliant data handling for analytics
  - Privacy policy required before store submission

### Implementation Considerations

- **Real-time communication:** WebSocket connection for live game state sync. Fallback to polling if WebSocket connection drops.
- **Animation performance:** Leaderboard shuffle, streak fire indicators, and post-game ceremony animations must run at 60fps on mid-range devices. Flutter's Skia rendering engine handles this well, but test on lower-end Android devices (Samsung A-series, Xiaomi Redmi — common in target demographic).
- **Share image generation:** Report card rendered as a styled image client-side (Flutter's `RepaintBoundary` or similar) in both 9:16 (Instagram Stories) and 1:1 (general sharing) formats. Must include dynamic data (player names, scores, awards) rendered into a visually polished template.
- **Deep linking:** Room join codes support both manual entry and deep links (rackup.app/join/ABCD) for frictionless sharing via text/social media. Deep links direct to App Store if app not installed, then open directly into the room on launch.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach: Experience MVP** — deliver the full emotional arc of one game mode (Party Mode on pool) with enough depth that groups finish, share, and come back. Cut breadth (one mode, one sport), preserve depth (full item system, full punishment escalation, full post-game ceremony). The experience must feel complete, not like a demo.

**Resource Reality: Solo Developer**

This is a solo build. That's a constraint, not a limitation — but it demands ruthless prioritization. Every feature must earn its place. The scoping below is calibrated for one developer shipping an MVP that validates the core loop before investing in scale.

**Solo dev implications:**
- **Lean on managed services** — Firebase/Supabase over custom WebSocket servers. The architecture phase should bias heavily toward managed real-time infrastructure to minimize ops burden.
- **No custom backend unless necessary** — if a managed service handles rooms, state sync, and analytics, use it. Building a custom real-time game server solo is a multi-month detour.
- **Ship the riskiest thing first** — real-time multiplayer with reconnection is the technical risk. Spike it before building the UI. If the state sync doesn't work reliably in a bar, nothing else matters.
- **Iterative build with early playtesting** — use the walking skeleton approach (see Recommended Build Order below) to get real-world feedback from friend groups within weeks, not months.

### Authentication Model

**MVP: Anonymous-first, zero friction.** Players enter a display name when joining a room. No account creation, no sign-in, no email. Friction is zero — Jake says "join this room," friends type a name and a code, they're in.

**Device ID for analytics:** Behind the scenes, the app generates a persistent device identifier (not tied to any account) to power group identity fingerprinting and analytics. This enables 7-Day Group Return tracking without requiring sign-in.

**Phase 1.5: Optional lightweight sign-in.** Add one-tap Apple Sign In / Google Sign In to enable:
- Push notification delivery (requires device token linked to an identity)
- Persistent player identity across devices
- Lifetime player stats ("Danny's career Blue Shell count")
- Smoother group identity recognition (account-based, not name-heuristic-based)

Sign-in is never required — anonymous play always works. Sign-in is offered after the first completed game as a "save your stats" prompt, alongside the push notification permission request.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- Jake — First Night (room creation, game flow, report card) ✅
- Danny — Underdog (items, rubber banding, chaos) ✅
- Lena — Reluctant Convert (referee experience) ✅
- Maya — Viral Loop (sharing, report card) ✅
- Referee Experience (state machine, rotation, undo) ✅
- The Crash Landing (disconnection recovery) ✅
- Jake — The Return (analytics instrumented, UX deferred) ⚠️ Partial

**Must-Have Capabilities (MVP):**

| Capability | Rationale |
|-----------|-----------|
| Room creation + join-by-code | Without this, the product doesn't exist |
| Turn management + referee confirmation | Core game loop |
| Referee screen (command center UX) | The energy engine — if this is boring, the game dies |
| Scoring with streaks + triple-points finale | Emotional arc — warm-up to peak |
| Full 10-item deck with use-it-or-lose-it | Items ARE the game — Blue Shell moments drive sharing |
| Rubber banding (last place gets better items) | Skill-equalizing design — the core differentiator |
| Full 15-mission deck with private display | Secret missions add depth without complexity |
| Punishment deck with percentage-based escalation | Escalation arc — mild to spicy regardless of game length |
| Custom punishment submission | Player investment before game starts |
| Leaderboard with position-shuffle animations | Dramatic reveals keep everyone watching |
| Post-game report card with awards | The viral mechanism — share button is the growth engine |
| Share image generation (9:16 + 1:1) | If nobody shares, the product doesn't spread |
| Mid-game joining with catch-up scoring | Bar reality — people arrive late |
| Referee rotation + handoff | Everyone gets a turn, nobody is stuck managing |
| 5-second undo for shot results | Bar-proof — fat fingers happen |
| Disconnection recovery (60s) | Bar-proof — bad signal is guaranteed |
| Referee failover on disconnect | Game never stops |
| Screen wake lock | 30-60 min sessions, screen can't lock |
| Deep linking for room codes | Frictionless invite sharing |
| 5 essential sound effects | Party atmosphere — sounds make moments feel real (see below) |
| Analytics: game completion, group identity, share taps | Instrument KPIs from day one |
| Anonymous auth with device ID | Zero-friction identity + analytics foundation |

**MVP Sound Effects (5 essential sounds):**

Sound effects are part of the experience, not polish. A silent Blue Shell is a notification; a Blue Shell with a dramatic impact chime is a *moment*. The difference is what makes people at the next table ask "what are you guys playing?"

| Sound | Trigger | Why Essential |
|-------|---------|---------------|
| Blue Shell impact | Blue Shell deployed against a player | The signature chaos moment — needs audio punctuation |
| Leaderboard shuffle | Positions change after any shot | The dramatic reveal that everyone watches |
| Punishment reveal | Punishment text appears on referee screen | Builds anticipation before the referee reads it aloud |
| Streak fire | Player hits 3+ consecutive ("ON FIRE!") | Audio reward that the whole group hears |
| Podium fanfare | Post-game ceremony, each podium position revealed | The climax of the game — needs a moment of ceremony |

Implementation: 5 royalty-free `.mp3` files from game asset packs. Flutter `audioplayers` package. Preload on game start. Respect device silent mode. Half a day of implementation. Don't commission custom audio for MVP.

**Explicitly Deferred from MVP:**

| Capability | Why Deferred | Phase |
|-----------|-------------|-------|
| Push notifications | Requires notification infrastructure + permission flow. Analytics must come first to provide context. | Phase 1.5 (fast-follow) |
| Haptic feedback | Subtle enhancement, not atmosphere creation. Sounds carry the party vibe; haptics are invisible to bystanders. | Phase 1.5 (fast-follow) |
| Optional sign-in (Apple/Google) | Zero friction is more important than persistent identity for MVP. Device ID covers analytics needs. | Phase 1.5 (fast-follow) |
| Full audio design (beyond 5 essentials) | 5 sounds cover the key moments. Expand the sound palette after validating the core loop. | Phase 1.5 (fast-follow) |
| Group Stats on report card | Requires group identity recognition UX beyond raw analytics. Instrument the data, defer the display. | Phase 2 |
| First-time player tutorial | Marcus figured it out in one round in the journey. In-context learning is sufficient for MVP. Formalize if onboarding data shows confusion. | Phase 2 |
| Re-engagement notifications | Depends on push notifications + sign-in being built first. | Phase 2 |

### Recommended Build Order (Walking Skeleton → Full MVP)

The MVP scope above is what ships to the App Store. But for a solo developer, building all 17+ systems before testing with real people is a mistake. Use this iterative build order to get real-world feedback early and often:

**Stage 1 — Walking Skeleton (first playable, weeks 1-3):**
- Room creation + join-by-code
- Turn management + referee shot confirmation (MADE/MISSED)
- Basic scoring (points for makes, no streaks yet)
- Punishments only (pre-built deck, no custom, no escalation tiers yet)
- Simple leaderboard (ranked list, no animations)
- Game end with basic winner announcement
- **→ Deploy to TestFlight/Google Play Internal Testing. Playtest with 1-2 friend groups at a real bar.**

**Stage 2 — The Chaos Layer (weeks 4-6):**
- Add items (full 10-item deck, use-it-or-lose-it, rubber banding)
- Add secret missions (full 15-mission deck, private display)
- Add custom punishment submission
- Add streak tracking + triple-points finale
- Add percentage-based punishment escalation
- **→ Playtest again. Does the chaos work? Are items being used? Do missions add depth?**

**Stage 3 — The Experience Layer (weeks 7-9):**
- Leaderboard position-shuffle animations
- Post-game report card with awards
- Share image generation (9:16 + 1:1)
- 5 essential sound effects
- Referee rotation + handoff UX
- 5-second undo
- **→ Playtest. Is the report card shareable? Does the referee rotation feel smooth?**

**Stage 4 — Bar-Proofing (weeks 10-11):**
- Disconnection detection + auto turn-skip
- Reconnection with state sync
- Referee failover on disconnect
- Mid-game joining with catch-up scoring
- Screen wake lock
- Deep linking for room codes
- Analytics instrumentation
- Anonymous auth with device ID
- **→ Final bar-environment stress test. Test in a basement bar with terrible signal.**

**Stage 5 — App Store Submission (week 12):**
- Store listing, screenshots, privacy policy
- Final QA pass across iOS + Android
- Submit to App Store + Google Play

**Beta Testing Strategy:** TestFlight (iOS) and Google Play Internal Testing (Android) from Stage 1 onward. Recruit 2-3 friend groups as ongoing beta testers. Every stage gets a real-world playtest in an actual bar before moving to the next. The walking skeleton playtest is the most important — it validates the core loop (real pool + app overlay) before investing in the chaos layer. If the basic concept doesn't work with just scoring and punishments, more features won't fix it.

### Post-MVP Features

**Phase 1.5 — Polish & Fast-Follow (weeks after launch):**
- Push notification infrastructure + permission flow
- Optional Apple/Google sign-in ("save your stats")
- Haptic feedback on key moments
- Expanded sound design (beyond 5 essentials)
- First-time player tutorial (if onboarding data warrants it)

**Phase 2 — Game Modes & Retention:**
1. Saboteur Mode (highest viral potential — hidden roles drove Among Us to 650M downloads)
2. Quick Round (simplest to build, captures "one more game at last call")
3. Total Chaos Mode
4. Team Mode
5. Loser's League
- Player XP and levels
- Group progression and milestones
- Group Stats on report card
- Re-engagement notifications with group context
- Web join (Jackbox model) — if download friction is killing adoption

**Phase 3 — Platform Expansion:**
- Darts (Year 1 stretch goal — Flight Club validated £80.4M market)
- Beer pong, cornhole, foosball
- AI trash talk commentator / roast engine
- Video compilation / highlight reel
- Seasonal content and leaderboards
- B2B bar partnership program
- Tournament bracket system
- Corporate team building packages

### Risk Mitigation Strategy

**Technical Risks:**

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| Real-time state sync unreliable in bars | Critical — product unusable | Medium | Spike WebSocket reliability in poor-connectivity environments FIRST, before any UI work. Test in actual basement bars. Use managed real-time service to offload infrastructure complexity. |
| Flutter animation performance on low-end Android | High — leaderboard shuffle stutters kill the drama | Medium | Test on Samsung A-series and Xiaomi Redmi early. Simplify animations if needed — smooth > fancy. |
| Solo dev bottleneck on cross-cutting concerns | Medium — auth, analytics, error handling slow everything down | High | Use managed services aggressively (Firebase Auth, Analytics, Crashlytics or equivalents). Don't build what you can buy. |
| Room code collisions at scale | Low — but embarrassing | Low | 4-character alphanumeric = 1.6M combinations. More than sufficient for MVP. Add 5th character if rooms-per-day approaches 10K+. |

**Market Risks:**

| Risk | Impact | Mitigation |
|------|--------|------------|
| Download friction kills group adoption | Critical — rooms created but guests don't join | Track "rooms created vs. rooms with 3+ players" from day one. If conversion is <50%, fast-track web join (Phase 2). |
| First-night experience doesn't drive return | Critical — novelty without retention | 7-Day Group Return is the north star metric. If groups don't return, diagnose before adding features. The core loop must work before adding modes. |
| App Store rejects for alcohol-adjacent content | High — blocks launch entirely | Pre-review all punishment text against guidelines. Position as "party game." Zero alcohol imagery. Submit early to catch issues before marketing push. |
| Copycat apps after initial traction | Medium — but blue ocean won't last forever | Build network effects: group progression, legacy stats, community. First-mover advantage + group switching costs = defensible position. |

**Resource Risks (Solo Developer):**

| Risk | Impact | Mitigation |
|------|--------|------------|
| Burnout from building everything solo | Critical — project dies | Timebox MVP to ~12 weeks using the walking skeleton approach. Ship iteratively, celebrate progress at each stage. |
| No QA beyond self-testing | Medium — bugs in production | TestFlight/Internal Testing from Stage 1. 2-3 friend groups as ongoing beta testers. Playtest in real bars at every stage. Automated testing for state sync logic. |
| No design resources | Medium — UX suffers | Referee screen is the #1 design priority. If one screen gets professional design attention, it's the referee command center. Everything else can be functional-first. |
| Server costs surprise | Low — but cash matters for solo | Managed services (Firebase free tier) scale to thousands of concurrent rooms before paid tiers kick in. Monitor usage from day one. |

## Functional Requirements

### Room & Multiplayer

- **FR1:** Host can create a new game room and receive a unique shareable join code
- **FR2:** Players can join an existing room by entering the join code manually
- **FR3:** Players can join an existing room via a deep link (rackup.app/join/CODE); if the app is not installed, the deep link redirects to the appropriate App Store for download, then opens directly into the room on launch
- **FR4:** Players can enter a display name when joining a room (no account required)
- **FR5:** Host can configure game length (number of rounds: 5, 10, or 15) before starting
- **FR6:** Players can join a room mid-game and receive a catch-up starting score equal to the current lowest player's score plus a consolation item
- **FR7:** Rooms support 2-8 concurrent players
- **FR8:** All players must submit one custom punishment before the game starts; the host can start the game once all players have submitted or the configurable timeout has elapsed, whichever comes first
- **FR9:** Host can start the game once all players have joined and the punishment submission phase is complete (all submitted or timeout elapsed)
- **FR10:** All players can view a pre-game lobby showing connected players, each player's punishment submission status, and a waiting indicator until the host starts the game
- **FR11:** The system terminates a room when the game ends; post-game report card data remains accessible to all players until they leave the results screen; room state is archived for analytics after all players exit

### Game Flow & Turn Management

- **FR12:** The system manages turn order across all players in the room
- **FR13:** The referee can confirm each shot result as "made" or "missed"
- **FR14:** The referee can undo a shot result within 5 seconds of confirmation
- **FR15:** The system triggers the appropriate consequence chain based on shot result (made: points + streak; missed: streak reset + item drop chance + punishment)
- **FR16:** The system activates triple-point scoring for the final 3 rounds and notifies all players
- **FR17:** The system ends the game after the configured number of rounds and transitions to the post-game ceremony

### Referee System

- **FR18:** The system assigns a referee role to one player at the start of the game
- **FR19:** The referee receives a dedicated command center screen showing current shooter, mission delivery, shot confirmation, and consequence announcements
- **FR20:** The referee can deliver secret missions to the current shooter (whisper prompt with confirmation)
- **FR21:** The referee can announce punishments, item drops, and streak milestones from their screen
- **FR22:** The system prompts referee rotation after each full round through all players
- **FR23:** The current referee can hand off the role to the next player in rotation
- **FR24:** The system skips the next referee in rotation if they are also the current shooter
- **FR25:** The system detects when the referee disconnects and prompts the next player to take over

### Scoring & Streaks

- **FR26:** The system awards base points (+3) for each made shot
- **FR27:** The system tracks consecutive made shots (streaks) per player and awards escalating streak bonuses (+1 for 2, +2 for 3, +3 for 4+)
- **FR28:** The system resets a player's streak to zero on a miss
- **FR29:** The system displays streak status indicators to all players (warming up, ON FIRE, UNSTOPPABLE)
- **FR30:** The system awards mission bonus points when a shooter completes their assigned secret mission
- **FR31:** The system triples all point values during the final 3 rounds

### Items & Power-Ups

- **FR32:** The system awards an item to a player on a missed shot with a default probability of 50%
- **FR33:** The system applies rubber banding — last place draws from the full item deck; first place is excluded from Blue Shell draws
- **FR34:** Each player can hold one item at a time (use-it-or-lose-it — current item is replaced if a new one is received)
- **FR35:** Players can deploy their held item on their turn, targeting another player when applicable
- **FR36:** The system resolves item effects for all 10 items (each item is a distinct sub-requirement that must be independently implemented and tested):
  - **FR36a:** Blue Shell — target first place player; they lose 3 points and must shoot off-handed next turn
  - **FR36b:** Shield — block the next punishment or item used against you
  - **FR36c:** Score Steal — take 5 points from a targeted player
  - **FR36d:** Streak Breaker — reset a targeted player's streak to zero
  - **FR36e:** Double Up — next made shot is worth double points
  - **FR36f:** Trap Card — the next player to miss receives your punishment instead
  - **FR36g:** Reverse — swap your score with a targeted player
  - **FR36h:** Immunity — skip your next punishment
  - **FR36i:** Mulligan — redo your last shot (group votes to allow via in-app poll)
  - **FR36j:** Wildcard — player enters a custom rule that the system displays to all players for 3 turns

### Secret Missions

- **FR37:** The system randomly assigns a secret mission to the current shooter with a default probability of 33% per turn
- **FR38:** Only the shooter and the referee can see the assigned mission
- **FR39:** The system validates mission completion based on the referee's confirmation
- **FR40:** The system supports the full 15-mission deck with varying difficulty and bonus point values (+2 to +8)

### Punishments

- **FR41:** The system draws a punishment from the appropriate tier when a player misses a shot
- **FR42:** The system escalates punishment tiers based on game progression percentage (first 30% mild, 30-70% medium, final 30% spicy)
- **FR43:** Custom punishments submitted by players are shuffled into all tiers throughout the game
- **FR44:** The referee screen displays the drawn punishment with its tier tag for announcement

### Leaderboard & Display

- **FR45:** All players can view the current leaderboard showing player names, scores, and rankings
- **FR46:** The leaderboard displays position-shuffle animations when rankings change after a shot
- **FR47:** The system displays streak fire indicators next to players on active streaks
- **FR48:** The system plays sound effects on key events (Blue Shell impact, leaderboard shuffle, punishment reveal, streak fire, podium fanfare)
- **FR49:** The system keeps the device screen awake during an active game session

### Post-Game & Sharing

- **FR50:** The system generates a post-game report card displaying awards: MVP (highest score), Sharpshooter (best accuracy), Punching Bag (most punishments), Participant Trophy (lowest score), Hot Hand (longest streak), Mission Master (most missions completed)
- **FR51:** The referee controls the post-game podium ceremony with sequential dramatic reveal (3rd → 2nd → 1st place)
- **FR52:** Players can generate a styled shareable image of the report card in 9:16 (Instagram Stories) and 1:1 (general sharing) formats
- **FR53:** Players can share the report card image via the device's native share sheet
- **FR54:** The system displays "RECORD THIS" prompts on all players' screens when shareable moments occur (spicy punishments, Blue Shell deployments, streak breaks)
- **FR55:** The report card includes Best Moments timestamps ("Blue Shell at 9:47 PM") so players can find their own recordings
- **FR56:** The system presents a post-game micro-feedback prompt asking each player to rate the referee experience (thumbs up / thumbs down) for Referee Satisfaction measurement

### Connectivity & Resilience

- **FR57:** The system detects when a player disconnects and displays a visual indicator on other players' screens
- **FR58:** The system automatically skips disconnected players' turns and continues the game
- **FR59:** The system preserves a disconnected player's score, items, and stats server-side
- **FR60:** The system silently reconnects a returning player and syncs their state within 60 seconds of disconnection
- **FR61:** The system notifies a reconnected player of any missed turns

### Analytics & Identity

- **FR62:** The system generates a persistent device identifier for anonymous player tracking
- **FR63:** The system tracks game completion events (started, finished, abandoned)
- **FR64:** The system tracks share button taps on post-game report cards
- **FR65:** The system fingerprints group identity by matching player composition across sessions (for 7-Day Group Return measurement)
- **FR66:** The system tracks item deployment events (which items are used, how often)
- **FR67:** The system tracks sequential room creation by the same host within a single session to measure Second Game Rate
- **FR68:** The system tracks referee satisfaction feedback (thumbs up/down) from post-game micro-surveys

## Non-Functional Requirements

### Performance

- **NFR1:** Room creation completes and returns a join code within 2 seconds of the host tapping "Create Room"
- **NFR2:** Player join (code entry to visible in lobby) completes within 3 seconds
- **NFR3:** Shot result confirmation (referee tap to leaderboard update on all devices) propagates within 2 seconds
- **NFR4:** Leaderboard position-shuffle animations render at 60fps on mid-range devices (Samsung A-series, Xiaomi Redmi)
- **NFR5:** Post-game report card and share image generate within 3 seconds of game end
- **NFR6:** Sound effects trigger within 200ms of their associated event (perceptible delay kills the party atmosphere)
- **NFR7:** App cold start to home screen loads within 3 seconds
- **NFR8:** Deep link open (app already installed) to room lobby loads within 4 seconds

### Security & Privacy

- **NFR9:** All client-server communication encrypted via TLS 1.2+
- **NFR10:** Device identifiers are hashed before storage — raw device IDs never stored on the server
- **NFR11:** Player display names are not linked to real identities — no email, phone, or social login data collected in MVP
- **NFR12:** Game session data (scores, items, punishments) retained for analytics for 90 days, then anonymized or purged
- **NFR13:** Custom punishment text is visible only to players within the same room — never exposed to other rooms or public APIs
- **NFR14:** Privacy policy published and accessible within the app before store submission
- **NFR15:** GDPR: users can request deletion of their device identifier and associated analytics data. CCPA: same, with opt-out of data sale (though no data is sold)

### Scalability

- **NFR16:** The system supports at least 100 concurrent active rooms without performance degradation (MVP launch target)
- **NFR17:** The system scales to 1,000+ concurrent rooms without architecture changes (growth target — managed service selection should accommodate this)
- **NFR18:** Room code generation remains collision-free up to 10,000 active rooms per day (4-character alphanumeric = 1.6M combinations)
- **NFR19:** Analytics event ingestion handles burst writes (all players in a room generating events simultaneously at game end) without data loss

### Reliability

- **NFR20:** Game state is persisted to a managed cloud service with provider-guaranteed uptime SLA (e.g., Firebase 99.95%, Supabase 99.9%) — not stored solely in application memory or on a single self-managed server
- **NFR21:** The app recovers gracefully from backgrounding (user switches to camera app to record a moment, then returns) without losing game state or room connection
- **NFR22:** Crash-free session rate >99% across both iOS and Android
- **NFR23:** Failed room creation or join attempts display clear, actionable error messages (not generic errors)
- **NFR24:** The system degrades gracefully under load — if capacity is exceeded, new room creation is rejected with a clear message rather than degrading active games
- **NFR25:** A full game session (60 minutes) should consume no more than 15% battery on a typical modern smartphone — no unnecessary background processing, efficient WebSocket keep-alive intervals, no continuous polling
