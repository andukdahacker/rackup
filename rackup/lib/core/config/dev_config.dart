import 'package:rackup/core/config/app_config.dart';

/// Development flavor configuration — localhost, no Sentry.
class DevConfig implements AppConfig {
  /// Creates a [DevConfig].
  const DevConfig();

  @override
  String get apiBaseUrl => 'http://localhost:8080';

  @override
  String get wsBaseUrl => 'ws://localhost:8080';

  @override
  bool get enableSentryLogging => false;

  @override
  String get sentryDsn => '';
}
