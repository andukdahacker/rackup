import 'package:rackup/core/config/app_config.dart';

/// Staging flavor configuration — Railway staging URLs, Sentry enabled.
class StagingConfig implements AppConfig {
  /// Creates a [StagingConfig].
  const StagingConfig();

  @override
  // TODO(story-1.2): Replace with Railway staging URL
  String get apiBaseUrl => 'https://rackup-staging.up.railway.app';

  @override
  // TODO(story-1.2): Replace with Railway staging WebSocket URL
  String get wsBaseUrl => 'wss://rackup-staging.up.railway.app';

  @override
  bool get enableSentryLogging => true;

  @override
  // TODO(story-1.2): Replace with real Sentry DSN
  String get sentryDsn => '';
}
