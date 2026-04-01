import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/view/widgets/role_reveal_overlay.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('RoleRevealOverlay', () {
    testWidgets('displays correct text and auto-dismisses after animation',
        (tester) async {
      bool dismissed = false;

      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RoleRevealOverlay(
            refereeName: 'Bob',
            refereeSlot: 2,
            onDismissed: () => dismissed = true,
          ),
        ),
      );

      // Verify text elements are present.
      expect(find.text('🎤'), findsOneWidget);
      expect(find.text("YOU'RE THE REFEREE NOW"), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Verify accessibility semantics.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'You are the referee now',
        ),
        findsOneWidget,
      );

      // With animations disabled, overlay dismisses quickly.
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
