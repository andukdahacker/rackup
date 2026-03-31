import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/player.dart';

void main() {
  group('PlayerStatus', () {
    test('has joining value', () {
      expect(PlayerStatus.joining, isNotNull);
      expect(PlayerStatus.values, contains(PlayerStatus.joining));
    });

    test('has writing value', () {
      expect(PlayerStatus.writing, isNotNull);
      expect(PlayerStatus.values, contains(PlayerStatus.writing));
    });

    test('has ready value', () {
      expect(PlayerStatus.ready, isNotNull);
      expect(PlayerStatus.values, contains(PlayerStatus.ready));
    });

    test('has exactly three values', () {
      expect(PlayerStatus.values.length, 3);
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

    test('copyWith returns new player with changed status', () {
      final updated = player.copyWith(status: PlayerStatus.writing);
      expect(updated.status, PlayerStatus.writing);
      expect(updated.displayName, 'Jake');
      expect(updated.deviceIdHash, 'abc123');
      expect(updated.slot, 1);
      expect(updated.isHost, true);
    });

    test('copyWith with no arguments returns equal player', () {
      final copy = player.copyWith();
      expect(copy, equals(player));
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
