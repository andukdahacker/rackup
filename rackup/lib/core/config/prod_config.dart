import 'package:rackup/core/config/app_config.dart';

/// Production flavor configuration — Railway production URLs, Sentry enabled.
class ProdConfig implements AppConfig {
  /// Creates a [ProdConfig].
  const ProdConfig();

  @override
  // TODO(story-1.2): Replace with Railway production URL
  String get apiBaseUrl => 'https://rackup.up.railway.app';

  @override
  // TODO(story-1.2): Replace with Railway production WebSocket URL
  String get wsBaseUrl => 'wss://rackup.up.railway.app';

  @override
  bool get enableSentryLogging => true;

  @override
  // TODO(story-1.2): Replace with real Sentry DSN
  String get sentryDsn => '';
}
