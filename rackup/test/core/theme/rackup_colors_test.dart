import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

void main() {
  group('RackUpColors', () {
    group('base canvas', () {
      test('canvas is #0F0E1A', () {
        expect(RackUpColors.canvas, const Color(0xFF0F0E1A));
      });
    });

    group('semantic colors', () {
      test('madeGreen is #16A34A', () {
        expect(RackUpColors.madeGreen, const Color(0xFF16A34A));
      });

      test('missedRed is #EF4444', () {
        expect(RackUpColors.missedRed, const Color(0xFFEF4444));
      });

      test('streakGold is #FFD700', () {
        expect(RackUpColors.streakGold, const Color(0xFFFFD700));
      });

      test('itemBlue is #3B82F6', () {
        expect(RackUpColors.itemBlue, const Color(0xFF3B82F6));
      });

      test('missionPurple is #A855F7', () {
        expect(RackUpColors.missionPurple, const Color(0xFFA855F7));
      });

      test('textPrimary is #F0EDF6', () {
        expect(RackUpColors.textPrimary, const Color(0xFFF0EDF6));
      });

      test('textSecondary is #8B85A1', () {
        expect(RackUpColors.textSecondary, const Color(0xFF8B85A1));
      });
    });

    group('escalation tier backgrounds', () {
      test('tierLobby is #1A1832', () {
        expect(RackUpColors.tierLobby, const Color(0xFF1A1832));
      });

      test('tierMild is #0D2B3E', () {
        expect(RackUpColors.tierMild, const Color(0xFF0D2B3E));
      });

      test('tierMedium is #3D2008', () {
        expect(RackUpColors.tierMedium, const Color(0xFF3D2008));
      });

      test('tierSpicy is #3D0A0A', () {
        expect(RackUpColors.tierSpicy, const Color(0xFF3D0A0A));
      });
    });

    group('player identity colors', () {
      test('playerCoral is #FF6B6B', () {
        expect(RackUpColors.playerCoral, const Color(0xFFFF6B6B));
      });

      test('playerCyan is #4ECDC4', () {
        expect(RackUpColors.playerCyan, const Color(0xFF4ECDC4));
      });

      test('playerAmber is #FFB347', () {
        expect(RackUpColors.playerAmber, const Color(0xFFFFB347));
      });

      test('playerViolet is #9B59B6', () {
        expect(RackUpColors.playerViolet, const Color(0xFF9B59B6));
      });

      test('playerLime is #A8E06C', () {
        expect(RackUpColors.playerLime, const Color(0xFFA8E06C));
      });

      test('playerSky is #74B9FF', () {
        expect(RackUpColors.playerSky, const Color(0xFF74B9FF));
      });

      test('playerRose is #FD79A8', () {
        expect(RackUpColors.playerRose, const Color(0xFFFD79A8));
      });

      test('playerMint is #55E6C1', () {
        expect(RackUpColors.playerMint, const Color(0xFF55E6C1));
      });
    });
  });
}
