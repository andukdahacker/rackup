import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

void main() {
  group('PlayerIdentity', () {
    test('has exactly 8 slots', () {
      expect(PlayerIdentity.slots, hasLength(8));
    });

    test('slot numbers are 1 through 8', () {
      for (var i = 0; i < 8; i++) {
        expect(PlayerIdentity.slots[i].slot, i + 1);
      }
    });

    test('all shapes are unique', () {
      final shapes = PlayerIdentity.slots.map((s) => s.shape).toSet();
      expect(shapes, hasLength(8));
    });

    test('all colors are unique', () {
      final colors = PlayerIdentity.slots.map((s) => s.color).toSet();
      expect(colors, hasLength(8));
    });

    test('slot 1 is Coral Circle', () {
      final slot = PlayerIdentity.forSlot(1);
      expect(slot.name, 'Coral');
      expect(slot.color, RackUpColors.playerCoral);
      expect(slot.shape, PlayerShape.circle);
    });

    test('slot 2 is Cyan Square', () {
      final slot = PlayerIdentity.forSlot(2);
      expect(slot.name, 'Cyan');
      expect(slot.color, RackUpColors.playerCyan);
      expect(slot.shape, PlayerShape.square);
    });

    test('slot 3 is Amber Triangle', () {
      final slot = PlayerIdentity.forSlot(3);
      expect(slot.name, 'Amber');
      expect(slot.color, RackUpColors.playerAmber);
      expect(slot.shape, PlayerShape.triangle);
    });

    test('slot 4 is Violet Diamond', () {
      final slot = PlayerIdentity.forSlot(4);
      expect(slot.name, 'Violet');
      expect(slot.color, RackUpColors.playerViolet);
      expect(slot.shape, PlayerShape.diamond);
    });

    test('slot 5 is Lime Star', () {
      final slot = PlayerIdentity.forSlot(5);
      expect(slot.name, 'Lime');
      expect(slot.color, RackUpColors.playerLime);
      expect(slot.shape, PlayerShape.star);
    });

    test('slot 6 is Sky Hexagon', () {
      final slot = PlayerIdentity.forSlot(6);
      expect(slot.name, 'Sky');
      expect(slot.color, RackUpColors.playerSky);
      expect(slot.shape, PlayerShape.hexagon);
    });

    test('slot 7 is Rose Cross', () {
      final slot = PlayerIdentity.forSlot(7);
      expect(slot.name, 'Rose');
      expect(slot.color, RackUpColors.playerRose);
      expect(slot.shape, PlayerShape.cross);
    });

    test('slot 8 is Mint Pentagon', () {
      final slot = PlayerIdentity.forSlot(8);
      expect(slot.name, 'Mint');
      expect(slot.color, RackUpColors.playerMint);
      expect(slot.shape, PlayerShape.pentagon);
    });

    test('forSlot throws RangeError for slot 0', () {
      expect(() => PlayerIdentity.forSlot(0), throwsRangeError);
    });

    test('forSlot throws RangeError for slot 9', () {
      expect(() => PlayerIdentity.forSlot(9), throwsRangeError);
    });

    test('forSlot throws RangeError for negative slot', () {
      expect(() => PlayerIdentity.forSlot(-1), throwsRangeError);
    });
  });

  group('PlayerShape', () {
    test('has 8 values', () {
      expect(PlayerShape.values, hasLength(8));
    });
  });
}
