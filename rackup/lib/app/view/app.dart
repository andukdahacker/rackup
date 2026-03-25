import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/routing/app_router.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/l10n/l10n.dart';

/// The root application widget.
class App extends StatelessWidget {
  /// Creates an [App] with the given [config] and [deviceIdentityService].
  const App({
    required this.config,
    required this.deviceIdentityService,
    super.key,
  });

  /// The environment configuration for this flavor.
  final AppConfig config;

  /// The device identity service for anonymous device identification.
  final DeviceIdentityService deviceIdentityService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: config),
        RepositoryProvider<DeviceIdentityService>.value(
          value: deviceIdentityService,
        ),
        RepositoryProvider<RoomApiService>(
          create: (_) => RoomApiService(apiBaseUrl: config.apiBaseUrl),
        ),
      ],
      child: MaterialApp.router(
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
        routerConfig: appRouter,
        builder: (context, child) {
          final disableAnimations =
              MediaQuery.of(context).disableAnimations;
          return RackUpGameTheme(
            data: RackUpGameTheme.fromProgression(
              percentage: 0,
              animationsEnabled: !disableAnimations,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
