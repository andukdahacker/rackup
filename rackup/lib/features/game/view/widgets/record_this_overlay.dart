import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Full-screen overlay for "RECORD THIS" moments.
///
/// Shows a camera emoji with pulsing border, "RECORD THIS" text,
/// descriptive subtext, and tier badge. Uses storm-pause visual:
/// dimmed background + single red edge pulse. Auto-dismisses after ~4s.
class RecordThisOverlay extends StatefulWidget {
  const RecordThisOverlay({
    required this.onDismissed,
    required this.subtext,
    this.tierLabel = '',
    super.key,
  });

  /// Called when the overlay finishes and should be removed.
  final VoidCallback onDismissed;

  /// Descriptive text explaining what's about to happen.
  final String subtext;

  /// Current tier label (e.g., "Mild", "Medium", "Spicy").
  final String tierLabel;

  @override
  State<RecordThisOverlay> createState() => _RecordThisOverlayState();
}

class _RecordThisOverlayState extends State<RecordThisOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _cameraPulse;
  late final Animation<double> _edgePulse;
  late final Animation<double> _eruption;

  bool get _reducedMotion => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void initState() {
    super.initState();

    if (_reducedMotion) {
      // Reduced motion: static overlay for 1s, brief red edge flash.
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _opacity = const AlwaysStoppedAnimation<double>(1.0);
      _cameraPulse = const AlwaysStoppedAnimation<double>(1.0);
      // Brief flash at start (0-20% of timeline).
      _edgePulse = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
      ]).animate(_controller);
      _eruption = const AlwaysStoppedAnimation<double>(1.0);
      _controller.forward();
      _controller.addStatusListener(_onComplete);
      return;
    }

    // Full animation: ~4000ms total.
    // 300ms fade-in + 600ms edge pulse + 2500ms hold + 300ms eruption + 300ms fade-out.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Fade in, hold, eruption out.
    _opacity = TweenSequence<double>([
      // 0–300ms: fade in.
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      // 300–3400ms: hold.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3100),
      // 3400–4000ms: eruption fade-out.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 600,
      ),
    ]).animate(_controller);

    // Camera emoji pulse: repeating 1.0 → 1.15 → 1.0 over 800ms loop.
    // Approximated as 5 cycles within the hold window.
    _cameraPulse = TweenSequence<double>([
      // Fade-in phase: no pulse.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 300),
      // 5 pulse cycles (800ms each = 4000ms, scaled to weight 3100).
      for (int i = 0; i < 5; i++) ...[
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 310,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 310,
        ),
      ],
      // Eruption phase.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 600),
    ]).animate(_controller);

    // Red edge pulse: single 600ms flash starting at 300ms.
    _edgePulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 300),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 3100),
    ]).animate(_controller);

    // Eruption: scale 1.0 → 1.3 → 0 in the last 600ms.
    _eruption = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3400),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 150,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 450,
      ),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener(_onComplete);
  }

  void _onComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _tierColor() {
    return switch (widget.tierLabel.toLowerCase()) {
      'mild' => const Color(0xFF14B8A6), // teal
      'medium' => const Color(0xFFF59E0B), // amber
      'spicy' => RackUpColors.missedRed,
      _ => RackUpColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Record this moment: ${widget.subtext}',
      liveRegion: true,
      child: FadeTransition(
        opacity: _opacity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Dimmed background (storm pause).
                Container(
                  color: RackUpColors.canvas.withValues(alpha: 0.85),
                ),
                // Red edge pulse border.
                if (_edgePulse.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: RackUpColors.missedRed
                                .withValues(alpha: _edgePulse.value),
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Content.
                Center(
                  child: ScaleTransition(
                    scale: _eruption,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Camera emoji with pulsing border.
                        ScaleTransition(
                          scale: _cameraPulse,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: RackUpColors.missedRed,
                                width: 3,
                              ),
                            ),
                            child: const Text(
                              '\u{1F4F7}',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // "RECORD THIS" text.
                        Text(
                          'RECORD THIS',
                          style: GoogleFonts.oswald(
                            fontWeight: FontWeight.w700,
                            fontSize: 36,
                            color: RackUpColors.missedRed,
                          ),
                          textAlign: TextAlign.center,
                          textScaler:
                              ClampedTextScaler.of(context, TextRole.display),
                        ),
                        const SizedBox(height: 12),
                        // Descriptive subtext.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            widget.subtext,
                            style: GoogleFonts.barlow(
                              fontSize: 16,
                              color: RackUpColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            textScaler:
                                ClampedTextScaler.of(context, TextRole.body),
                          ),
                        ),
                        // Tier badge.
                        if (widget.tierLabel.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _tierColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _tierColor().withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              widget.tierLabel,
                              style: GoogleFonts.barlow(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _tierColor(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
