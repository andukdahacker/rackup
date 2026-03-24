import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';

void main() {
  group('ClampedTextScaler', () {
    group('body text role (max 2.0x)', () {
      test('allows scaling up to 2.0x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(2),
          role: TextRole.body,
        );
        expect(scaler.scale(16), 32); // 16 * 2.0
      });

      test('clamps scaling beyond 2.0x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(3),
          role: TextRole.body,
        );
        expect(scaler.scale(16), 32); // 16 * 2.0, not 16 * 3.0
      });

      test('does not affect 1.0x scaling', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.noScaling,
          role: TextRole.body,
        );
        expect(scaler.scale(16), 16);
      });
    });

    group('display text role (max 1.2x)', () {
      test('clamps scaling at 1.2x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(2),
          role: TextRole.display,
        );
        // 64 * 1.2 = 76.8
        expect(scaler.scale(64), closeTo(76.8, 0.01));
      });

      test('allows scaling below 1.2x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(1.1),
          role: TextRole.display,
        );
        expect(scaler.scale(64), closeTo(70.4, 0.01));
      });
    });

    group('referee punishment text role (max 1.3x)', () {
      test('clamps at 1.3x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(2),
          role: TextRole.refereePunishment,
        );
        expect(scaler.scale(20), closeTo(26, 0.01));
      });
    });

    group('button label role (max 1.0x — no scaling)', () {
      test('never scales', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(3),
          role: TextRole.buttonLabel,
        );
        expect(scaler.scale(28), 28);
      });
    });

    group('player name tag role (max 2.0x)', () {
      test('scales like body text', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(1.5),
          role: TextRole.playerNameTag,
        );
        expect(scaler.scale(16), 24);
      });
    });

    group('player name tag icon role (max 1.0x)', () {
      test('never scales', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(2),
          role: TextRole.playerNameTagIcon,
        );
        expect(scaler.scale(24), 24);
      });
    });

    group('ClampedTextScaler.of()', () {
      testWidgets('creates scaler from MediaQuery context', (tester) async {
        late ClampedTextScaler captured;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.5),
            ),
            child: Builder(
              builder: (context) {
                captured = ClampedTextScaler.of(context, TextRole.body);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        // Body role max is 2.0x, so 16 * 2.0 = 32 (not 16 * 2.5 = 40)
        expect(captured.scale(16), 32);
        expect(captured.role, TextRole.body);
      });
    });

    group('textScaleFactor', () {
      test('returns clamped factor for body at 3x', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(3),
          role: TextRole.body,
        );
        expect(scaler.textScaleFactor, 2.0);
      });

      test('returns unclamped factor when within limit', () {
        const scaler = ClampedTextScaler(
          baseScaler: TextScaler.linear(1.5),
          role: TextRole.body,
        );
        expect(scaler.textScaleFactor, 1.5);
      });
    });
  });
}
