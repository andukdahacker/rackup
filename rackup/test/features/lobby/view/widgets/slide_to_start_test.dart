import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/view/widgets/slide_to_start.dart';

void main() {
  Widget buildSubject({
    bool enabled = true,
    VoidCallback? onStart,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: RackUpTypography.buildTextTheme(),
      ),
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 300,
            child: SlideToStart(
              enabled: enabled,
              onStart: onStart ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('SlideToStart', () {
    testWidgets('disabled state renders at 30% opacity', (tester) async {
      await tester.pumpWidget(buildSubject(enabled: false));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.3);
    });

    testWidgets('active state renders at full opacity', (tester) async {
      await tester.pumpWidget(buildSubject());

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('shows track text', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('SLIDE TO START GAME'), findsOneWidget);
    });

    testWidgets('threshold trigger fires callback', (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        buildSubject(onStart: () => triggered = true),
      );

      // Drag far enough to cross 70% threshold.
      final finder = find.byType(SlideToStart);
      await tester.drag(finder, const Offset(250, 0));
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });

    testWidgets('snap-back below threshold does not trigger',
        (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        buildSubject(onStart: () => triggered = true),
      );

      // Drag not far enough (less than 70%).
      final finder = find.byType(SlideToStart);
      await tester.drag(finder, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(triggered, isFalse);
    });

    testWidgets('long-press for 3 seconds triggers callback', (tester) async {
      var triggered = false;
      await tester.pumpWidget(
        buildSubject(onStart: () => triggered = true),
      );

      final finder = find.byType(SlideToStart);
      final center = tester.getCenter(finder);

      // Start gesture and wait for Flutter's long-press detection (~500ms).
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));

      // Now onLongPressStart has fired, starting the 3-second Timer.
      // Advance past the 3-second duration.
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });

    testWidgets('auto-resets after 5 seconds if not navigated',
        (tester) async {
      var triggerCount = 0;
      await tester.pumpWidget(
        buildSubject(onStart: () => triggerCount++),
      );

      // Trigger via drag.
      final finder = find.byType(SlideToStart);
      await tester.drag(finder, const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(triggerCount, 1);

      // Advance 5 seconds — auto-reset fires.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Should be able to trigger again.
      await tester.drag(finder, const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(triggerCount, 2);
    });
  });
}
