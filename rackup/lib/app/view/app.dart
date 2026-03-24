import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/routing/app_router.dart';
import 'package:rackup/l10n/l10n.dart';

/// The root application widget.
class App extends StatelessWidget {
  /// Creates an [App] with the given [config].
  const App({required this.config, super.key});

  /// The environment configuration for this flavor.
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppConfig>.value(
      value: config,
      child: MaterialApp.router(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
