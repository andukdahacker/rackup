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
    with TickerProviderStateMixin {
  late final AnimationController _countdownController;
  late final AnimationController _fadeController;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // starts fully visible
    );
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_expired && mounted) {
        _expired = true;
        _fadeController.reverse().then((_) {
          if (mounted) widget.onExpired();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_countdownController, _fadeController]),
      builder: (context, child) {
        final remaining =
            (widget.duration.inSeconds * (1 - _countdownController.value))
                .ceil();
        return IgnorePointer(
          ignoring: _expired,
          child: Opacity(
            opacity: _fadeController.value,
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
                          value: 1 - _countdownController.value,
                          strokeWidth: 3,
                          color: RackUpColors.textSecondary,
                          backgroundColor: RackUpColors.textSecondary
                              .withValues(alpha: 0.2),
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
          ),
        );
      },
    );
  }
}
