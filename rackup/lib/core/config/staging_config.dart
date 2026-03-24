import 'package:rackup/core/config/app_config.dart';

/// Staging flavor configuration — Railway staging URLs, Sentry enabled.
class StagingConfig implements AppConfig {
  /// Creates a [StagingConfig].
  const StagingConfig();

  @override
  // TODO(deploy): Replace with actual Railway staging URL after provisioning
  String get apiBaseUrl => 'https://rackup-staging.up.railway.app';

  @override
  // TODO(deploy): Replace with actual Railway staging
  // WebSocket URL after provisioning
  String get wsBaseUrl => 'wss://rackup-staging.up.railway.app';

  @override
  bool get enableSentryLogging => sentryDsn.isNotEmpty;

  @override
  // TODO(sentry): Replace with real Sentry DSN when Sentry is integrated
  String get sentryDsn => '';
}
