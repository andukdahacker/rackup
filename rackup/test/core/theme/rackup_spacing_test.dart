import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';

void main() {
  group('RackUpSpacing', () {
    test('spaceXs is 4dp', () {
      expect(RackUpSpacing.spaceXs, 4);
    });

    test('spaceSm is 8dp', () {
      expect(RackUpSpacing.spaceSm, 8);
    });

    test('spaceMd is 16dp', () {
      expect(RackUpSpacing.spaceMd, 16);
    });

    test('spaceLg is 24dp', () {
      expect(RackUpSpacing.spaceLg, 24);
    });

    test('spaceXl is 32dp', () {
      expect(RackUpSpacing.spaceXl, 32);
    });

    test('spaceXxl is 48dp', () {
      expect(RackUpSpacing.spaceXxl, 48);
    });

    test('minTapTarget is 56dp', () {
      expect(RackUpSpacing.minTapTarget, 56);
    });

    test('primaryButtonHeight is 64dp', () {
      expect(RackUpSpacing.primaryButtonHeight, 64);
    });

    test('all spacing values follow 8dp base grid (except spaceXs)', () {
      expect(RackUpSpacing.spaceSm % 8, 0);
      expect(RackUpSpacing.spaceMd % 8, 0);
      expect(RackUpSpacing.spaceLg % 8, 0);
      expect(RackUpSpacing.spaceXl % 8, 0);
      expect(RackUpSpacing.spaceXxl % 8, 0);
    });
  });
}
