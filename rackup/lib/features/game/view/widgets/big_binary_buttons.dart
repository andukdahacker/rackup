import 'package:flutter/material.dart';

/// Two side-by-side buttons for MADE (green) / MISSED (red) shot confirmation.
///
/// UX spec: Oswald Bold 28dp uppercase, minimum 100dp height, 32dp horizontal
/// margin, breathing pulse animation on idle, 97% scale on press.
class BigBinaryButtons extends StatefulWidget {
  const BigBinaryButtons({
    required this.onMade,
    required this.onMissed,
    super.key,
  });

  /// Called when the referee taps MADE.
  final VoidCallback onMade;

  /// Called when the referee taps MISSED.
  final VoidCallback onMissed;

  @override
  State<BigBinaryButtons> createState() => _BigBinaryButtonsState();
}

class _BigBinaryButtonsState extends State<BigBinaryButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Row(
          children: [
            Expanded(
              child: _ShotButton(
                label: 'MADE',
                color: const Color(0xFF22C55E),
                semanticLabel: 'Confirm shot made',
                onTap: widget.onMade,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ShotButton(
                label: 'MISSED',
                color: const Color(0xFFEF4444),
                semanticLabel: 'Confirm shot missed',
                onTap: widget.onMissed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShotButton extends StatefulWidget {
  const _ShotButton({
    required this.label,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_ShotButton> createState() => _ShotButtonState();
}

class _ShotButtonState extends State<_ShotButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.color,
                  widget.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                color: Colors.white,
              ),
              textScaler: TextScaler.noScaling,
            ),
          ),
        ),
      ),
    );
  }
}
