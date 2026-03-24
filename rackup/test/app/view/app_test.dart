// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/app/app.dart';
import 'package:rackup/core/config/dev_config.dart';

void main() {
  group('App', () {
    testWidgets('renders successfully', (tester) async {
      await tester.pumpWidget(App(config: DevConfig()));
      await tester.pumpAndSettle();
      expect(find.text('Rackup'), findsOneWidget);
    });
  });
}
