import 'package:flutter/material.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';

/// The Referee Command Center — 4-region layout.
///
/// Regions: Status Bar (~60dp), Stage Area (~40%), Action Zone (~35%),
/// Footer (~80dp).
class RefereeScreen extends StatelessWidget {
  const RefereeScreen({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    required this.currentShooter,
    super.key,
  });

  /// Current round number.
  final int currentRound;

  /// Total rounds.
  final int totalRounds;

  /// Current escalation tier.
  final EscalationTier tier;

  /// The player currently shooting.
  final GamePlayer currentShooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar (~60dp).
            ProgressTierBar(
              currentRound: currentRound,
              totalRounds: totalRounds,
              tier: tier,
            ),
            // Stage Area (~40%).
            Expanded(
              flex: 40,
              child: Center(
                child: PlayerNameTag(
                  displayName: currentShooter.displayName,
                  slot: currentShooter.slot,
                  size: PlayerNameTagSize.large,
                ),
              ),
            ),
            // Action Zone (~35%).
            Expanded(
              flex: 35,
              child: Center(
                child: Text(
                  'Waiting for turn...',
                  style: const TextStyle(
                    fontSize: 18,
                    color: RackUpColors.textSecondary,
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                ),
              ),
            ),
            // Footer (~80dp).
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'Leaderboard',
                  style: const TextStyle(
                    fontSize: 16,
                    color: RackUpColors.textSecondary,
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
