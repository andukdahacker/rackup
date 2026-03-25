import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Text roles that determine maximum scale factors.
enum TextRole {
  /// Body text (14–20dp) — max scale 2.0x.
  body,

  /// Display/headings (32–64dp) — max scale 1.2x.
  display,

  /// Referee punishment text (20dp) — max scale 1.3x.
  refereePunishment,

  /// Button labels (28dp) — no scaling (1.0x).
  buttonLabel,

  /// Player name tag text — scales with body text.
  playerNameTag,

  /// Player name tag shape icon — no scaling (1.0x).
  playerNameTagIcon,
}

/// Maximum scale factors per [TextRole].
const Map<TextRole, double> _maxScaleFactors = {
  TextRole.body: 2.0,
  TextRole.display: 1.2,
  TextRole.refereePunishment: 1.3,
  TextRole.buttonLabel: 1.0,
  TextRole.playerNameTag: 2.0,
  TextRole.playerNameTagIcon: 1.0,
};

/// A [TextScaler] that clamps scaling to the maximum
/// allowed for a [TextRole].
class ClampedTextScaler implements TextScaler {
  /// Creates a clamped text scaler with the given
  /// [baseScaler] and [role].
  const ClampedTextScaler({
    required this.baseScaler,
    required this.role,
  });

  /// Creates a [ClampedTextScaler] for the given [role]
  /// using the platform's current text scaler from the
  /// [BuildContext].
  factory ClampedTextScaler.of(
    BuildContext context,
    TextRole role,
  ) {
    return ClampedTextScaler(
      baseScaler: MediaQuery.textScalerOf(context),
      role: role,
    );
  }

  /// The platform's text scaler (from [MediaQuery]).
  final TextScaler baseScaler;

  /// The text role that determines the max scale factor.
  final TextRole role;

  /// The maximum scale factor for this role.
  double get maxScaleFactor => _maxScaleFactors[role]!;

  @override
  double scale(double fontSize) {
    final scaledSize = baseScaler.scale(fontSize);
    final maxSize = fontSize * maxScaleFactor;
    return math.min(scaledSize, maxSize);
  }

  @override
  double get textScaleFactor {
    // Required by TextScaler interface, deprecated since
    // Flutter 3.12+ in favor of scale().
    // ignore: deprecated_member_use
    final baseFactor = baseScaler.textScaleFactor;
    return math.min(baseFactor, maxScaleFactor);
  }

  /// Returns a new [ClampedTextScaler] with the base scaler clamped to
  /// [minScaleFactor]–[maxScaleFactor]. The role's maximum scale factor still
  /// applies on top, so requesting a [minScaleFactor] above the role max will
  /// be silently capped to the role max.
  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = 10,
  }) {
    return ClampedTextScaler(
      baseScaler: baseScaler.clamp(
        minScaleFactor: minScaleFactor,
        maxScaleFactor: maxScaleFactor,
      ),
      role: role,
    );
  }
}
