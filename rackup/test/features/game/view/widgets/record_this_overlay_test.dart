import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/view/widgets/record_this_overlay.dart';

void main() {
  group('RecordThisOverlay', () {
    testWidgets('renders RECORD THIS text and subtext', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RecordThisOverlay(
              subtext: "Alex's streak just got broken!",
              tierLabel: 'Medium',
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('RECORD THIS'), findsOneWidget);
      expect(find.text("Alex's streak just got broken!"), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders camera emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RecordThisOverlay(
              subtext: 'test subtext',
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('\u{1F4F7}'), findsOneWidget);
    });

    testWidgets('auto-dismisses and calls onDismissed',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RecordThisOverlay(
            subtext: 'test',
            onDismissed: () => dismissed = true,
          ),
        ),
      );

      expect(dismissed, isFalse);

      // Advance past the full 4000ms animation duration.
      await tester.pump(const Duration(milliseconds: 4100));

      expect(dismissed, isTrue);
    });

    testWidgets('does not show tier badge when tierLabel is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RecordThisOverlay(
              subtext: 'test',
              onDismissed: () {},
            ),
          ),
        ),
      );

      // No tier badge containers beyond the main overlay structure.
      expect(find.text('Mild'), findsNothing);
      expect(find.text('Medium'), findsNothing);
      expect(find.text('Spicy'), findsNothing);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RecordThisOverlay(
              subtext: 'Streak broken!',
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Record this moment: Streak broken!'),
        findsOneWidget,
      );
    });
  });
}
