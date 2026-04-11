# Sound assets

> **PLACEHOLDER WARNING**: All `.mp3` files in this directory are byte-identical
> placeholder copies (same SHA1) of an early test sound. They preload at runtime
> and play, but every game sound currently emits the same audio.
>
> Action required from a designer/audio engineer: replace each file below with
> a unique, royalty-free audio clip (≤ 2 seconds, 32 kbps MP3, ≤ 100 KB) so the
> sound effects are distinguishable in-game. Filenames are referenced from
> `lib/core/audio/sound_manager.dart` (`GameSound` enum) — keep names unchanged.

| File                       | Trigger                                                        |
| -------------------------- | -------------------------------------------------------------- |
| `blue_shell_impact.mp3`    | Blue Shell item deploys (impact sound for all players)         |
| `item_drop.mp3`            | Item drop animation when an item enters a player's inventory  |
| `item_deployed.mp3`        | Generic item deploy impact (non-Blue-Shell)                    |
| `leaderboard_shuffle.mp3`  | Leaderboard rank shuffle animation                             |
| `podium_fanfare.mp3`       | Final podium reveal at game end (Epic 8)                       |
| `punishment_reveal.mp3`    | Punishment card flips face-up after a missed shot              |
| `streak_fire.mp3`          | Streak milestone (`warming_up` / `on_fire` / `unstoppable`)    |
