import 'package:flutter/material.dart';

/// Domain model for a power-up item.
class Item {
  /// Creates an [Item].
  const Item({
    required this.type,
    required this.displayName,
    required this.accentColorHex,
    required this.iconData,
    required this.requiresTarget,
  });

  /// The item type key (e.g., "blue_shell").
  final String type;

  /// Human-readable name (e.g., "Blue Shell").
  final String displayName;

  /// Hex color string for the accent (e.g., "#3B82F6").
  final String accentColorHex;

  /// Material icon for display.
  final IconData iconData;

  /// Whether this item requires a target player on deployment.
  final bool requiresTarget;

  /// Accent color as a [Color].
  Color get accentColor {
    final hex = accentColorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Registry of all 10 item types.
  static const Map<String, Item> registry = {
    'blue_shell': Item(
      type: 'blue_shell',
      displayName: 'Blue Shell',
      accentColorHex: '#3B82F6',
      iconData: Icons.gps_fixed,
      requiresTarget: true,
    ),
    'shield': Item(
      type: 'shield',
      displayName: 'Shield',
      accentColorHex: '#14B8A6',
      iconData: Icons.shield,
      requiresTarget: false,
    ),
    'score_steal': Item(
      type: 'score_steal',
      displayName: 'Score Steal',
      accentColorHex: '#FF6B6B',
      iconData: Icons.swap_horiz,
      requiresTarget: true,
    ),
    'streak_breaker': Item(
      type: 'streak_breaker',
      displayName: 'Streak Breaker',
      accentColorHex: '#F97316',
      iconData: Icons.flash_off,
      requiresTarget: true,
    ),
    'double_up': Item(
      type: 'double_up',
      displayName: 'Double Up',
      accentColorHex: '#FFD700',
      iconData: Icons.double_arrow,
      requiresTarget: false,
    ),
    'trap_card': Item(
      type: 'trap_card',
      displayName: 'Trap Card',
      accentColorHex: '#DC2626',
      iconData: Icons.warning,
      requiresTarget: false,
    ),
    'reverse': Item(
      type: 'reverse',
      displayName: 'Reverse',
      accentColorHex: '#8B5CF6',
      iconData: Icons.swap_vert,
      requiresTarget: true,
    ),
    'immunity': Item(
      type: 'immunity',
      displayName: 'Immunity',
      accentColorHex: '#10B981',
      iconData: Icons.health_and_safety,
      requiresTarget: false,
    ),
    'mulligan': Item(
      type: 'mulligan',
      displayName: 'Mulligan',
      accentColorHex: '#60A5FA',
      iconData: Icons.refresh,
      requiresTarget: false,
    ),
    'wildcard': Item(
      type: 'wildcard',
      displayName: 'Wildcard',
      accentColorHex: '#EAB308',
      iconData: Icons.star,
      requiresTarget: false,
    ),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Item && type == other.type;

  @override
  int get hashCode => type.hashCode;
}
