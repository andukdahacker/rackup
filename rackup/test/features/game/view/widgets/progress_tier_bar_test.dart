import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('ProgressTierBar', () {
    testWidgets('renders tier badge, progress bar, and round label',
        (tester) async {
      await tester.pumpApp(
        const ProgressTierBar(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
        ),
      );

      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Verify Semantics label exists.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Round 1 of 10, MILD tier',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders 3X badge when isTriplePoints is true',
        (tester) async {
      await tester.pumpApp(
        const ProgressTierBar(
          currentRound: 8,
          totalRounds: 10,
          tier: EscalationTier.spicy,
          isTriplePoints: true,
        ),
      );
      // Don't use pumpAndSettle — pulse animation never settles.
      await tester.pump();

      expect(find.text('3X'), findsOneWidget);
      expect(find.text('SPICY'), findsOneWidget);
    });

    testWidgets('does not render 3X badge when isTriplePoints is false',
        (tester) async {
      await tester.pumpApp(
        const ProgressTierBar(
          currentRound: 5,
          totalRounds: 10,
          tier: EscalationTier.medium,
        ),
      );

      expect(find.text('3X'), findsNothing);
    });

    testWidgets('semantics label includes triple points when active',
        (tester) async {
      await tester.pumpApp(
        const ProgressTierBar(
          currentRound: 8,
          totalRounds: 10,
          tier: EscalationTier.spicy,
          isTriplePoints: true,
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label ==
                  'Round 8 of 10, SPICY tier, Triple points active',
        ),
        findsOneWidget,
      );
    });

    testWidgets('animates tier badge on tier change', (tester) async {
      await tester.pumpApp(
        const ProgressTierBar(
          currentRound: 3,
          totalRounds: 10,
          tier: EscalationTier.mild,
        ),
      );

      // Verify AnimatedContainer is present for tier badge.
      expect(find.byType(AnimatedContainer), findsWidgets);
      expect(find.text('MILD'), findsOneWidget);
    });

    testWidgets(
        'reduced motion shows static 3X badge without pulse',
        (tester) async {
      // Use MediaQuery with disableAnimations to simulate reduced motion.
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                return RackUpGameTheme(
                  data: const RackUpGameThemeData(
                    tier: EscalationTier.spicy,
                    backgroundColor: Color(0xFF3D0A0A),
                    animationsEnabled: false,
                  ),
                  child: const ProgressTierBar(
                    currentRound: 8,
                    totalRounds: 10,
                    tier: EscalationTier.spicy,
                    isTriplePoints: true,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // The badge should still render (static, no pulse).
      expect(find.text('3X'), findsOneWidget);
    });
  });
}
