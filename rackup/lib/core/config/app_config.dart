/// Base configuration contract for all flavor environments.
abstract class AppConfig {
  /// HTTP endpoint for room create/join.
  String get apiBaseUrl;

  /// WebSocket endpoint.
  String get wsBaseUrl;

  /// Whether to enable Sentry error logging.
  bool get enableSentryLogging;

  /// Sentry DSN — empty string disables Sentry.
  String get sentryDsn;
}
