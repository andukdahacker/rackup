import 'package:flutter/material.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Full-screen overlay that reveals the referee role assignment.
///
/// Shows microphone emoji, "YOU'RE THE REFEREE NOW" text, referee's name
/// in their identity color, and a gold horizontal rule. Auto-dismisses
/// after a fade-in (300ms) + hold (2s) + fade-out (300ms) sequence.
class RoleRevealOverlay extends StatefulWidget {
  const RoleRevealOverlay({
    required this.refereeName,
    required this.refereeSlot,
    required this.onDismissed,
    super.key,
  });

  /// The referee's display name.
  final String refereeName;

  /// The referee's 1-based slot for identity color.
  final int refereeSlot;

  /// Called when the overlay animation completes.
  final VoidCallback onDismissed;

  @override
  State<RoleRevealOverlay> createState() => _RoleRevealOverlayState();
}

class _RoleRevealOverlayState extends State<RoleRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    final disableAnimations = WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    if (disableAnimations) {
      // Skip animation entirely — show briefly then dismiss.
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (mounted) widget.onDismissed();
      });
      _controller = AnimationController(
        vsync: this,
        duration: Duration.zero,
      );
      _opacity = const AlwaysStoppedAnimation<double>(1.0);
      return;
    }

    // 300ms fade-in + 2000ms hold + 300ms fade-out = 2600ms total.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 2000,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = PlayerIdentity.forSlot(widget.refereeSlot);

    return Semantics(
      label: 'You are the referee now',
      liveRegion: true,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          color: RackUpColors.canvas,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎤',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  "YOU'RE THE REFEREE NOW",
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w700,
                    fontSize: 42,
                    color: RackUpColors.streakGold,
                  ),
                  textAlign: TextAlign.center,
                  textScaler: ClampedTextScaler.of(context, TextRole.display),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.refereeName,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                    color: identity.color,
                  ),
                  textAlign: TextAlign.center,
                  textScaler: ClampedTextScaler.of(context, TextRole.display),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 2,
                  color: RackUpColors.streakGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
