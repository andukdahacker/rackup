import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';
import 'package:rackup/features/game/view/widgets/streak_fire_indicator.dart';

/// The Player Screen — 4-region layout for non-referee players.
///
/// Regions: Header (~60dp), Leaderboard (~50%), Event Feed (~25%),
/// My Status (~15%).
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    required this.players,
    required this.myDeviceIdHash,
    required this.currentShooterDeviceIdHash,
    required this.leaderboardBloc,
    super.key,
  });

  /// Current round number.
  final int currentRound;

  /// Total rounds.
  final int totalRounds;

  /// Current escalation tier.
  final EscalationTier tier;

  /// All players in the game.
  final List<GamePlayer> players;

  /// The current device's ID hash (for highlighting self row).
  final String myDeviceIdHash;

  /// The current shooter's device ID hash (for turn indicator).
  final String currentShooterDeviceIdHash;

  /// LeaderboardBloc for animated position tracking.
  final LeaderboardBloc leaderboardBloc;

  @override
  Widget build(BuildContext context) {
    GamePlayer? myPlayer;
    for (final p in players) {
      if (p.deviceIdHash == myDeviceIdHash) {
        myPlayer = p;
        break;
      }
    }

    // Find current shooter's display name.
    String? currentShooterName;
    for (final p in players) {
      if (p.deviceIdHash == currentShooterDeviceIdHash) {
        currentShooterName = p.displayName;
        break;
      }
    }

    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header (~60dp).
            ProgressTierBar(
              currentRound: currentRound,
              totalRounds: totalRounds,
              tier: tier,
            ),
            // Leaderboard (~50%).
            Expanded(
              flex: 50,
              child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
                bloc: leaderboardBloc,
                builder: (context, leaderboardState) {
                  // Use server leaderboard if available, otherwise fallback to local sort.
                  if (leaderboardState is LeaderboardActive) {
                    return _buildLeaderboardFromEntries(
                      context,
                      leaderboardState,
                    );
                  }

                  // Fallback: sort players locally.
                  final sorted = List<GamePlayer>.of(players)
                    ..sort((a, b) => b.score.compareTo(a.score));
                  return _buildLeaderboardFromPlayers(context, sorted);
                },
              ),
            ),
            // Event Feed (~25%).
            Expanded(
              flex: 25,
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.topLeft,
                child: Text(
                  currentShooterName != null
                      ? "It's $currentShooterName's turn"
                      : 'Game started!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: RackUpColors.textSecondary,
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                ),
              ),
            ),
            // My Status (~15%).
            Expanded(
              flex: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (myPlayer case final mp?)
                      Expanded(
                        child: PlayerNameTag(
                          displayName: mp.displayName,
                          slot: mp.slot,
                          size: PlayerNameTagSize.compact,
                        ),
                      ),
                    Text(
                      '${myPlayer?.score ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: RackUpColors.textPrimary,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                    const SizedBox(width: 8),
                    if (myPlayer case final mp? when mp.streak > 0)
                      Text(
                        '${mp.streak}x',
                        style: const TextStyle(
                          fontSize: 14,
                          color: RackUpColors.streakGold,
                        ),
                        textScaler:
                            ClampedTextScaler.of(context, TextRole.body),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'No items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RackUpColors.textSecondary,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardFromEntries(
    BuildContext context,
    LeaderboardActive state,
  ) {
    final entries = state.entries;
    // Build previous rank map for position-shuffle animation.
    final prevRankMap = <String, int>{};
    for (final e in state.previousEntries) {
      prevRankMap[e.deviceIdHash] = entries.indexWhere(
        (c) => c.deviceIdHash == e.deviceIdHash,
      );
    }
    final prevIndexMap = <String, int>{};
    for (final (i, prev) in state.previousEntries.indexed) {
      prevIndexMap[prev.deviceIdHash] = i;
    }

    // CascadeTiming is available via state.cascadeProfile for future
    // dramatic pacing integration (e.g., delaying event feed rendering).

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isSelf = entry.deviceIdHash == myDeviceIdHash;
              final isShooter =
                  entry.deviceIdHash == currentShooterDeviceIdHash;
              final isLeader = index == 0;
              final isMilestone = state.streakMilestone &&
                  entry.deviceIdHash == state.shooterHash;

              // Position-shuffle animation: slide from previous index.
              final prevIndex = prevIndexMap[entry.deviceIdHash];
              final indexDelta =
                  prevIndex != null ? prevIndex - index : 0;

              Widget row = _buildEntryRow(
                context,
                entry: entry,
                isSelf: isSelf,
                isShooter: isShooter,
                isLeader: isLeader,
                isMilestone: isMilestone,
              );

              if (indexDelta != 0) {
                row = TweenAnimationBuilder<Offset>(
                  key: ValueKey('anim-${entry.deviceIdHash}'),
                  tween: Tween(
                    begin: Offset(0, indexDelta.toDouble()),
                    end: Offset.zero,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, offset, child) {
                    return FractionalTranslation(
                      translation: offset,
                      child: child,
                    );
                  },
                  child: row,
                );
              }

              return row;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntryRow(
    BuildContext context, {
    required LeaderboardEntry entry,
    required bool isSelf,
    required bool isShooter,
    required bool isLeader,
    required bool isMilestone,
  }) {
    return Padding(
      key: ValueKey(entry.deviceIdHash),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Leader gets subtle radial glow.
          boxShadow: isLeader
              ? [
                  BoxShadow(
                    color:
                        RackUpColors.streakGold.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
          // Self row gets blue tint.
          color: isSelf
              ? RackUpColors.itemBlue.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              // Rank number.
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLeader
                        ? RackUpColors.streakGold
                        : RackUpColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  textScaler:
                      ClampedTextScaler.of(context, TextRole.body),
                ),
              ),
              if (isShooter)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.sports_basketball,
                    color: RackUpColors.streakGold,
                    size: 16,
                  ),
                ),
              Expanded(
                child: PlayerNameTag(
                  displayName: entry.displayName,
                  slot: players
                          .where(
                            (p) => p.deviceIdHash == entry.deviceIdHash,
                          )
                          .firstOrNull
                          ?.slot ??
                      1,
                  tagState: isSelf
                      ? PlayerNameTagState.highlighted
                      : PlayerNameTagState.normal,
                ),
              ),
              if (entry.streakLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StreakFireIndicator(
                    streakLabel: entry.streakLabel,
                    isMilestone: isMilestone,
                  ),
                ),
              Text(
                '${entry.score}',
                style: const TextStyle(
                  fontSize: 16,
                  color: RackUpColors.textPrimary,
                ),
                textScaler:
                    ClampedTextScaler.of(context, TextRole.body),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardFromPlayers(
    BuildContext context,
    List<GamePlayer> sorted,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final player = sorted[index];
        final isSelf = player.deviceIdHash == myDeviceIdHash;
        final isShooter =
            player.deviceIdHash == currentShooterDeviceIdHash;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              if (isShooter)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.sports_basketball,
                    color: RackUpColors.streakGold,
                    size: 16,
                  ),
                ),
              Expanded(
                child: PlayerNameTag(
                  displayName: player.displayName,
                  slot: player.slot,
                  tagState: isSelf
                      ? PlayerNameTagState.highlighted
                      : PlayerNameTagState.normal,
                ),
              ),
              Text(
                '${player.score}',
                style: const TextStyle(
                  fontSize: 16,
                  color: RackUpColors.textPrimary,
                ),
                textScaler:
                    ClampedTextScaler.of(context, TextRole.body),
              ),
            ],
          ),
        );
      },
    );
  }
}
