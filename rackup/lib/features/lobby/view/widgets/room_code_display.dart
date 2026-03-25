import 'package:flutter/material.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';

/// Prominently displays a room code with gold Oswald typography.
class RoomCodeDisplay extends StatelessWidget {
  /// Creates a [RoomCodeDisplay].
  const RoomCodeDisplay({required this.roomCode, super.key});

  /// The 4-character room code to display.
  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return Text(
      roomCode,
      style: RackUpTypography.displayMd.copyWith(
        color: RackUpColors.streakGold,
        letterSpacing: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}
