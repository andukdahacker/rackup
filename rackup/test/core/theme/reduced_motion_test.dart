import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

void main() {
  group('Reduced motion support', () {
    testWidgets('animationsEnabled is false when disableAnimations is true',
        (tester) async {
      late RackUpGameThemeData captured;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              final disableAnimations =
                  MediaQuery.of(context).disableAnimations;
              captured = RackUpGameTheme.fromProgression(
                percentage: 0,
                animationsEnabled: !disableAnimations,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.animationsEnabled, isFalse);
      expect(captured.tierTransitionDuration, Duration.zero);
    });

    testWidgets('animationsEnabled is true when disableAnimations is false',
        (tester) async {
      late RackUpGameThemeData captured;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              final disableAnimations =
                  MediaQuery.of(context).disableAnimations;
              captured = RackUpGameTheme.fromProgression(
                percentage: 50,
                animationsEnabled: !disableAnimations,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.animationsEnabled, isTrue);
      expect(
        captured.tierTransitionDuration,
        const Duration(milliseconds: 500),
      );
    });

    test('tier transition duration is 500ms with animations enabled', () {
      const data = RackUpGameThemeData(
        tier: EscalationTier.mild,
        backgroundColor: RackUpColors.tierMild,
        animationsEnabled: true,
      );
      expect(data.tierTransitionDuration, const Duration(milliseconds: 500));
    });

    test('tier transition duration is zero with animations disabled', () {
      const data = RackUpGameThemeData(
        tier: EscalationTier.mild,
        backgroundColor: RackUpColors.tierMild,
        animationsEnabled: false,
      );
      expect(data.tierTransitionDuration, Duration.zero);
    });
  });
}
