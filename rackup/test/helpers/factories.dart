import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/config/dev_config.dart';

/// Creates a default [AppConfig] for testing.
AppConfig createTestConfig() => const DevConfig();
