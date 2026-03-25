// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/app/app.dart';
import 'package:rackup/core/config/dev_config.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App', () {
    late DeviceIdentityService deviceIdentityService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      deviceIdentityService = DeviceIdentityService(prefs: prefs);
      await deviceIdentityService.init();
    });

    testWidgets('renders successfully', (tester) async {
      await tester.pumpWidget(
        App(
          config: DevConfig(),
          deviceIdentityService: deviceIdentityService,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Turn pool night into chaos'), findsOneWidget);
    });
  });
}
