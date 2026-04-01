import 'package:flutter/material.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// A ~60dp fixed-height bar showing the current tier, progress, and round.
class ProgressTierBar extends StatelessWidget {
  const ProgressTierBar({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    super.key,
  });

  /// The current round number.
  final int currentRound;

  /// The total number of rounds.
  final int totalRounds;

  /// The current escalation tier.
  final EscalationTier tier;

  String get _tierLabel => switch (tier) {
        EscalationTier.lobby => 'LOBBY',
        EscalationTier.mild => 'MILD',
        EscalationTier.medium => 'MEDIUM',
        EscalationTier.spicy => 'SPICY',
      };

  Color get _tierColor => switch (tier) {
        EscalationTier.lobby => RackUpColors.tierLobby,
        EscalationTier.mild => RackUpColors.tierMild,
        EscalationTier.medium => RackUpColors.tierMedium,
        EscalationTier.spicy => RackUpColors.tierSpicy,
      };

  @override
  Widget build(BuildContext context) {
    final progress =
        totalRounds > 0 ? (currentRound - 1) / totalRounds : 0.0;

    return Semantics(
      label: 'Round $currentRound of $totalRounds, $_tierLabel tier',
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: RackUpColors.canvas,
        child: Row(
          children: [
            // Tier tag badge.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _tierColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _tierLabel,
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: RackUpColors.textPrimary,
                ),
                textScaler: ClampedTextScaler.of(context, TextRole.body),
              ),
            ),
            const SizedBox(width: 12),
            // Progress bar.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: RackUpColors.textSecondary.withValues(
                    alpha: 0.3,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Round label.
            Text(
              'R$currentRound/$totalRounds',
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: RackUpColors.textPrimary,
              ),
              textScaler: ClampedTextScaler.of(context, TextRole.body),
            ),
          ],
        ),
      ),
    );
  }
}
