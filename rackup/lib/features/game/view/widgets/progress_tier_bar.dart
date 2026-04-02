import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// A ~60dp fixed-height bar showing the current tier, progress, and round.
class ProgressTierBar extends StatefulWidget {
  const ProgressTierBar({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    this.isTriplePoints = false,
    super.key,
  });

  /// The current round number.
  final int currentRound;

  /// The total number of rounds.
  final int totalRounds;

  /// The current escalation tier.
  final EscalationTier tier;

  /// Whether the game is in triple-point territory.
  final bool isTriplePoints;

  @override
  State<ProgressTierBar> createState() => _ProgressTierBarState();
}

class _ProgressTierBarState extends State<ProgressTierBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  String get _tierLabel => switch (widget.tier) {
        EscalationTier.lobby => 'LOBBY',
        EscalationTier.mild => 'MILD',
        EscalationTier.medium => 'MEDIUM',
        EscalationTier.spicy => 'SPICY',
      };

  Color get _tierColor => switch (widget.tier) {
        EscalationTier.lobby => RackUpColors.tierLobby,
        EscalationTier.mild => RackUpColors.tierMild,
        EscalationTier.medium => RackUpColors.tierMedium,
        EscalationTier.spicy => RackUpColors.tierSpicy,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePulseAnimation();
  }

  @override
  void didUpdateWidget(covariant ProgressTierBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTriplePoints != widget.isTriplePoints) {
      _updatePulseAnimation();
    }
  }

  CurvedAnimation? _curvedAnimation;

  void _updatePulseAnimation() {
    final animationsEnabled =
        RackUpGameTheme.maybeOf(context)?.animationsEnabled ?? true;

    if (widget.isTriplePoints && animationsEnabled) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      // Dispose previous CurvedAnimation to avoid leak (P3).
      _curvedAnimation?.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      );
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        _curvedAnimation!,
      );
      _pulseController!.repeat(reverse: true);
    } else {
      _pulseController?.stop();
      _pulseAnimation = null;
    }
  }

  @override
  void dispose() {
    _curvedAnimation?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalRounds > 0
        ? (widget.currentRound - 1) / widget.totalRounds
        : 0.0;
    final themeData = RackUpGameTheme.maybeOf(context);
    final transitionDuration =
        themeData?.tierTransitionDuration ?? Duration.zero;
    final progressBarColor = widget.isTriplePoints
        ? RackUpColors.tierSpicyAccent
        : _tierColor;

    final semanticsLabel = widget.isTriplePoints
        ? 'Round ${widget.currentRound} of ${widget.totalRounds}, '
            '$_tierLabel tier, Triple points active'
        : 'Round ${widget.currentRound} of ${widget.totalRounds}, '
            '$_tierLabel tier';

    return Semantics(
      label: semanticsLabel,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: RackUpColors.canvas,
        child: Row(
          children: [
            // Tier tag badge with animated color transition.
            AnimatedContainer(
              duration: transitionDuration,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _tierColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _tierLabel,
                style: GoogleFonts.oswald(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: RackUpColors.textPrimary,
                ),
                textScaler:
                    ClampedTextScaler.of(context, TextRole.body),
              ),
            ),
            // Pulsing "3X" badge when triple points are active.
            if (widget.isTriplePoints) ...[
              const SizedBox(width: 8),
              _buildTripleBadge(),
            ],
            const SizedBox(width: 12),
            // Progress bar with animated color.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: progressBarColor),
                  duration: transitionDuration,
                  builder: (context, color, _) {
                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor:
                          RackUpColors.textSecondary.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color ?? progressBarColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Round label.
            Text(
              'R${widget.currentRound}/${widget.totalRounds}',
              style: GoogleFonts.oswald(
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

  Widget _buildTripleBadge() {
    final badge = RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: RackUpColors.tierSpicy,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '3X',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: RackUpColors.streakGold,
          ),
          textScaler: ClampedTextScaler.of(context, TextRole.body),
        ),
      ),
    );

    if (_pulseAnimation != null) {
      return ScaleTransition(
        scale: _pulseAnimation!,
        child: badge,
      );
    }

    return badge;
  }
}
