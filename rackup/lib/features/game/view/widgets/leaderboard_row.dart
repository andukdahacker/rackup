import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/view/widgets/streak_fire_indicator.dart';

/// A single leaderboard row with score change indicator, rank change arrow,
/// and animated leader glow.
class LeaderboardRow extends StatefulWidget {
  const LeaderboardRow({
    required this.entry,
    required this.players,
    required this.isSelf,
    required this.isShooter,
    required this.isLeader,
    required this.isMilestone,
    required this.scoreDelta,
    required this.rankImproved,
    required this.rankChanged,
    super.key,
  });

  final LeaderboardEntry entry;
  final List<GamePlayer> players;
  final bool isSelf;
  final bool isShooter;
  final bool isLeader;
  final bool isMilestone;
  final int scoreDelta;

  /// True if rank improved (went up), false if worsened, null if unchanged.
  final bool? rankImproved;

  /// Whether rank changed at all.
  final bool rankChanged;

  @override
  State<LeaderboardRow> createState() => _LeaderboardRowState();
}

class _LeaderboardRowState extends State<LeaderboardRow> {
  bool _showScoreDelta = false;
  bool _showRankArrow = false;
  Timer? _scoreDeltaTimer;
  Timer? _rankArrowTimer;

  @override
  void initState() {
    super.initState();
    // Set initial state directly (no setState during initState).
    if (widget.scoreDelta > 0) {
      _showScoreDelta = true;
      _scoreDeltaTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showScoreDelta = false);
      });
    }
    if (widget.rankChanged) {
      _showRankArrow = true;
      _rankArrowTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showRankArrow = false);
      });
    }
  }

  @override
  void didUpdateWidget(covariant LeaderboardRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.score != widget.entry.score &&
        widget.scoreDelta > 0) {
      _triggerScoreDelta();
    }
    if (oldWidget.entry.rank != widget.entry.rank && widget.rankChanged) {
      _triggerRankArrow();
    }
  }

  void _triggerScoreDelta() {
    if (widget.scoreDelta <= 0) return;
    _scoreDeltaTimer?.cancel();
    setState(() => _showScoreDelta = true);
    _scoreDeltaTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showScoreDelta = false);
    });
  }

  void _triggerRankArrow() {
    if (!widget.rankChanged) return;
    _rankArrowTimer?.cancel();
    setState(() => _showRankArrow = true);
    _rankArrowTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showRankArrow = false);
    });
  }

  @override
  void dispose() {
    _scoreDeltaTimer?.cancel();
    _rankArrowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled =
        RackUpGameTheme.maybeOf(context)?.animationsEnabled ?? true;

    return RepaintBoundary(
      child: Padding(
        key: ValueKey(widget.entry.deviceIdHash),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildDecoration(
          animationsEnabled: animationsEnabled,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                // Rank number with optional rank change arrow.
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.entry.rank}',
                        style: GoogleFonts.oswald(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isLeader
                              ? RackUpColors.streakGold
                              : RackUpColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        textScaler:
                            ClampedTextScaler.of(context, TextRole.body),
                      ),
                      if (_showRankArrow &&
                          widget.rankImproved != null &&
                          animationsEnabled)
                        AnimatedOpacity(
                          opacity: _showRankArrow ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.rankImproved!
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 10,
                            color: widget.rankImproved!
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.isShooter)
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
                    displayName: widget.entry.displayName,
                    slot: widget.players
                            .where(
                              (p) =>
                                  p.deviceIdHash ==
                                  widget.entry.deviceIdHash,
                            )
                            .firstOrNull
                            ?.slot ??
                        1,
                    size: PlayerNameTagSize.leaderboard,
                    tagState: widget.isSelf
                        ? PlayerNameTagState.highlighted
                        : PlayerNameTagState.normal,
                  ),
                ),
                if (widget.entry.streakLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StreakFireIndicator(
                      streakLabel: widget.entry.streakLabel,
                      isMilestone: widget.isMilestone,
                    ),
                  ),
                // Score with optional "+N" indicator.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.entry.score}',
                      style: GoogleFonts.oswald(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: RackUpColors.textPrimary,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                    if (_showScoreDelta &&
                        widget.scoreDelta > 0 &&
                        animationsEnabled)
                      AnimatedOpacity(
                        opacity: _showScoreDelta ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '+${widget.scoreDelta}',
                            style: GoogleFonts.oswald(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RackUpColors.streakGold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecoration({
    required bool animationsEnabled,
    required Widget child,
  }) {
    if (widget.isLeader && animationsEnabled) {
      // Animated pulsing leader glow.
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.1, end: 0.2),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, alpha, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: RackUpColors.streakGold.withValues(alpha: alpha),
                  blurRadius: 12,
                ),
              ],
              color: widget.isSelf
                  ? RackUpColors.itemBlue.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          );
        },
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isLeader
            ? [
                BoxShadow(
                  color:
                      RackUpColors.streakGold.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
        color: widget.isSelf
            ? RackUpColors.itemBlue.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
