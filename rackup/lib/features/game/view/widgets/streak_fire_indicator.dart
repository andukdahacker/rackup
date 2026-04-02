import 'package:flutter/material.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Visual streak indicator with escalating fire emoji and labels.
///
/// Three visual states:
/// - warming_up: single flame, amber tint
/// - on_fire: double flame, gold with glow
/// - unstoppable: triple flame, pulsing gold
///
/// Milestone transitions use The Eruption pattern (scale 1.0 → 1.4 → 1.0, 300ms).
class StreakFireIndicator extends StatefulWidget {
  const StreakFireIndicator({
    required this.streakLabel,
    this.isMilestone = false,
    super.key,
  });

  /// The streak label: "warming_up", "on_fire", or "unstoppable".
  final String streakLabel;

  /// Whether this is a milestone transition (triggers Eruption animation).
  final bool isMilestone;

  @override
  State<StreakFireIndicator> createState() => _StreakFireIndicatorState();
}

class _StreakFireIndicatorState extends State<StreakFireIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // The Eruption: scale 1.0 -> 1.4 -> 1.0.
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Continuous pulse for unstoppable (1.0 → 1.1 → 1.0).
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isMilestone) {
      _controller.forward().then((_) {
        // After eruption completes, start pulse if unstoppable.
        if (mounted &&
            widget.streakLabel == 'unstoppable' &&
            !_controller.isAnimating) {
          _controller.repeat();
        }
      });
    } else if (widget.streakLabel == 'unstoppable') {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StreakFireIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMilestone && !oldWidget.isMilestone) {
      _controller
        ..reset()
        ..forward().then((_) {
          // After eruption completes, start pulse if unstoppable.
          if (mounted &&
              widget.streakLabel == 'unstoppable' &&
              !_controller.isAnimating) {
            _controller.repeat();
          }
        });
    } else if (widget.streakLabel == 'unstoppable' && !widget.isMilestone) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (widget.streakLabel) {
      'warming_up' => ('\u{1F525}', 'Warming Up', RackUpColors.playerAmber),
      'on_fire' => (
        '\u{1F525}\u{1F525}',
        'ON FIRE',
        RackUpColors.streakGold,
      ),
      'unstoppable' => (
        '\u{1F525}\u{1F525}\u{1F525}',
        'UNSTOPPABLE',
        RackUpColors.streakGold,
      ),
      _ => ('', '', RackUpColors.textSecondary),
    };

    if (emoji.isEmpty) return const SizedBox.shrink();

    final isUnstoppable = widget.streakLabel == 'unstoppable';

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textScaler: ClampedTextScaler.of(context, TextRole.body),
        ),
      ],
    );

    // Apply glow for on_fire and unstoppable.
    if (widget.streakLabel == 'on_fire' || isUnstoppable) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: RackUpColors.streakGold.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: content,
      );
    }

    // Apply animation.
    if (widget.isMilestone) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Semantics(label: label, child: content),
      );
    }

    if (isUnstoppable) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: Semantics(label: label, child: content),
      );
    }

    return Semantics(label: label, child: content);
  }
}
