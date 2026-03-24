import 'dart:ui';

import 'package:rackup/core/theme/rackup_colors.dart';

/// The geometric shapes used for player identification.
///
/// Each shape provides fully redundant identification alongside color,
/// ensuring accessibility for colorblind users.
enum PlayerShape {
  circle,
  square,
  triangle,
  diamond,
  star,
  hexagon,
  cross,
  pentagon,
}

/// A player identity combining a color and geometric shape.
///
/// The 8-slot system ensures every player has a unique color+shape combo.
class PlayerIdentity {
  const PlayerIdentity({
    required this.slot,
    required this.name,
    required this.color,
    required this.shape,
  });

  /// 1-based slot number.
  final int slot;

  /// Human-readable color name.
  final String name;

  /// The identity color.
  final Color color;

  /// The identity shape.
  final PlayerShape shape;

  /// All 8 player identity slots.
  static const List<PlayerIdentity> slots = [
    PlayerIdentity(
      slot: 1,
      name: 'Coral',
      color: RackUpColors.playerCoral,
      shape: PlayerShape.circle,
    ),
    PlayerIdentity(
      slot: 2,
      name: 'Cyan',
      color: RackUpColors.playerCyan,
      shape: PlayerShape.square,
    ),
    PlayerIdentity(
      slot: 3,
      name: 'Amber',
      color: RackUpColors.playerAmber,
      shape: PlayerShape.triangle,
    ),
    PlayerIdentity(
      slot: 4,
      name: 'Violet',
      color: RackUpColors.playerViolet,
      shape: PlayerShape.diamond,
    ),
    PlayerIdentity(
      slot: 5,
      name: 'Lime',
      color: RackUpColors.playerLime,
      shape: PlayerShape.star,
    ),
    PlayerIdentity(
      slot: 6,
      name: 'Sky',
      color: RackUpColors.playerSky,
      shape: PlayerShape.hexagon,
    ),
    PlayerIdentity(
      slot: 7,
      name: 'Rose',
      color: RackUpColors.playerRose,
      shape: PlayerShape.cross,
    ),
    PlayerIdentity(
      slot: 8,
      name: 'Mint',
      color: RackUpColors.playerMint,
      shape: PlayerShape.pentagon,
    ),
  ];

  /// Returns the [PlayerIdentity] for the given 1-based [slot].
  ///
  /// Throws [RangeError] if [slot] is not between 1 and 8.
  static PlayerIdentity forSlot(int slot) {
    RangeError.checkValueInInterval(slot, 1, 8, 'slot');
    return slots[slot - 1];
  }
}
