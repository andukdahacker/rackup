import 'package:flutter/widgets.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// The four visual intensity tiers used during gameplay.
enum EscalationTier {
  /// Pre-game / lobby state.
  lobby,

  /// 0–30% game progression.
  mild,

  /// 30–70% game progression.
  medium,

  /// 70–100% game progression (triple points).
  spicy,
}

/// Read-only game theme data derived from game progression.
///
/// Provides escalation-aware visual properties (background color, tier) to
/// the entire widget tree via [InheritedWidget]. This is intentionally NOT a
/// Bloc — the value changes at most 4 times per game on tier transitions.
@immutable
class RackUpGameThemeData {
  const RackUpGameThemeData({
    required this.tier,
    required this.backgroundColor,
    required this.animationsEnabled,
  });

  /// The current escalation tier.
  final EscalationTier tier;

  /// The active background color for the current tier.
  final Color backgroundColor;

  /// Whether animations are enabled (false when reduced motion is on).
  final bool animationsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RackUpGameThemeData &&
          tier == other.tier &&
          backgroundColor == other.backgroundColor &&
          animationsEnabled == other.animationsEnabled;

  @override
  int get hashCode => Object.hash(tier, backgroundColor, animationsEnabled);

  /// Duration for tier color transitions.
  /// Returns [Duration.zero] when reduced motion is enabled.
  Duration get tierTransitionDuration =>
      animationsEnabled ? const Duration(milliseconds: 500) : Duration.zero;

  // ── Stubs for future stories ──

  /// Particle preset for the current tier. Placeholder for future stories.
  Object? get particlePreset => null;

  /// Glow intensity for the current tier. Placeholder for future stories.
  double? get glowIntensity => null;

  /// Copy intensity tier label. Placeholder for future stories.
  String? get copyIntensityTier => null;
}

/// InheritedWidget that propagates [RackUpGameThemeData] down the tree.
class RackUpGameTheme extends InheritedWidget {
  const RackUpGameTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The game theme data available to descendants.
  final RackUpGameThemeData data;

  /// Retrieves the nearest [RackUpGameThemeData] from the widget tree.
  ///
  /// Throws [FlutterError] if no [RackUpGameTheme] ancestor exists.
  static RackUpGameThemeData of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<RackUpGameTheme>();
    if (widget == null) {
      throw FlutterError(
        'RackUpGameTheme.of() called with a context that does not contain a '
        'RackUpGameTheme.\nNo RackUpGameTheme ancestor could be found starting '
        'from the context that was passed to RackUpGameTheme.of().',
      );
    }
    return widget.data;
  }

  /// Retrieves the nearest [RackUpGameThemeData], or null if none exists.
  static RackUpGameThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RackUpGameTheme>()
        ?.data;
  }

  @override
  bool updateShouldNotify(RackUpGameTheme oldWidget) => data != oldWidget.data;

  /// Returns the [EscalationTier] for a given game progression percentage.
  ///
  /// - 0% or lobby state → [EscalationTier.lobby]
  /// - 0–30% → [EscalationTier.mild]
  /// - 30–70% → [EscalationTier.medium]
  /// - 70–100% → [EscalationTier.spicy]
  static EscalationTier tierForProgression(double percentage) {
    if (percentage.isNaN || percentage <= 0) return EscalationTier.lobby;
    final clamped = percentage.clamp(0, 100).toDouble();
    if (clamped <= 30) return EscalationTier.mild;
    if (clamped <= 70) return EscalationTier.medium;
    return EscalationTier.spicy;
  }

  /// Returns the background color for a given [EscalationTier].
  static Color backgroundForTier(EscalationTier tier) {
    return switch (tier) {
      EscalationTier.lobby => RackUpColors.tierLobby,
      EscalationTier.mild => RackUpColors.tierMild,
      EscalationTier.medium => RackUpColors.tierMedium,
      EscalationTier.spicy => RackUpColors.tierSpicy,
    };
  }

  /// Creates [RackUpGameThemeData] from a game progression percentage and
  /// the platform's reduced-motion setting.
  static RackUpGameThemeData fromProgression({
    required double percentage,
    required bool animationsEnabled,
  }) {
    final tier = tierForProgression(percentage);
    return RackUpGameThemeData(
      tier: tier,
      backgroundColor: backgroundForTier(tier),
      animationsEnabled: animationsEnabled,
    );
  }
}
