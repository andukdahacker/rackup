import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';

void main() {
  group('RackUpTypography', () {
    test('displayXl has correct size, weight, and height', () {
      expect(RackUpTypography.displayXl.fontSize, 64);
      expect(RackUpTypography.displayXl.fontWeight, FontWeight.w700);
      expect(RackUpTypography.displayXl.height, 1.1);
      expect(RackUpTypography.displayXl.color, RackUpColors.textPrimary);
    });

    test('displayLg has correct size, weight, and height', () {
      expect(RackUpTypography.displayLg.fontSize, 48);
      expect(RackUpTypography.displayLg.fontWeight, FontWeight.w700);
      expect(RackUpTypography.displayLg.height, 1.1);
    });

    test('displayMd has correct size, weight, and height', () {
      expect(RackUpTypography.displayMd.fontSize, 36);
      expect(RackUpTypography.displayMd.fontWeight, FontWeight.w600);
      expect(RackUpTypography.displayMd.height, 1.2);
    });

    test('displaySm has correct size, weight, and height', () {
      expect(RackUpTypography.displaySm.fontSize, 32);
      expect(RackUpTypography.displaySm.fontWeight, FontWeight.w500);
      expect(RackUpTypography.displaySm.height, 1.2);
    });

    test('heading has correct size, weight, and height', () {
      expect(RackUpTypography.heading.fontSize, 24);
      expect(RackUpTypography.heading.fontWeight, FontWeight.w700);
      expect(RackUpTypography.heading.height, 1.3);
    });

    test('bodyLg has correct size, weight, and height', () {
      expect(RackUpTypography.bodyLg.fontSize, 20);
      expect(RackUpTypography.bodyLg.fontWeight, FontWeight.w500);
      expect(RackUpTypography.bodyLg.height, 1.4);
    });

    test('body has correct size, weight, and height', () {
      expect(RackUpTypography.body.fontSize, 16);
      expect(RackUpTypography.body.fontWeight, FontWeight.w400);
      expect(RackUpTypography.body.height, 1.5);
    });

    test('caption has correct size, weight, and height', () {
      expect(RackUpTypography.caption.fontSize, 14);
      expect(RackUpTypography.caption.fontWeight, FontWeight.w400);
      expect(RackUpTypography.caption.height, 1.4);
    });
  });

  group('RackUpFontFamilies', () {
    test('display styles use Oswald font family', () {
      expect(
        RackUpTypography.displayXl.fontFamily,
        RackUpFontFamilies.display,
      );
      expect(
        RackUpTypography.displayLg.fontFamily,
        RackUpFontFamilies.display,
      );
      expect(
        RackUpTypography.displayMd.fontFamily,
        RackUpFontFamilies.display,
      );
      expect(
        RackUpTypography.displaySm.fontFamily,
        RackUpFontFamilies.display,
      );
    });

    test('heading uses Barlow Condensed font family', () {
      expect(
        RackUpTypography.heading.fontFamily,
        RackUpFontFamilies.accent,
      );
    });

    test('body styles use Barlow font family', () {
      expect(RackUpTypography.bodyLg.fontFamily, RackUpFontFamilies.body);
      expect(RackUpTypography.body.fontFamily, RackUpFontFamilies.body);
      expect(RackUpTypography.caption.fontFamily, RackUpFontFamilies.body);
    });
  });
}
