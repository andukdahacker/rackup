import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: RackUpColors.canvas,
          colorScheme: const ColorScheme.dark(
            surface: RackUpColors.canvas,
            primary: RackUpColors.itemBlue,
            secondary: RackUpColors.missionPurple,
            error: RackUpColors.missedRed,
          ),
          textTheme: RackUpTypography.buildTextTheme(),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final disableAnimations =
                MediaQuery.of(context).disableAnimations;
            return RackUpGameTheme(
              data: RackUpGameThemeData(
                tier: EscalationTier.lobby,
                backgroundColor: RackUpColors.tierLobby,
                animationsEnabled: !disableAnimations,
              ),
              child: widget,
            );
          },
        ),
      ),
    );
  }
}
