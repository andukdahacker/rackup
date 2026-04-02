import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/view/widgets/streak_fire_indicator.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('StreakFireIndicator', () {
    testWidgets('renders nothing for empty streak label', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(streakLabel: ''),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders Warming Up for warming_up label', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(streakLabel: 'warming_up'),
      );

      expect(find.text('Warming Up'), findsOneWidget);
      // Single fire emoji.
      expect(find.text('\u{1F525}'), findsOneWidget);
    });

    testWidgets('renders ON FIRE for on_fire label', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(streakLabel: 'on_fire'),
      );

      expect(find.text('ON FIRE'), findsOneWidget);
      // Double fire emoji.
      expect(find.text('\u{1F525}\u{1F525}'), findsOneWidget);
    });

    testWidgets('renders UNSTOPPABLE for unstoppable label', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(streakLabel: 'unstoppable'),
      );

      expect(find.text('UNSTOPPABLE'), findsOneWidget);
      // Triple fire emoji.
      expect(find.text('\u{1F525}\u{1F525}\u{1F525}'), findsOneWidget);
    });

    testWidgets('has accessibility semantics label', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(streakLabel: 'on_fire'),
      );

      // Verify Semantics widget wraps the content with the label.
      final semanticsWidgets = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.label == 'ON FIRE');
      expect(semanticsWidgets, isNotEmpty);
    });

    testWidgets('milestone triggers eruption animation', (tester) async {
      await tester.pumpApp(
        const StreakFireIndicator(
          streakLabel: 'warming_up',
          isMilestone: true,
        ),
      );

      // Animation should be running.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // The widget should still render during animation.
      expect(find.text('Warming Up'), findsOneWidget);

      // Complete the animation.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Warming Up'), findsOneWidget);
    });
  });
}
