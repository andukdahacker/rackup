import 'package:flutter/material.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// A 48x48dp undo button with a shrinking ring countdown animation (5 seconds).
///
/// Subdued styling (Tier 3 action). Fades to 0% opacity when the countdown
/// expires and calls [onExpired].
class UndoButton extends StatefulWidget {
  const UndoButton({
    required this.onUndo,
    required this.onExpired,
    this.duration = const Duration(seconds: 5),
    super.key,
  });

  /// Called when the referee taps the undo button.
  final VoidCallback onUndo;

  /// Called when the countdown expires.
  final VoidCallback onExpired;

  /// Countdown duration (default 5 seconds).
  final Duration duration;

  @override
  State<UndoButton> createState() => _UndoButtonState();
}

class _UndoButtonState extends State<UndoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_expired && mounted) {
        _expired = true;
        widget.onExpired();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining =
            (widget.duration.inSeconds * (1 - _controller.value)).ceil();
        return Opacity(
          opacity: _expired ? 0.0 : 1.0,
          child: Semantics(
            button: true,
            label: 'Undo last shot, $remaining seconds remaining',
            liveRegion: true,
            child: GestureDetector(
              onTap: _expired ? null : widget.onUndo,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shrinking ring countdown.
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: 1 - _controller.value,
                        strokeWidth: 3,
                        color: RackUpColors.textSecondary,
                        backgroundColor:
                            RackUpColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    // Undo icon.
                    const Icon(
                      Icons.undo,
                      color: RackUpColors.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
