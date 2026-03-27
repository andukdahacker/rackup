import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/player.dart';

void main() {
  group('PlayerStatus', () {
    test('has joining value', () {
      expect(PlayerStatus.joining, isNotNull);
      expect(PlayerStatus.values, contains(PlayerStatus.joining));
    });

    test('has exactly one value for Story 2.1', () {
      expect(PlayerStatus.values.length, 1);
    });
  });

  group('Player', () {
    const player = Player(
      displayName: 'Jake',
      deviceIdHash: 'abc123',
      slot: 1,
      isHost: true,
      status: PlayerStatus.joining,
    );

    test('stores all fields correctly', () {
      expect(player.displayName, 'Jake');
      expect(player.deviceIdHash, 'abc123');
      expect(player.slot, 1);
      expect(player.isHost, true);
      expect(player.status, PlayerStatus.joining);
    });

    test('extends Equatable with correct props', () {
      const identical = Player(
        displayName: 'Jake',
        deviceIdHash: 'abc123',
        slot: 1,
        isHost: true,
        status: PlayerStatus.joining,
      );
      expect(player, equals(identical));
    });

    test('is not equal when any field differs', () {
      const differentName = Player(
        displayName: 'Danny',
        deviceIdHash: 'abc123',
        slot: 1,
        isHost: true,
        status: PlayerStatus.joining,
      );
      expect(player, isNot(equals(differentName)));

      const differentSlot = Player(
        displayName: 'Jake',
        deviceIdHash: 'abc123',
        slot: 2,
        isHost: true,
        status: PlayerStatus.joining,
      );
      expect(player, isNot(equals(differentSlot)));

      const differentHost = Player(
        displayName: 'Jake',
        deviceIdHash: 'abc123',
        slot: 1,
        isHost: false,
        status: PlayerStatus.joining,
      );
      expect(player, isNot(equals(differentHost)));
    });

    test('is immutable', () {
      // Verify that Player fields are final by creating and comparing.
      // The const constructor proves immutability.
      const p1 = Player(
        displayName: 'A',
        deviceIdHash: 'hash',
        slot: 3,
        isHost: false,
        status: PlayerStatus.joining,
      );
      const p2 = Player(
        displayName: 'A',
        deviceIdHash: 'hash',
        slot: 3,
        isHost: false,
        status: PlayerStatus.joining,
      );
      expect(identical(p1, p2), isTrue);
    });
  });
}
