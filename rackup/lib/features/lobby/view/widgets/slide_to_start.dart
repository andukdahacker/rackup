import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// A slide-to-start component that requires the user to drag a thumb past
/// a 70% threshold to trigger the game start.
class SlideToStart extends StatefulWidget {
  /// Creates a [SlideToStart].
  const SlideToStart({
    required this.enabled,
    required this.onStart,
    super.key,
  });

  /// Whether the component is interactive.
  final bool enabled;

  /// Called when the slide threshold (70%) is reached or long-press (3s)
  /// completes.
  final VoidCallback onStart;

  @override
  State<SlideToStart> createState() => _SlideToStartState();
}

class _SlideToStartState extends State<SlideToStart>
    with SingleTickerProviderStateMixin {
  double _dragFraction = 0.0;
  bool _triggered = false;
  Timer? _longPressTimer;
  Timer? _resetTimer;
  late final AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  static const _trackHeight = 52.0;
  static const _thumbSize = 44.0;
  static const _threshold = 0.7;
  static const _longPressDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _resetTimer?.cancel();
    _snapBackController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.enabled || _triggered) return;
    if (maxDrag <= 0) return;
    setState(() {
      _dragFraction =
          (_dragFraction + details.delta.dx / maxDrag).clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enabled || _triggered) return;
    if (_dragFraction >= _threshold) {
      _trigger();
    } else {
      _snapBack();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.enabled || _triggered) return;
    _longPressTimer = Timer(_longPressDuration, _trigger);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _trigger() {
    if (_triggered) return;
    _triggered = true;
    _longPressTimer?.cancel();
    HapticFeedback.mediumImpact();
    widget.onStart();
    // Auto-reset if navigation doesn't occur (e.g., server rejected the start).
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _triggered = false;
          _dragFraction = 0.0;
        });
      }
    });
  }

  void _snapBack() {
    final from = _dragFraction;
    _snapBackAnimation = Tween<double>(begin: from, end: 0).animate(
      CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() {
          _dragFraction = _snapBackAnimation.value;
        });
      });
    _snapBackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Slide to start game. Long press for 3 seconds as alternative.',
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final maxDrag = trackWidth - _thumbSize - 8; // 4px padding each side

            return GestureDetector(
              onHorizontalDragUpdate: widget.enabled
                  ? (d) => _onHorizontalDragUpdate(d, maxDrag)
                  : null,
              onHorizontalDragEnd:
                  widget.enabled ? _onHorizontalDragEnd : null,
              onLongPressStart:
                  widget.enabled ? _onLongPressStart : null,
              onLongPressEnd: widget.enabled ? _onLongPressEnd : null,
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: RackUpColors.tierLobby,
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Green fill behind thumb.
                    if (_dragFraction > 0)
                      Positioned(
                        left: 0,
                        child: Container(
                          width:
                              4 + _thumbSize + (_dragFraction * maxDrag),
                          height: _trackHeight,
                          decoration: BoxDecoration(
                            color: RackUpColors.madeGreen
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(
                              _trackHeight / 2,
                            ),
                          ),
                        ),
                      ),
                    // Shimmer overlay for active state.
                    if (widget.enabled && !disableAnimations)
                      const Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(_trackHeight / 2),
                          ),
                          child: _ShimmerOverlay(),
                        ),
                      ),
                    // Track text.
                    Center(
                      child: Text(
                        'SLIDE TO START GAME',
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: RackUpColors.textSecondary,
                        ),
                        textScaler:
                            ClampedTextScaler.of(context, TextRole.body),
                      ),
                    ),
                    // Draggable thumb.
                    Positioned(
                      left: 4 + (_dragFraction * maxDrag),
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              RackUpColors.madeGreen,
                              Color(0xFF0D8A3A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerOverlay extends StatefulWidget {
  const _ShimmerOverlay();

  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 3.0 * _controller.value, 0),
              end: Alignment(0.0 + 3.0 * _controller.value, 0),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(color: Colors.white.withValues(alpha: 0.01)),
        );
      },
    );
  }
}
