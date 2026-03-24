import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Font family names used by the RackUp design system.
abstract final class RackUpFontFamilies {
  /// Display/headline font — Oswald.
  static const String display = 'Oswald';

  /// Referee/punishment text font — Barlow Condensed.
  static const String accent = 'BarlowCondensed';

  /// UI/body font — Barlow.
  static const String body = 'Barlow';
}

/// The 8-token type scale for the RackUp design system.
///
/// Uses Oswald for display/headlines, Barlow Condensed for referee/punishment
/// text, and Barlow for UI/body text.
///
/// Font families are registered via [buildTextTheme] at app startup.
abstract final class RackUpTypography {
  /// Display XL — 64dp, Oswald 700, line height 1.1.
  static const TextStyle displayXl = TextStyle(
    fontFamily: RackUpFontFamilies.display,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: RackUpColors.textPrimary,
  );

  /// Display LG — 48dp, Oswald 700, line height 1.1.
  static const TextStyle displayLg = TextStyle(
    fontFamily: RackUpFontFamilies.display,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: RackUpColors.textPrimary,
  );

  /// Display MD — 36dp, Oswald 600, line height 1.2.
  static const TextStyle displayMd = TextStyle(
    fontFamily: RackUpFontFamilies.display,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: RackUpColors.textPrimary,
  );

  /// Display SM — 32dp, Oswald 500, line height 1.2.
  static const TextStyle displaySm = TextStyle(
    fontFamily: RackUpFontFamilies.display,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: RackUpColors.textPrimary,
  );

  /// Heading — 24dp, Barlow Condensed 700, line height 1.3.
  static const TextStyle heading = TextStyle(
    fontFamily: RackUpFontFamilies.accent,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: RackUpColors.textPrimary,
  );

  /// Body LG — 20dp, Barlow 500, line height 1.4.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: RackUpFontFamilies.body,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: RackUpColors.textPrimary,
  );

  /// Body — 16dp, Barlow 400, line height 1.5.
  static const TextStyle body = TextStyle(
    fontFamily: RackUpFontFamilies.body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: RackUpColors.textPrimary,
  );

  /// Caption — 14dp, Barlow 400, line height 1.4.
  static const TextStyle caption = TextStyle(
    fontFamily: RackUpFontFamilies.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: RackUpColors.textPrimary,
  );

  /// Builds the complete [TextTheme] with Google Fonts loaded.
  ///
  /// Call this when constructing the app's [ThemeData] to ensure fonts are
  /// registered with the engine.
  static TextTheme buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.oswald(textStyle: displayXl),
      displayMedium: GoogleFonts.oswald(textStyle: displayLg),
      displaySmall: GoogleFonts.oswald(textStyle: displayMd),
      headlineLarge: GoogleFonts.oswald(textStyle: displaySm),
      headlineMedium: GoogleFonts.barlowCondensed(textStyle: heading),
      titleLarge: GoogleFonts.barlowCondensed(textStyle: heading),
      bodyLarge: GoogleFonts.barlow(textStyle: bodyLg),
      bodyMedium: GoogleFonts.barlow(textStyle: body),
      bodySmall: GoogleFonts.barlow(textStyle: caption),
    );
  }
}
