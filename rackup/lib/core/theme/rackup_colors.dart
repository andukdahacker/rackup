import 'dart:ui';

/// All color constants for the RackUp design system.
///
/// Colors are organized into semantic groups: base canvas, semantic indicators,
/// escalation tiers, and player identity slots.
abstract final class RackUpColors {
  // ── Base Canvas ──
  /// Dark base canvas with purple undertone (#0F0E1A).
  static const Color canvas = Color(0xFF0F0E1A);

  // ── Semantic Colors ──
  /// Green — made/success (#16A34A).
  static const Color madeGreen = Color(0xFF16A34A);

  /// Red — missed/danger (#EF4444).
  static const Color missedRed = Color(0xFFEF4444);

  /// Gold — streak/achievement (#FFD700).
  static const Color streakGold = Color(0xFFFFD700);

  /// Electric Blue — items/power (#3B82F6).
  static const Color itemBlue = Color(0xFF3B82F6);

  /// Purple — missions/secret (#A855F7).
  static const Color missionPurple = Color(0xFFA855F7);

  /// Off-White — primary text (#F0EDF6).
  static const Color textPrimary = Color(0xFFF0EDF6);

  /// Muted Lavender — secondary text (#8B85A1).
  static const Color textSecondary = Color(0xFF8B85A1);

  // ── Escalation Tier Backgrounds ──
  /// Lobby tier — deep indigo (#1A1832).
  static const Color tierLobby = Color(0xFF1A1832);

  /// Mild tier (0–30%) — cool teal-blue (#0D2B3E).
  static const Color tierMild = Color(0xFF0D2B3E);

  /// Medium tier (30–70%) — warm amber-brown (#3D2008).
  static const Color tierMedium = Color(0xFF3D2008);

  /// Spicy/Triple tier (70–100%) — hot deep red (#3D0A0A).
  static const Color tierSpicy = Color(0xFF3D0A0A);

  /// Spicy tier accent — gold (#FFD700), used for highlights in the spicy tier.
  static const Color tierSpicyAccent = streakGold;

  // ── Player Identity Colors ──
  /// Slot 1 — Coral (#FF6B6B).
  static const Color playerCoral = Color(0xFFFF6B6B);

  /// Slot 2 — Cyan (#4ECDC4).
  static const Color playerCyan = Color(0xFF4ECDC4);

  /// Slot 3 — Amber (#FFB347).
  static const Color playerAmber = Color(0xFFFFB347);

  /// Slot 4 — Violet (#9B59B6).
  static const Color playerViolet = Color(0xFF9B59B6);

  /// Slot 5 — Lime (#A8E06C).
  static const Color playerLime = Color(0xFFA8E06C);

  /// Slot 6 — Sky (#74B9FF).
  static const Color playerSky = Color(0xFF74B9FF);

  /// Slot 7 — Rose (#FD79A8).
  static const Color playerRose = Color(0xFFFD79A8);

  /// Slot 8 — Mint (#55E6C1).
  static const Color playerMint = Color(0xFF55E6C1);

  // ── Item / Overlay ──
  /// Item gold — used for deploy press, deploying flash, Blue Shell crosshair (#FFD700).
  /// Alias of [streakGold] for semantic clarity in item code paths.
  static const Color itemGold = streakGold;

  /// Targeting overlay sheet background (alias of [tierLobby]).
  static const Color overlayBackground = tierLobby;
}
