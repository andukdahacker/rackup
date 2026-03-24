import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

void main() {
  group('RackUpGameTheme', () {
    group('tierForProgression', () {
      test('returns lobby for 0%', () {
        expect(
          RackUpGameTheme.tierForProgression(0),
          EscalationTier.lobby,
        );
      });

      test('returns lobby for negative values', () {
        expect(
          RackUpGameTheme.tierForProgression(-5),
          EscalationTier.lobby,
        );
      });

      test('returns mild for 1%', () {
        expect(
          RackUpGameTheme.tierForProgression(1),
          EscalationTier.mild,
        );
      });

      test('returns mild for 30%', () {
        expect(
          RackUpGameTheme.tierForProgression(30),
          EscalationTier.mild,
        );
      });

      test('returns medium for 31%', () {
        expect(
          RackUpGameTheme.tierForProgression(31),
          EscalationTier.medium,
        );
      });

      test('returns medium for 70%', () {
        expect(
          RackUpGameTheme.tierForProgression(70),
          EscalationTier.medium,
        );
      });

      test('returns spicy for 71%', () {
        expect(
          RackUpGameTheme.tierForProgression(71),
          EscalationTier.spicy,
        );
      });

      test('returns spicy for 100%', () {
        expect(
          RackUpGameTheme.tierForProgression(100),
          EscalationTier.spicy,
        );
      });

      test('clamps values above 100 to spicy', () {
        expect(
          RackUpGameTheme.tierForProgression(150),
          EscalationTier.spicy,
        );
      });

      test('clamps NaN to lobby', () {
        expect(
          RackUpGameTheme.tierForProgression(double.nan),
          EscalationTier.lobby,
        );
      });

      test('clamps infinity to spicy', () {
        expect(
          RackUpGameTheme.tierForProgression(double.infinity),
          EscalationTier.spicy,
        );
      });
    });

    group('backgroundForTier', () {
      test('lobby returns tierLobby color', () {
        expect(
          RackUpGameTheme.backgroundForTier(EscalationTier.lobby),
          RackUpColors.tierLobby,
        );
      });

      test('mild returns tierMild color', () {
        expect(
          RackUpGameTheme.backgroundForTier(EscalationTier.mild),
          RackUpColors.tierMild,
        );
      });

      test('medium returns tierMedium color', () {
        expect(
          RackUpGameTheme.backgroundForTier(EscalationTier.medium),
          RackUpColors.tierMedium,
        );
      });

      test('spicy returns tierSpicy color', () {
        expect(
          RackUpGameTheme.backgroundForTier(EscalationTier.spicy),
          RackUpColors.tierSpicy,
        );
      });
    });

    group('fromProgression', () {
      test('creates correct data for lobby', () {
        final data = RackUpGameTheme.fromProgression(
          percentage: 0,
          animationsEnabled: true,
        );
        expect(data.tier, EscalationTier.lobby);
        expect(data.backgroundColor, RackUpColors.tierLobby);
        expect(data.animationsEnabled, isTrue);
      });

      test('creates correct data for spicy', () {
        final data = RackUpGameTheme.fromProgression(
          percentage: 85,
          animationsEnabled: false,
        );
        expect(data.tier, EscalationTier.spicy);
        expect(data.backgroundColor, RackUpColors.tierSpicy);
        expect(data.animationsEnabled, isFalse);
      });
    });

    group('RackUpGameThemeData', () {
      test('tierTransitionDuration is 500ms when animations enabled', () {
        const data = RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: true,
        );
        expect(
          data.tierTransitionDuration,
          const Duration(milliseconds: 500),
        );
      });

      test('tierTransitionDuration is zero when animations disabled', () {
        const data = RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: false,
        );
        expect(data.tierTransitionDuration, Duration.zero);
      });

      test('equality compares by value', () {
        const a = RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: true,
        );
        const b = RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: true,
        );
        const c = RackUpGameThemeData(
          tier: EscalationTier.spicy,
          backgroundColor: RackUpColors.tierSpicy,
          animationsEnabled: true,
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
        expect(a, isNot(equals(c)));
      });

      test('stub fields return null/default', () {
        const data = RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: true,
        );
        expect(data.particlePreset, isNull);
        expect(data.glowIntensity, isNull);
        expect(data.copyIntensityTier, isNull);
      });
    });

    group('InheritedWidget', () {
      testWidgets('of() returns data from ancestor', (tester) async {
        late RackUpGameThemeData captured;
        await tester.pumpWidget(
          RackUpGameTheme(
            data: const RackUpGameThemeData(
              tier: EscalationTier.medium,
              backgroundColor: RackUpColors.tierMedium,
              animationsEnabled: true,
            ),
            child: Builder(
              builder: (context) {
                captured = RackUpGameTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(captured.tier, EscalationTier.medium);
        expect(captured.backgroundColor, RackUpColors.tierMedium);
      });

      testWidgets('of() throws when no ancestor', (tester) async {
        late FlutterError captured;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              try {
                RackUpGameTheme.of(context);
                // ignore: avoid_catching_errors, testing FlutterError throw
              } on FlutterError catch (e) {
                captured = e;
              }
              return const SizedBox.shrink();
            },
          ),
        );
        expect(
          captured.message,
          contains('RackUpGameTheme.of()'),
        );
      });

      testWidgets('maybeOf() returns null when no ancestor', (tester) async {
        RackUpGameThemeData? captured;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              captured = RackUpGameTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        );
        expect(captured, isNull);
      });

      testWidgets('updateShouldNotify triggers on tier change',
          (tester) async {
        var buildCount = 0;
        final widget = Builder(
          builder: (context) {
            RackUpGameTheme.of(context);
            buildCount++;
            return const SizedBox.shrink();
          },
        );

        await tester.pumpWidget(
          RackUpGameTheme(
            data: const RackUpGameThemeData(
              tier: EscalationTier.lobby,
              backgroundColor: RackUpColors.tierLobby,
              animationsEnabled: true,
            ),
            child: widget,
          ),
        );
        expect(buildCount, 1);

        await tester.pumpWidget(
          RackUpGameTheme(
            data: const RackUpGameThemeData(
              tier: EscalationTier.spicy,
              backgroundColor: RackUpColors.tierSpicy,
              animationsEnabled: true,
            ),
            child: widget,
          ),
        );
        expect(buildCount, 2);
      });
    });
  });
}
