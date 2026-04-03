import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/cascade/cascade_timing.dart';

void main() {
  group('CascadeTiming punishment profiles', () {
    test('streak_milestone has 500ms delay (mild punishment)', () {
      final delay = CascadeTiming.delayFor('streak_milestone');
      expect(delay, const Duration(milliseconds: 500));
      expect(CascadeTiming.hasDelay('streak_milestone'), isTrue);
    });

    test('item_punishment has 1000ms delay (medium punishment)', () {
      final delay = CascadeTiming.delayFor('item_punishment');
      expect(delay, const Duration(milliseconds: 1000));
      expect(CascadeTiming.hasDelay('item_punishment'), isTrue);
    });

    test('spicy has 1200ms delay (spicy punishment)', () {
      final delay = CascadeTiming.delayFor('spicy');
      expect(delay, const Duration(milliseconds: 1200));
      expect(CascadeTiming.hasDelay('spicy'), isTrue);
    });

    test('routine has zero delay (no punishment)', () {
      final delay = CascadeTiming.delayFor('routine');
      expect(delay, Duration.zero);
      expect(CascadeTiming.hasDelay('routine'), isFalse);
    });
  });
}
