import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Full-screen overlay announcing triple-point activation.
///
/// Uses "The Eruption" animation pattern: scale 1.0 → 1.4 → 1.0 (300ms)
/// on the "3X" text, with a gold radial glow. Auto-dismisses after a
/// 2-second hold.
class TriplePointsOverlay extends StatefulWidget {
  const TriplePointsOverlay({
    required this.onDismissed,
    super.key,
  });

  /// Called when the overlay animation completes.
  final VoidCallback onDismissed;

  @override
  State<TriplePointsOverlay> createState() => _TriplePointsOverlayState();
}

class _TriplePointsOverlayState extends State<TriplePointsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _eruption;

  @override
  void initState() {
    super.initState();

    final disableAnimations = WidgetsBinding.instance.platformDispatcher
        .accessibilityFeatures.disableAnimations;

    if (disableAnimations) {
      // Reduced motion: show briefly then dismiss.
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _opacity = const AlwaysStoppedAnimation<double>(1.0);
      _eruption = const AlwaysStoppedAnimation<double>(1.0);
      _controller.forward();
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onDismissed();
        }
      });
      return;
    }

    // 300ms fade-in + 300ms eruption + 1700ms hold + 300ms fade-out = 2600ms.
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

    // Eruption: scale 1.0 → 1.4 → 1.0 during the first 600ms.
    _eruption = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 2000,
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
    return Semantics(
      label: 'Triple points activated',
      liveRegion: true,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          color: RackUpColors.canvas.withValues(alpha: 0.9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TRIPLE POINTS',
                  style: GoogleFonts.oswald(
                    fontWeight: FontWeight.w700,
                    fontSize: 42,
                    color: RackUpColors.streakGold,
                  ),
                  textAlign: TextAlign.center,
                  textScaler:
                      ClampedTextScaler.of(context, TextRole.display),
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _eruption,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: RackUpColors.streakGold.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '3X',
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.w700,
                        fontSize: 64,
                        color: RackUpColors.streakGold,
                      ),
                      textAlign: TextAlign.center,
                      textScaler: ClampedTextScaler.of(
                        context,
                        TextRole.display,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
