import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/config/dev_config.dart';
import 'package:rackup/core/config/prod_config.dart';
import 'package:rackup/core/config/staging_config.dart';

void main() {
  group('DevConfig', () {
    const config = DevConfig();

    test('apiBaseUrl points to localhost', () {
      expect(config.apiBaseUrl, 'http://localhost:8080');
    });

    test('wsBaseUrl points to localhost', () {
      expect(config.wsBaseUrl, 'ws://localhost:8080');
    });

    test('Sentry logging is disabled', () {
      expect(config.enableSentryLogging, isFalse);
    });

    test('sentryDsn is empty', () {
      expect(config.sentryDsn, isEmpty);
    });

    test('implements AppConfig', () {
      expect(config, isA<AppConfig>());
    });
  });

  group('StagingConfig', () {
    const config = StagingConfig();

    test('apiBaseUrl uses https', () {
      expect(config.apiBaseUrl, startsWith('https://'));
    });

    test('wsBaseUrl uses wss', () {
      expect(config.wsBaseUrl, startsWith('wss://'));
    });

    test('Sentry logging is enabled', () {
      expect(config.enableSentryLogging, isTrue);
    });

    test('implements AppConfig', () {
      expect(config, isA<AppConfig>());
    });
  });

  group('ProdConfig', () {
    const config = ProdConfig();

    test('apiBaseUrl uses https', () {
      expect(config.apiBaseUrl, startsWith('https://'));
    });

    test('wsBaseUrl uses wss', () {
      expect(config.wsBaseUrl, startsWith('wss://'));
    });

    test('Sentry logging is enabled', () {
      expect(config.enableSentryLogging, isTrue);
    });

    test('implements AppConfig', () {
      expect(config, isA<AppConfig>());
    });
  });
}
