import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/view/widgets/triple_points_overlay.dart';

void main() {
  group('TriplePointsOverlay', () {
    testWidgets('renders TRIPLE POINTS and 3X text', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TriplePointsOverlay(
            onDismissed: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('TRIPLE POINTS'), findsOneWidget);
      expect(find.text('3X'), findsOneWidget);
      expect(dismissed, isFalse);
    });

    testWidgets('auto-dismisses after animation completes',
        (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TriplePointsOverlay(
            onDismissed: () => dismissed = true,
          ),
        ),
      );

      expect(dismissed, isFalse);

      // Advance past the full animation duration (2600ms).
      await tester.pump(const Duration(milliseconds: 2700));

      expect(dismissed, isTrue);
    });

    testWidgets('has correct semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TriplePointsOverlay(
            onDismissed: () {},
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Triple points activated',
        ),
        findsOneWidget,
      );
    });
  });
}
