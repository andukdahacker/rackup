import 'package:flutter/material.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Referee punishment announcement card — teleprompter-style display.
///
/// Shows "THE POOL GODS HAVE SPOKEN" header (tier-aware), tier badge,
/// punishment text, and a "PUNISHMENT DELIVERED" button.
/// Uses The Reveal animation: anticipation beat + scale-up payoff.
class PunishmentAnnouncementCard extends StatefulWidget {
  const PunishmentAnnouncementCard({
    required this.punishment,
    required this.onDelivered,
    super.key,
  });

  /// The punishment payload with text and tier.
  final PunishmentPayload punishment;

  /// Called when the referee taps "PUNISHMENT DELIVERED".
  final VoidCallback onDelivered;

  @override
  State<PunishmentAnnouncementCard> createState() =>
      _PunishmentAnnouncementCardState();
}

class _PunishmentAnnouncementCardState extends State<PunishmentAnnouncementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // The Reveal: 150ms anticipation (scale to 0.95) + 250ms payoff (to 1.0).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95),
        weight: 37.5, // ~150ms of 400ms
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 62.5, // ~250ms of 400ms
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header — tier-aware copy.
            Text(
              _headerText(widget.punishment.tier),
              style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _headerColor(widget.punishment.tier),
              ),
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
            ),
            const SizedBox(height: 12),
            // Tier badge.
            _TierBadge(tier: widget.punishment.tier),
            const SizedBox(height: 16),
            // Punishment text — teleprompter style.
            Text(
              widget.punishment.text,
              style: TextStyle(
                fontFamily: 'BarlowCondensed',
                fontWeight: FontWeight.w700,
                fontSize: widget.punishment.text.length > 80 ? 18 : 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
            ),
            const SizedBox(height: 20),
            // Delivered button.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onDelivered,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: RackUpColors.textSecondary,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'PUNISHMENT DELIVERED',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: RackUpColors.textSecondary,
                  ),
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _headerText(String tier) {
    return switch (tier) {
      'mild' => 'THE POOL GODS HAVE SPOKEN',
      'medium' => 'THE POOL GODS HAVE SPOKEN!',
      'spicy' => 'THE POOL GODS DEMAND SACRIFICE',
      _ => 'THE POOL GODS HAVE SPOKEN', // custom and fallback
    };
  }

  static Color _headerColor(String tier) {
    return switch (tier) {
      'spicy' => const Color(0xFFFFE4B5), // gold tint for dramatic effect
      _ => const Color(0xFFF0EDF6), // off-white default
    };
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _tierColors(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Barlow',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: textColor,
        ),
        textScaler: TextScaler.noScaling,
      ),
    );
  }

  static (Color, Color) _tierColors(String tier) {
    return switch (tier) {
      'mild' => (const Color(0xFF616161), const Color(0xFFF0EDF6)),
      'medium' => (const Color(0xFFF59E0B), const Color(0xFF1A1832)),
      'spicy' => (const Color(0xFFEF4444), Colors.white),
      'custom' => (const Color(0xFFA855F7), Colors.white),
      _ => (const Color(0xFF616161), const Color(0xFFF0EDF6)),
    };
  }
}
