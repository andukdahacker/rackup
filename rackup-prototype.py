#!/usr/bin/env python3
"""
RackUp Prototype - Test every game mode with your friends!

Run: python3 rackup-prototype.py

Play real pool. This app runs on one phone/laptop as the host.
It handles turns, missions, items, punishments, and scoring.
"""

import random
import time
import sys
import os

# ─── CONFIG ──────────────────────────────────────────────────────────────────

ITEMS = {
    "Blue Shell":       "Target 1st place! They must shoot with their off-hand next turn.",
    "Shield":           "Block the next punishment or item used against you.",
    "Score Steal":      "Steal 5 points from any player of your choice.",
    "Streak Breaker":   "Reset another player's streak to zero.",
    "Double Up":        "Your next made shot is worth double points.",
    "Trap Card":        "Place a hidden trap - next player to miss does YOUR punishment.",
    "Reverse":          "Swap scores with any other player.",
    "Immunity":         "Skip your next punishment. Play anytime.",
    "Mulligan":         "Redo your last shot (group must allow it).",
    "Wildcard":         "Invent any rule that lasts for 3 turns.",
}

SECRET_MISSIONS = [
    ("Bank Shot Artist", "Make a bank shot", 5),
    ("Combo King", "Sink 2 balls in one turn", 8),
    ("Called It", "Call your pocket before shooting (tell the group)", 3),
    ("Lefty/Righty", "Shoot with your non-dominant hand and make it", 7),
    ("Speed Demon", "Shoot within 5 seconds of stepping up", 4),
    ("Behind the Back", "Attempt a behind-the-back shot", 6),
    ("No Look", "Don't watch the ball after you hit it (look away)", 5),
    ("Jump Shot", "Attempt a jump shot (even if you miss)", 3),
    ("Trash Talker", "Convincingly trash talk before your shot", 2),
    ("The Whisper", "Whisper your shot call so quietly only the ref hears", 3),
    ("One-Handed", "Shoot without using a bridge hand", 5),
    ("Eyes Closed", "Close your eyes before contact", 6),
    ("Storyteller", "Tell a 10-second story while shooting", 4),
    ("The Distractor", "Try to make someone laugh during YOUR shot", 3),
    ("Long Range", "Shoot from the far end of the table", 5),
]

PUNISHMENTS_MILD = [
    "Take a sip of your drink",
    "Compliment the person to your left",
    "Do your best impression of someone in the group",
    "Text the 5th person in your recent messages 'I miss you'",
    "Speak in an accent for the next 2 turns",
    "Let the group pick a song you have to dance to for 10 seconds",
    "Give your phone to someone else for 1 turn - they can post ONE story",
    "Say something nice about every player",
]

PUNISHMENTS_MEDIUM = [
    "Shoot your next turn with your eyes closed",
    "Let the group choose your next drink order",
    "Call someone and sing happy birthday to them",
    "Do 10 pushups right now",
    "Switch to shooting with your off-hand for 2 turns",
    "Let someone draw something on your arm with a pen",
    "Speak only in questions for the next 3 turns",
    "Swap shirts with someone for the rest of the game",
    "Hold the cue like a guitar and play a solo before your next shot",
    "You can only shoot left-handed for the rest of the round",
]

PUNISHMENTS_SPICY = [
    "Read your last 3 sent texts out loud to the group",
    "Let the group compose and send ONE text from your phone",
    "Post a selfie right now with a caption the group writes",
    "Call your most recent ex and ask how their day was (speaker phone)",
    "Do a dramatic karaoke performance of the group's choice (one verse)",
    "Let the group go through your camera roll for 15 seconds",
    "Venmo the winner $1 right now (or equivalent bet)",
    "Let the worst player give you a new hairstyle for the rest of the night",
]

CHAOS_COMMANDS = [
    "SPEED ROUND: Everyone has 5 seconds per shot. Go go go!",
    "MIRROR MATCH: Everyone must shoot opposite-handed this round.",
    "SILENT ROUND: No talking. Communicate only with gestures.",
    "BLINDFOLD: The shooter must close their eyes. Another player aims for them.",
    "TEAM SWAP: If in teams, swap one player between teams.",
    "DOUBLE OR NOTHING: This shot is worth double, but a miss costs you 5 points.",
    "CROWD CONTROL: Non-shooters vote on which pocket you MUST aim for.",
    "MUSICAL CHAIRS: Everyone rotates positions - you inherit the next player's score for this turn!",
    "BOUNTY: First person to sink a ball gets 10 bonus points.",
    "THE FLOOR IS LAVA: You must shoot without both feet on the ground (lean, hop, one foot).",
    "COMMENTARY: The player to your right must narrate your shot like a sports announcer.",
    "SLOW MOTION: You must shoot and react in slow motion. Group judges authenticity.",
    "PHONE ROULETTE: Everyone puts phones in the center. Random phone rings = that person drinks.",
    "TRICK SHOT CHALLENGE: You MUST attempt a trick shot. Group votes if it counts.",
    "ALLIANCE ROUND: Secretly write down a partner. If you both make your shots, double points.",
    "CONFESSION: Before your shot, confess something. Group votes if it's juicy enough for points.",
    "REMIX: The app randomly swaps two players' scores!",
    "RULE BREAK: The shooter gets to invent ONE rule that lasts for 2 turns.",
]

SABOTEUR_BEHAVIORS = [
    "Subtly miss this shot (make it look natural!)",
    "Play normally this turn to avoid suspicion",
    "Try to convince everyone that someone else is the saboteur",
    "Miss, but make it look like you were attempting something ambitious",
    "Scratch 'accidentally'",
    "Play normally - sometimes the best sabotage is patience",
    "If you have an item, use it to help someone in last place (deflect suspicion)",
    "Take a risky shot - if you miss, it looks brave, not suspicious",
]

LOSER_LEAGUE_EXCUSES = [
    "I was going for the bank shot...",
    "The table is uneven!",
    "Someone bumped me",
    "I'm just warming up",
    "That was my practice stroke!",
    "This cue is warped",
    "The chalk was bad",
    "I sneezed internally",
]

# ─── SOUND EFFECTS (text-based) ─────────────────────────────────────────────

def sfx(effect):
    sounds = {
        "fanfare": "\n  ** DAAAA DA DA DAAAAAAA! ** \n",
        "fail":    "\n  ~~ womp womp ~~ \n",
        "fire":    "\n  THIS PLAYER IS ON FIRE! \n",
        "boom":    "\n  ** BOOM! ** \n",
        "suspense":"\n  ... ... ... \n",
        "siren":   "\n  !! WEE WOO WEE WOO !! \n",
        "drum":    "\n  *drumroll* ... \n",
    }
    print(sounds.get(effect, ""))

# ─── DISPLAY HELPERS ─────────────────────────────────────────────────────────

def clear():
    os.system("cls" if os.name == "nt" else "clear")

def banner(text):
    width = max(len(text) + 6, 40)
    print("\n" + "=" * width)
    print(f"   {text}")
    print("=" * width)

def pause(msg="Press Enter to continue..."):
    input(f"\n  {msg}")

def dramatic_reveal(label, value, delay=0.05):
    print(f"\n  {label}: ", end="", flush=True)
    for ch in str(value):
        print(ch, end="", flush=True)
        time.sleep(delay)
    print()

# ─── PLAYER & GAME STATE ────────────────────────────────────────────────────

class Player:
    def __init__(self, name):
        self.name = name
        self.score = 0
        self.streak = 0
        self.items = []
        self.missions_completed = 0
        self.shots_made = 0
        self.shots_taken = 0
        self.punishments_received = 0
        self.is_saboteur = False
        self.immunity = False
        self.team = None
        self.suspicion_votes = 0

class Game:
    def __init__(self):
        self.players = []
        self.mode = None
        self.round_num = 0
        self.max_rounds = 0
        self.spice_level = 0  # 0=mild, 1=medium, 2=spicy
        self.custom_punishments = []
        self.saboteur = None
        self.teams = {"A": [], "B": []}
        self.emergency_meetings_left = 1

# ─── SETUP ───────────────────────────────────────────────────────────────────

def setup_players():
    clear()
    banner("RACKUP - Player Setup")
    print("\n  How many players?")
    while True:
        try:
            n = int(input("  > "))
            if 2 <= n <= 12:
                break
            print("  Need 2-12 players!")
        except ValueError:
            print("  Enter a number!")

    players = []
    for i in range(n):
        name = input(f"  Player {i+1} name: ").strip()
        if not name:
            name = f"Player{i+1}"
        players.append(Player(name))
    return players

def setup_custom_punishments(game):
    clear()
    banner("Custom Punishment Pool")
    print("\n  Each player secretly submits a punishment.")
    print("  These get mixed into the deck throughout the night.")
    print("  (Pass the phone/laptop between players)\n")

    for p in game.players:
        punishment = input(f"  {p.name}'s punishment (or Enter to skip): ").strip()
        if punishment:
            game.custom_punishments.append(f"[{p.name}'s pick] {punishment}")
        # Clear the screen so next player doesn't see
        clear()
        banner("Custom Punishment Pool")
        print()

    if game.custom_punishments:
        print(f"  {len(game.custom_punishments)} custom punishments added to the deck!")
    else:
        print("  No custom punishments - using default deck!")
    pause()

def choose_mode():
    clear()
    banner("RACKUP - Choose Your Mode")
    modes = [
        ("Party Mode", "Real pool + chaos layer. The classic RackUp experience."),
        ("Total Chaos", "The app controls EVERYTHING. Pool is just a prop."),
        ("Saboteur", "One player secretly tries to lose. Can you find them?"),
        ("Loser's League", "Everyone tries to MISS. Vote on who's faking."),
        ("Team Mode", "Teams compete with shared scores and items."),
        ("Quick Round", "5-round blitz. Fast, brutal, done."),
    ]
    for i, (name, desc) in enumerate(modes, 1):
        print(f"\n  [{i}] {name}")
        print(f"      {desc}")

    while True:
        try:
            choice = int(input("\n  Pick a mode > "))
            if 1 <= choice <= len(modes):
                return modes[choice-1][0]
        except ValueError:
            pass
        print("  Invalid choice!")

def choose_rounds():
    print("\n  How many rounds? (5=quick, 10=standard, 15=marathon)")
    while True:
        try:
            r = int(input("  > "))
            if 1 <= r <= 30:
                return r
        except ValueError:
            pass
        print("  Enter 1-30!")

# ─── ITEM SYSTEM ─────────────────────────────────────────────────────────────

def give_item(player, game):
    """Give items with rubber banding - worse players get better items."""
    scores = sorted(game.players, key=lambda p: p.score)
    rank = scores.index(player)
    # Last place gets best odds for good items
    good_items = ["Blue Shell", "Score Steal", "Reverse", "Double Up"]
    ok_items = ["Shield", "Streak Breaker", "Trap Card", "Mulligan"]
    meh_items = ["Immunity", "Wildcard"]

    if rank <= len(game.players) // 3:  # Bottom third
        pool = good_items * 3 + ok_items + meh_items
    elif rank >= len(game.players) * 2 // 3:  # Top third
        pool = good_items + ok_items + meh_items * 3
    else:
        pool = good_items + ok_items * 2 + meh_items

    item = random.choice(pool)
    if len(player.items) < 2:
        player.items.append(item)
        print(f"\n  >> {player.name} received: {item}!")
        print(f"     {ITEMS[item]}")
    else:
        print(f"\n  >> {player.name}'s inventory is full! (max 2 items)")
        print(f"     Current items: {', '.join(player.items)}")
        use = input("     Discard one? (1/2/no): ").strip()
        if use in ("1", "2"):
            idx = int(use) - 1
            old = player.items[idx]
            player.items[idx] = item
            print(f"     Discarded {old}, got {item}!")

def use_item(player, game):
    if not player.items:
        return
    print(f"\n  {player.name}'s items: {', '.join(f'[{i+1}] {it}' for i, it in enumerate(player.items))}")
    choice = input("  Use an item? (1/2/no): ").strip()
    if choice in ("1", "2"):
        idx = int(choice) - 1
        if idx < len(player.items):
            item = player.items.pop(idx)
            apply_item(player, item, game)

def apply_item(player, item, game):
    sfx("boom")
    print(f"\n  {player.name} uses: {item}!")
    print(f"  Effect: {ITEMS[item]}")

    if item == "Blue Shell":
        leader = max(game.players, key=lambda p: p.score)
        if leader != player:
            print(f"  >> {leader.name} is TARGETED! They must shoot off-handed next turn!")
            leader.score = max(0, leader.score - 3)
            print(f"  >> {leader.name} also loses 3 points! ({leader.score} pts)")
        else:
            print(f"  >> You're in first... it hits YOU! -3 points!")
            player.score = max(0, player.score - 3)

    elif item == "Score Steal":
        print("  Steal from whom?")
        for i, p in enumerate(game.players):
            if p != player:
                print(f"    [{i+1}] {p.name} ({p.score} pts)")
        try:
            target_idx = int(input("  > ")) - 1
            target = game.players[target_idx]
            stolen = min(5, target.score)
            target.score -= stolen
            player.score += stolen
            print(f"  >> Stole {stolen} points from {target.name}!")
        except (ValueError, IndexError):
            print("  >> Invalid target, item wasted!")

    elif item == "Reverse":
        print("  Swap scores with whom?")
        for i, p in enumerate(game.players):
            if p != player:
                print(f"    [{i+1}] {p.name} ({p.score} pts)")
        try:
            target_idx = int(input("  > ")) - 1
            target = game.players[target_idx]
            player.score, target.score = target.score, player.score
            print(f"  >> Swapped! {player.name}: {player.score} pts, {target.name}: {target.score} pts")
        except (ValueError, IndexError):
            print("  >> Invalid target, item wasted!")

    elif item == "Double Up":
        print("  >> Your next made shot is worth DOUBLE!")
        # Handled in shot resolution

    elif item == "Shield":
        player.immunity = True
        print("  >> Shield active! Next punishment or item is blocked.")

    elif item == "Immunity":
        player.immunity = True
        print("  >> Immunity active! Skip your next punishment.")

    elif item == "Streak Breaker":
        print("  Break whose streak?")
        for i, p in enumerate(game.players):
            if p != player and p.streak > 0:
                print(f"    [{i+1}] {p.name} (streak: {p.streak})")
        try:
            target_idx = int(input("  > ")) - 1
            target = game.players[target_idx]
            target.streak = 0
            print(f"  >> {target.name}'s streak destroyed!")
        except (ValueError, IndexError):
            print("  >> No valid target!")

    else:
        print("  >> Effect applied! Enforce it yourselves, legends.")

# ─── PUNISHMENT SYSTEM ───────────────────────────────────────────────────────

def get_punishment(game):
    """Get a punishment based on current spice level with custom pool mixed in."""
    pools = [PUNISHMENTS_MILD, PUNISHMENTS_MEDIUM, PUNISHMENTS_SPICY]

    # Mix in custom punishments at any level
    pool = list(pools[min(game.spice_level, 2)])
    if game.custom_punishments:
        pool.extend(game.custom_punishments)

    return random.choice(pool)

def escalate_spice(game):
    """Auto-escalate through the game."""
    progress = game.round_num / max(game.max_rounds, 1)
    if progress > 0.66:
        game.spice_level = 2
    elif progress > 0.33:
        game.spice_level = 1
    else:
        game.spice_level = 0

    labels = ["MILD", "MEDIUM", "SPICY"]
    return labels[game.spice_level]

# ─── LEADERBOARD ─────────────────────────────────────────────────────────────

def show_leaderboard(game, dramatic=True):
    sorted_players = sorted(game.players, key=lambda p: p.score, reverse=True)

    if dramatic:
        sfx("drum")
        time.sleep(0.3)

    banner("LEADERBOARD")
    medals = ["1st", "2nd", "3rd"]
    for i, p in enumerate(sorted_players):
        rank = medals[i] if i < 3 else f"{i+1}th"
        streak_str = f" [STREAK: {p.streak}]" if p.streak >= 2 else ""
        items_str = f" | Items: {', '.join(p.items)}" if p.items else ""
        team_str = f" [Team {p.team}]" if p.team else ""

        bar = "#" * max(1, p.score)
        print(f"  {rank:>4}  {p.name:<12} {p.score:>4} pts  {bar}{streak_str}{items_str}{team_str}")

    if dramatic and sorted_players[0].streak >= 3:
        sfx("fire")

# ─── CORE TURN LOGIC ────────────────────────────────────────────────────────

def play_turn_party(player, game):
    """Party Mode: Real pool + chaos layer."""
    clear()
    spice = escalate_spice(game)
    banner(f"PARTY MODE - Round {game.round_num}/{game.max_rounds}")
    print(f"  Spice Level: {spice}")
    print(f"\n  >> {player.name}'s turn!")
    print(f"     Score: {player.score} | Streak: {player.streak}")
    if player.items:
        print(f"     Items: {', '.join(player.items)}")

    # Secret mission (30% chance)
    mission = None
    if random.random() < 0.3:
        mission = random.choice(SECRET_MISSIONS)
        print(f"\n  ** SECRET MISSION ** (only {player.name} should see this!)")
        print(f"     {mission[0]}: {mission[1]} (+{mission[2]} pts)")
        pause("Press Enter to hide mission, then take your shot...")
        clear()
        banner(f"PARTY MODE - {player.name}'s Shot")

    # Option to use item before shot
    use_item(player, game)

    # Record the shot
    print(f"\n  {player.name}, take your shot at the table!")
    result = input("  Did you make it? (y/n): ").strip().lower()
    made = result in ("y", "yes")

    player.shots_taken += 1

    if made:
        sfx("fanfare")
        player.shots_made += 1
        player.streak += 1
        points = 3

        # Streak bonuses
        if player.streak == 2:
            print("  >> Warming up...")
            points += 1
        elif player.streak == 3:
            sfx("fire")
            print("  >> ON FIRE! +2 bonus!")
            points += 2
        elif player.streak >= 4:
            sfx("fire")
            print(f"  >> UNSTOPPABLE! Streak of {player.streak}! +3 bonus!")
            points += 3

        # Final round multiplier
        if game.round_num >= game.max_rounds - 2:
            points *= 3
            print("  >> FINAL ROUNDS: 3x MULTIPLIER!")

        player.score += points
        print(f"  >> +{points} points! (Total: {player.score})")

        # Mission check
        if mission:
            completed = input(f"  Did you complete the mission '{mission[0]}'? (y/n): ").strip().lower()
            if completed in ("y", "yes"):
                player.score += mission[2]
                player.missions_completed += 1
                sfx("boom")
                print(f"  >> MISSION COMPLETE! +{mission[2]} bonus points!")

    else:
        sfx("fail")
        player.streak = 0
        print(f"  >> Miss!")

        # Consolation item (40% on miss)
        if random.random() < 0.4:
            give_item(player, game)

        # Punishment
        if not player.immunity:
            punishment = get_punishment(game)
            print(f"\n  PUNISHMENT: {punishment}")
            player.punishments_received += 1
        else:
            print("\n  >> IMMUNITY ACTIVE! Punishment blocked!")
            player.immunity = False

    show_leaderboard(game)
    pause()

def play_turn_chaos(player, game):
    """Total Chaos Mode: App controls everything."""
    clear()
    escalate_spice(game)
    banner(f"TOTAL CHAOS - Round {game.round_num}/{game.max_rounds}")
    print(f"\n  >> {player.name}, the app commands you!")

    # Random chaos command
    command = random.choice(CHAOS_COMMANDS)
    sfx("siren")
    print(f"\n  COMMAND: {command}")

    # Also assign a secret mission
    mission = random.choice(SECRET_MISSIONS)
    print(f"\n  BONUS MISSION: {mission[0]} - {mission[1]} (+{mission[2]} pts)")

    # Option to use item
    use_item(player, game)

    pause("Follow the command, then take your shot!")

    result = input(f"\n  Did {player.name} make the shot? (y/n): ").strip().lower()
    made = result in ("y", "yes")
    player.shots_taken += 1

    if made:
        sfx("fanfare")
        player.shots_made += 1
        player.streak += 1
        points = random.randint(3, 8)  # Chaos = random points
        player.score += points
        print(f"  >> +{points} points! (Chaos scoring!)")

        mission_done = input(f"  Complete the mission too? (y/n): ").strip().lower()
        if mission_done in ("y", "yes"):
            player.score += mission[2]
            player.missions_completed += 1
            print(f"  >> +{mission[2]} mission bonus!")
    else:
        sfx("fail")
        player.streak = 0
        # In chaos mode, misses have wild consequences
        consequence = random.choice([
            "SCORE SCRAMBLE: Your score is randomized between 0 and your current score!",
            "POINT TRANSFER: Give 3 points to the person on your left!",
            "PUNISHMENT TIME!",
            "LUCKY MISS: You actually get 2 points anyway!",
            "ITEM DROP: You get a consolation item!",
            "NOTHING HAPPENS: The chaos gods show mercy.",
        ])
        print(f"\n  >> {consequence}")
        if "SCRAMBLE" in consequence:
            player.score = random.randint(0, max(player.score, 1))
        elif "TRANSFER" in consequence:
            idx = game.players.index(player)
            next_player = game.players[(idx + 1) % len(game.players)]
            transfer = min(3, player.score)
            player.score -= transfer
            next_player.score += transfer
        elif "PUNISHMENT" in consequence:
            print(f"  >> {get_punishment(game)}")
            player.punishments_received += 1
        elif "LUCKY" in consequence:
            player.score += 2
        elif "ITEM" in consequence:
            give_item(player, game)

    # Random event (20% chance)
    if random.random() < 0.2:
        sfx("siren")
        event = random.choice([
            "SCORE SWAP: The top and bottom players swap scores!",
            "EVERYONE DRINK: Universal punishment!",
            "BONUS ROUND: Next shot is worth double for everyone!",
            "SHUFFLE: All items are collected and randomly redistributed!",
        ])
        print(f"\n  !! CHAOS EVENT: {event}")
        if "SCORE SWAP" in event:
            sorted_p = sorted(game.players, key=lambda p: p.score)
            sorted_p[0].score, sorted_p[-1].score = sorted_p[-1].score, sorted_p[0].score
            print(f"  >> {sorted_p[0].name} and {sorted_p[-1].name} swapped scores!")

    show_leaderboard(game)
    pause()

def play_turn_saboteur(player, game):
    """Saboteur Mode: One player secretly tries to lose."""
    clear()
    escalate_spice(game)
    banner(f"SABOTEUR MODE - Round {game.round_num}/{game.max_rounds}")
    print(f"\n  >> {player.name}'s turn!")
    print(f"     Score: {player.score} | Streak: {player.streak}")

    # Secret saboteur instructions
    if player.is_saboteur:
        print(f"\n  ** SABOTEUR EYES ONLY ** (hide screen from others!)")
        hint = random.choice(SABOTEUR_BEHAVIORS)
        print(f"     Strategy: {hint}")
        pause("Press Enter to hide saboteur info...")
        clear()
        banner(f"SABOTEUR MODE - {player.name}'s Shot")

    # Regular mission sometimes
    mission = None
    if random.random() < 0.25:
        mission = random.choice(SECRET_MISSIONS)
        print(f"\n  MISSION: {mission[0]} - {mission[1]} (+{mission[2]} pts)")

    use_item(player, game)

    result = input(f"\n  Did {player.name} make the shot? (y/n): ").strip().lower()
    made = result in ("y", "yes")
    player.shots_taken += 1

    if made:
        sfx("fanfare")
        player.shots_made += 1
        player.streak += 1
        points = 3 + min(player.streak, 3)
        player.score += points
        print(f"  >> +{points} points!")

        if mission:
            completed = input(f"  Mission '{mission[0]}' done? (y/n): ").strip().lower()
            if completed in ("y", "yes"):
                player.score += mission[2]
                player.missions_completed += 1
    else:
        sfx("fail")
        player.streak = 0
        if random.random() < 0.3:
            give_item(player, game)
        if not player.immunity:
            print(f"\n  PUNISHMENT: {get_punishment(game)}")
            player.punishments_received += 1
        else:
            print("  >> Immunity blocked the punishment!")
            player.immunity = False

    # Suspicion vote (every 3 rounds)
    if game.round_num % 3 == 0 and game.round_num > 0:
        sfx("suspense")
        print("\n  *** SUSPICION VOTE ***")
        print("  Who do you think is the SABOTEUR?")
        print("  (Each player whispers their vote to the referee)\n")
        for p in game.players:
            print(f"    {p.name}: ", end="")
            vote = input("").strip()
            for target in game.players:
                if target.name.lower() == vote.lower():
                    target.suspicion_votes += 1
                    break

        most_sus = max(game.players, key=lambda p: p.suspicion_votes)
        print(f"\n  >> Most suspected: {most_sus.name} ({most_sus.suspicion_votes} votes)")

    # Emergency meeting option
    if game.emergency_meetings_left > 0:
        call_meeting = input("\n  Anyone calling an EMERGENCY MEETING? (y/n): ").strip().lower()
        if call_meeting in ("y", "yes"):
            game.emergency_meetings_left -= 1
            sfx("siren")
            print("\n  !! EMERGENCY MEETING !!")
            print("  Everyone debates for 60 seconds, then votes.\n")
            caller = input("  Who called it? ").strip()
            accused = input("  Who are they accusing? ").strip()

            votes_guilty = 0
            votes_innocent = 0
            for p in game.players:
                v = input(f"  {p.name} votes (guilty/innocent): ").strip().lower()
                if v.startswith("g"):
                    votes_guilty += 1
                else:
                    votes_innocent += 1

            if votes_guilty > votes_innocent:
                # Check if correct
                for p in game.players:
                    if p.name.lower() == accused.lower():
                        if p.is_saboteur:
                            sfx("fanfare")
                            print(f"\n  >> CORRECT! {accused} was the SABOTEUR!")
                            print(f"  >> {caller} gets 15 bonus points!")
                            for cp in game.players:
                                if cp.name.lower() == caller.lower():
                                    cp.score += 15
                        else:
                            sfx("fail")
                            print(f"\n  >> WRONG! {accused} was innocent!")
                            print(f"  >> {caller} loses 10 points!")
                            for cp in game.players:
                                if cp.name.lower() == caller.lower():
                                    cp.score = max(0, cp.score - 10)
                        break
            else:
                print("  >> Vote failed. The game continues...")

    show_leaderboard(game)
    pause()

def play_turn_loser(player, game):
    """Loser's League: Everyone tries to miss convincingly."""
    clear()
    banner(f"LOSER'S LEAGUE - Round {game.round_num}/{game.max_rounds}")
    print(f"\n  REMEMBER: You're trying to MISS... but make it look real!")
    print(f"\n  >> {player.name}'s turn!")
    print(f"     Score: {player.score}")

    # Give them a suggested excuse
    excuse = random.choice(LOSER_LEAGUE_EXCUSES)
    print(f"\n  Suggested excuse if caught: \"{excuse}\"")

    pause("Take your shot...")

    result = input(f"\n  Did {player.name} make it? (y/n): ").strip().lower()
    made = result in ("y", "yes")
    player.shots_taken += 1

    if made:
        sfx("fail")  # Making it is BAD in Loser's League
        print("  >> OH NO! You accidentally MADE it!")
        player.score -= 3
        print("  >> -3 points! (You're supposed to MISS!)")
        punishment = get_punishment(game)
        print(f"  >> PUNISHMENT for making it: {punishment}")
        player.punishments_received += 1
    else:
        player.shots_made += 1  # Tracking "successful" misses
        print("  >> Nice miss!")

        # Vote: was it convincing?
        print("\n  VOTE: Was that miss convincing or were they clearly faking?")
        convincing = 0
        faking = 0
        for other in game.players:
            if other != player:
                vote = input(f"    {other.name} - convincing (c) or faking (f)? ").strip().lower()
                if vote.startswith("c"):
                    convincing += 1
                else:
                    faking += 1

        if convincing >= faking:
            sfx("fanfare")
            points = 3 + convincing  # More unanimous = more points
            player.score += points
            print(f"  >> CONVINCING! +{points} points!")
        else:
            sfx("siren")
            print(f"  >> CAUGHT FAKING! No points and a punishment!")
            punishment = get_punishment(game)
            print(f"  >> {punishment}")
            player.punishments_received += 1

    show_leaderboard(game)
    pause()

def play_turn_team(player, game):
    """Team Mode: Shared team scores."""
    clear()
    escalate_spice(game)
    banner(f"TEAM MODE - Round {game.round_num}/{game.max_rounds}")
    print(f"\n  >> {player.name}'s turn! [Team {player.team}]")
    print(f"     Personal: {player.score} pts | Streak: {player.streak}")

    # Show team scores
    for team_name in ("A", "B"):
        team_score = sum(p.score for p in game.players if p.team == team_name)
        members = [p.name for p in game.players if p.team == team_name]
        print(f"     Team {team_name}: {team_score} pts ({', '.join(members)})")

    mission = None
    if random.random() < 0.3:
        mission = random.choice(SECRET_MISSIONS)
        print(f"\n  TEAM MISSION: {mission[0]} - {mission[1]} (+{mission[2]} for the team!)")

    use_item(player, game)

    result = input(f"\n  Did {player.name} make it? (y/n): ").strip().lower()
    made = result in ("y", "yes")
    player.shots_taken += 1

    if made:
        sfx("fanfare")
        player.shots_made += 1
        player.streak += 1
        points = 3 + min(player.streak, 3)
        player.score += points
        print(f"  >> +{points} for {player.name} and Team {player.team}!")

        if mission:
            completed = input(f"  Mission done? (y/n): ").strip().lower()
            if completed in ("y", "yes"):
                # Bonus goes to all team members
                for tp in game.players:
                    if tp.team == player.team:
                        tp.score += mission[2] // 2
                print(f"  >> Team {player.team} gets mission bonus!")
    else:
        sfx("fail")
        player.streak = 0

        # Team punishment or individual
        if random.random() < 0.3:
            print(f"\n  TEAM PUNISHMENT for Team {player.team}:")
            punishment = get_punishment(game)
            print(f"  >> {punishment} (entire team!)")
            for tp in game.players:
                if tp.team == player.team:
                    tp.punishments_received += 1
        else:
            if not player.immunity:
                print(f"\n  PUNISHMENT: {get_punishment(game)}")
                player.punishments_received += 1
            else:
                print("  >> Immunity blocked!")
                player.immunity = False

        if random.random() < 0.4:
            give_item(player, game)

    # Show team leaderboard
    print("\n  --- TEAM STANDINGS ---")
    for team_name in ("A", "B"):
        team_score = sum(p.score for p in game.players if p.team == team_name)
        print(f"  Team {team_name}: {team_score} pts")
    show_leaderboard(game, dramatic=False)
    pause()

def play_turn_quick(player, game):
    """Quick Round: Simplified, fast turns."""
    clear()
    banner(f"QUICK ROUND - Turn {game.round_num}/{game.max_rounds}")
    print(f"\n  >> {player.name} - SHOOT FAST!")

    # Simple: make or miss, points or punishment
    result = input("  Made it? (y/n): ").strip().lower()
    made = result in ("y", "yes")
    player.shots_taken += 1

    if made:
        player.shots_made += 1
        player.streak += 1
        points = 5 * player.streak  # Streaks are HUGE in quick mode
        player.score += points
        print(f"  >> +{points}! ", end="")
        if player.streak >= 2:
            print(f"(Streak x{player.streak}!)")
        else:
            print()
    else:
        player.streak = 0
        print(f"  >> {random.choice(PUNISHMENTS_MILD)}")
        player.punishments_received += 1

    # Quick leaderboard
    sorted_p = sorted(game.players, key=lambda p: p.score, reverse=True)
    for i, p in enumerate(sorted_p):
        marker = " <<" if p == player else ""
        print(f"  {i+1}. {p.name}: {p.score}{marker}")
    pause("")

# ─── POST GAME ───────────────────────────────────────────────────────────────

def post_game_ceremony(game):
    clear()
    sfx("drum")
    time.sleep(0.5)
    banner("GAME OVER!")
    time.sleep(0.5)

    sorted_players = sorted(game.players, key=lambda p: p.score, reverse=True)

    # Reveal saboteur if applicable
    if game.mode == "Saboteur" and game.saboteur:
        sfx("suspense")
        time.sleep(1)
        print(f"\n  The SABOTEUR was... ", end="", flush=True)
        time.sleep(1.5)
        sfx("siren")
        print(f"{game.saboteur.name}!")
        print(f"  They {'successfully sabotaged!' if game.saboteur.score <= sorted_players[len(sorted_players)//2].score else 'got caught playing too well!'}")
        pause()

    # Podium ceremony
    clear()
    sfx("fanfare")
    banner("MVP PODIUM")

    if len(sorted_players) >= 3:
        print(f"""
              ___________
             |           |
             |  1st: {sorted_players[0].name:<4} |
      _______|           |_______
     |       |  {sorted_players[0].score:>3} pts  |       |
     | 2nd:  |           | 3rd:  |
     | {sorted_players[1].name:<5} |___________| {sorted_players[2].name:<5} |
     | {sorted_players[1].score:>3}pts|           | {sorted_players[2].score:>3}pts|
     |_______|           |_______|
    """)
    elif len(sorted_players) == 2:
        print(f"\n  1st: {sorted_players[0].name} ({sorted_players[0].score} pts)")
        print(f"  2nd: {sorted_players[1].name} ({sorted_players[1].score} pts)")

    pause()

    # Awards
    clear()
    banner("AWARDS CEREMONY")

    awards = []
    if sorted_players:
        awards.append(("MVP", sorted_players[0].name, f"{sorted_players[0].score} pts"))

    most_accurate = max(game.players, key=lambda p: p.shots_made / max(p.shots_taken, 1))
    if most_accurate.shots_taken > 0:
        pct = round(most_accurate.shots_made / most_accurate.shots_taken * 100)
        awards.append(("Sharpshooter", most_accurate.name, f"{pct}% accuracy"))

    most_punished = max(game.players, key=lambda p: p.punishments_received)
    if most_punished.punishments_received > 0:
        awards.append(("Punching Bag", most_punished.name, f"{most_punished.punishments_received} punishments"))

    least_points = min(game.players, key=lambda p: p.score)
    awards.append(("Participant Trophy", least_points.name, "Better luck next time"))

    best_streak = max(game.players, key=lambda p: p.streak)
    if best_streak.shots_made >= 2:
        awards.append(("Hot Hand", best_streak.name, f"Best streak"))

    mission_master = max(game.players, key=lambda p: p.missions_completed)
    if mission_master.missions_completed > 0:
        awards.append(("Mission Master", mission_master.name, f"{mission_master.missions_completed} missions"))

    for title, name, stat in awards:
        dramatic_reveal(title, f"{name} - {stat}")
        time.sleep(0.3)

    # Full stats
    print("\n\n  --- FULL STATS ---")
    for p in sorted_players:
        acc = round(p.shots_made / max(p.shots_taken, 1) * 100)
        print(f"  {p.name}: {p.score}pts | {p.shots_made}/{p.shots_taken} shots ({acc}%) | {p.punishments_received} punishments | {len(p.items)} items left")

    banner("THANKS FOR PLAYING RACKUP!")
    print("\n  Play again? Grab another round and start a new game!")
    print()

# ─── MAIN GAME LOOP ─────────────────────────────────────────────────────────

def main():
    clear()
    print("""
    ╔═══════════════════════════════════════════╗
    ║                                           ║
    ║   ██████╗  █████╗  ██████╗██╗  ██╗       ║
    ║   ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝       ║
    ║   ██████╔╝███████║██║     █████╔╝        ║
    ║   ██╔══██╗██╔══██║██║     ██╔═██╗        ║
    ║   ██║  ██║██║  ██║╚██████╗██║  ██╗       ║
    ║   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝       ║
    ║              U P                          ║
    ║                                           ║
    ║   Turn Bar Games Into Absolute Chaos      ║
    ║                                           ║
    ╚═══════════════════════════════════════════╝
    """)
    pause("Press Enter to start!")

    game = Game()
    game.players = setup_players()

    # Custom punishments
    do_custom = input("\n  Add custom punishments? (y/n): ").strip().lower()
    if do_custom in ("y", "yes"):
        setup_custom_punishments(game)

    # Choose mode
    game.mode = choose_mode()

    # Mode-specific setup
    if game.mode == "Quick Round":
        game.max_rounds = 5
        print("\n  Quick Round: 5 rounds, go fast!")
    else:
        game.max_rounds = choose_rounds()

    if game.mode == "Saboteur":
        # Secretly assign saboteur
        game.saboteur = random.choice(game.players)
        game.saboteur.is_saboteur = True
        clear()
        banner("SABOTEUR ASSIGNMENT")
        print("\n  Pass the device to each player one at a time.")
        print("  Only the saboteur will see a message.\n")
        for p in game.players:
            input(f"  >> Hand device to {p.name}, then press Enter...")
            clear()
            if p.is_saboteur:
                sfx("suspense")
                print(f"\n\n  {p.name}... YOU are the SABOTEUR!")
                print("  Your goal: finish in the BOTTOM HALF without getting caught.")
                print("  Play badly... but not TOO badly.")
                pause("Memorize this, then press Enter to hide...")
            else:
                print(f"\n\n  {p.name}... you are NOT the saboteur.")
                print("  Play your best and find the traitor!")
                pause("Press Enter to hide...")
            clear()
        print("\n  Saboteur has been assigned. Trust no one.")
        pause()

    if game.mode == "Team Mode":
        # Split into teams
        random.shuffle(game.players)
        half = len(game.players) // 2
        for i, p in enumerate(game.players):
            p.team = "A" if i < half else "B"
            game.teams[p.team].append(p)
        clear()
        banner("TEAMS")
        print(f"\n  Team A: {', '.join(p.name for p in game.teams['A'])}")
        print(f"  Team B: {', '.join(p.name for p in game.teams['B'])}")
        pause()

    # Assign turn function based on mode
    turn_funcs = {
        "Party Mode": play_turn_party,
        "Total Chaos": play_turn_chaos,
        "Saboteur": play_turn_saboteur,
        "Loser's League": play_turn_loser,
        "Team Mode": play_turn_team,
        "Quick Round": play_turn_quick,
    }
    turn_func = turn_funcs[game.mode]

    # Main game loop
    for round_num in range(1, game.max_rounds + 1):
        game.round_num = round_num
        for player in game.players:
            turn_func(player, game)

    # Post-game
    post_game_ceremony(game)

    # Play again?
    again = input("  Play again? (y/n): ").strip().lower()
    if again in ("y", "yes"):
        main()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n  Thanks for playing RackUp! See you next pool night.\n")
        sys.exit(0)
