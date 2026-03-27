import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';

/// A single player row in the lobby player list.
///
/// Anatomy: color+shape identity tag (20dp) + player name (Oswald SemiBold 20dp)
/// + optional gold "HOST" badge + status indicator (right-aligned).
/// Slides in from left with 300ms animation and stagger delay, respecting reduced motion.
class PlayerListTile extends StatefulWidget {
  /// Creates a [PlayerListTile].
  const PlayerListTile({
    required this.player,
    this.staggerIndex = 0,
    super.key,
  });

  /// The player to display.
  final Player player;

  /// Index used for stagger delay (80ms per index).
  final int staggerIndex;

  @override
  State<PlayerListTile> createState() => _PlayerListTileState();
}

class _PlayerListTileState extends State<PlayerListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsEnabled =
        RackUpGameTheme.maybeOf(context)?.animationsEnabled ??
            !MediaQuery.of(context).disableAnimations;
    if (animationsEnabled) {
      final delay = Duration(milliseconds: 80 * widget.staggerIndex);
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final identity = PlayerIdentity.forSlot(player.slot);
    final statusText = _statusText(player.status);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Semantics(
          label: '${player.displayName}, $statusText'
              '${player.isHost ? ', Host' : ''}',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RackUpSpacing.spaceMd,
              vertical: RackUpSpacing.spaceSm,
            ),
            decoration: BoxDecoration(
              color: RackUpColors.tierLobby,
              borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
            ),
            child: Row(
              children: [
                // Color+shape identity tag.
                PlayerShapeWidget(
                  shape: identity.shape,
                  color: identity.color,
                  size: 20,
                ),
                const SizedBox(width: RackUpSpacing.spaceSm),
                // Player name (Oswald SemiBold 20dp).
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.displayName,
                          style: const TextStyle(
                            fontFamily: RackUpFontFamilies.display,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: RackUpColors.textPrimary,
                          ),
                          textScaler: ClampedTextScaler.of(
                            context,
                            TextRole.body,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.isHost) ...[
                        const SizedBox(width: RackUpSpacing.spaceXs),
                        Text(
                          'HOST',
                          style: const TextStyle(
                            fontFamily: RackUpFontFamilies.display,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: RackUpColors.streakGold,
                            letterSpacing: 1,
                          ),
                          textScaler: ClampedTextScaler.of(
                            context,
                            TextRole.body,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status indicator.
                Text(
                  statusText,
                  style: RackUpTypography.caption.copyWith(
                    color: _statusColor(player.status),
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusText(PlayerStatus status) {
    return switch (status) {
      PlayerStatus.joining => 'Joining...',
    };
  }

  static Color _statusColor(PlayerStatus status) {
    return switch (status) {
      PlayerStatus.joining => RackUpColors.textSecondary,
    };
  }
}
