import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';
import 'package:rackup/features/game/view/widgets/event_feed_widget.dart';
import 'package:rackup/features/game/view/widgets/leaderboard_row.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';

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
    this.isTriplePoints = false,
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

  /// Whether the game is in triple-point territory.
  final bool isTriplePoints;

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

    final themeData = RackUpGameTheme.maybeOf(context);
    final bgColor = themeData?.backgroundColor ?? RackUpColors.canvas;
    final transitionDuration =
        themeData?.tierTransitionDuration ?? Duration.zero;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedContainer(
        duration: transitionDuration,
        color: bgColor,
        child: SafeArea(
          child: Column(
          children: [
            // Header (~60dp).
            ProgressTierBar(
              currentRound: currentRound,
              totalRounds: totalRounds,
              tier: tier,
              isTriplePoints: isTriplePoints,
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
            const Expanded(
              flex: 25,
              child: EventFeedWidget(),
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
      ),
    );
  }

  Widget _buildLeaderboardFromEntries(
    BuildContext context,
    LeaderboardActive state,
  ) {
    final entries = state.entries;
    // Build previous index map for position-shuffle animation.
    final prevIndexMap = <String, int>{};
    for (final (i, prev) in state.previousEntries.indexed) {
      prevIndexMap[prev.deviceIdHash] = i;
    }
    // Build previous score/rank maps for visual indicators.
    final prevScoreMap = <String, int>{};
    final prevRankMap = <String, int>{};
    for (final prev in state.previousEntries) {
      prevScoreMap[prev.deviceIdHash] = prev.score;
      prevRankMap[prev.deviceIdHash] = prev.rank;
    }

    final animationsEnabled =
        RackUpGameTheme.maybeOf(context)?.animationsEnabled ?? true;

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

              // Score delta for "+N" indicator.
              final prevScore = prevScoreMap[entry.deviceIdHash];
              final scoreDelta =
                  prevScore != null ? entry.score - prevScore : 0;

              // Rank change indicator.
              final prevRank = prevRankMap[entry.deviceIdHash];
              final bool? rankImproved;
              if (prevRank != null && prevRank != entry.rank) {
                rankImproved = entry.rank < prevRank; // lower rank = better
              } else {
                rankImproved = null;
              }

              // Position-shuffle animation: slide from previous index.
              final prevIndex = prevIndexMap[entry.deviceIdHash];
              final indexDelta =
                  prevIndex != null ? prevIndex - index : 0;

              Widget row = LeaderboardRow(
                entry: entry,
                players: players,
                isSelf: isSelf,
                isShooter: isShooter,
                isLeader: isLeader,
                isMilestone: isMilestone,
                scoreDelta: scoreDelta,
                rankImproved: rankImproved,
                rankChanged: entry.rankChanged,
              );

              // Staggered position-shuffle animation (The Shuffle pattern).
              if (indexDelta != 0 && animationsEnabled) {
                // Wider stagger for streak milestones (80ms vs ~30ms).
                final staggerMs =
                    state.cascadeProfile == 'streak_milestone'
                        ? 0.08
                        : 0.06;
                final staggerCurve = Interval(
                  (index * staggerMs).clamp(0.0, 0.5),
                  1.0,
                  curve: Curves.easeOutCubic,
                );

                row = TweenAnimationBuilder<double>(
                  key: ValueKey('opacity-${entry.deviceIdHash}'),
                  tween: Tween(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: staggerCurve,
                  builder: (context, opacity, child) {
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: TweenAnimationBuilder<Offset>(
                    key: ValueKey('anim-${entry.deviceIdHash}'),
                    tween: Tween(
                      begin: Offset(0, indexDelta.toDouble()),
                      end: Offset.zero,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: staggerCurve,
                    builder: (context, offset, child) {
                      return FractionalTranslation(
                        translation: offset,
                        child: child,
                      );
                    },
                    child: row,
                  ),
                );
              }

              return row;
            },
          ),
        ),
      ],
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
