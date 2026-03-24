import 'package:rackup/core/config/app_config.dart';

/// Production flavor configuration — Railway production URLs, Sentry enabled.
class ProdConfig implements AppConfig {
  /// Creates a [ProdConfig].
  const ProdConfig();

  @override
  // TODO(deploy): Replace with actual Railway production URL after deployment
  String get apiBaseUrl => 'https://rackup.up.railway.app';

  @override
  // TODO(deploy): Replace with actual Railway production
  // WebSocket URL after deployment
  String get wsBaseUrl => 'wss://rackup.up.railway.app';

  @override
  bool get enableSentryLogging => sentryDsn.isNotEmpty;

  @override
  // TODO(sentry): Replace with real Sentry DSN when Sentry is integrated
  String get sentryDsn => '';
}
