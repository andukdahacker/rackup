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
  });
}
