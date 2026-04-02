import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';

/// Size variants for the [PlayerNameTag] widget.
enum PlayerNameTagSize {
  /// Compact: 12dp shape, 13dp name.
  compact(shapeSize: 12, fontSize: 13),

  /// Standard: 16dp shape, 16dp name.
  standard(shapeSize: 16, fontSize: 16),

  /// Leaderboard: 16dp shape, 16dp name (Oswald SemiBold).
  leaderboard(shapeSize: 16, fontSize: 16),

  /// Large: 24dp shape, 42dp name (Oswald).
  large(shapeSize: 24, fontSize: 42);

  const PlayerNameTagSize({required this.shapeSize, required this.fontSize});

  /// The shape widget size.
  final double shapeSize;

  /// The name text font size.
  final double fontSize;
}

/// Visual state for the [PlayerNameTag].
enum PlayerNameTagState {
  /// Default appearance.
  normal,

  /// Highlighted (self — blue tint).
  highlighted,

  /// Dimmed (disconnected — 40% opacity).
  dimmed,
}

/// A reusable player name tag showing identity shape + color + name.
///
/// Uses [PlayerIdentity.forSlot] for color and [PlayerShapeWidget] for shape.
class PlayerNameTag extends StatelessWidget {
  const PlayerNameTag({
    required this.displayName,
    required this.slot,
    this.size = PlayerNameTagSize.standard,
    this.tagState = PlayerNameTagState.normal,
    super.key,
  });

  /// The player's display name.
  final String displayName;

  /// The player's 1-based slot (1–8).
  final int slot;

  /// Size variant.
  final PlayerNameTagSize size;

  /// Visual state.
  final PlayerNameTagState tagState;

  bool get _useOswald =>
      size == PlayerNameTagSize.leaderboard || size == PlayerNameTagSize.large;

  @override
  Widget build(BuildContext context) {
    final identity = PlayerIdentity.forSlot(slot);
    final opacity = tagState == PlayerNameTagState.dimmed ? 0.4 : 1.0;

    final content = Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerShapeWidget(
            shape: identity.shape,
            color: identity.color,
            size: size.shapeSize,
          ),
          SizedBox(width: size == PlayerNameTagSize.large ? 12 : 8),
          Flexible(
            child: Text(
              displayName,
              style: _useOswald
                  ? GoogleFonts.oswald(
                      fontSize: size.fontSize,
                      fontWeight: FontWeight.w600,
                      color: identity.color,
                    )
                  : TextStyle(
                      fontSize: size.fontSize,
                      fontWeight: FontWeight.normal,
                      color: identity.color,
                    ),
              overflow: TextOverflow.ellipsis,
              textScaler: ClampedTextScaler.of(
                context,
                TextRole.playerNameTag,
              ),
            ),
          ),
        ],
      ),
    );

    final widget = tagState == PlayerNameTagState.highlighted
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RackUpColors.itemBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: content,
          )
        : content;

    return Semantics(
      label:
          '$displayName, ${identity.name.toLowerCase()} ${identity.shape.name}',
      child: widget,
    );
  }
}
