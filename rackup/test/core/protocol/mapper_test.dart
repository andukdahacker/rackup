import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/protocol/mapper.dart';
import 'package:rackup/core/protocol/messages.dart';

void main() {
  group('mapToPlayer', () {
    test('maps LobbyPlayerPayload to Player domain model', () {
      const payload = LobbyPlayerPayload(
        displayName: 'Jake',
        deviceIdHash: 'sha256abc',
        slot: 1,
        isHost: true,
        status: 'joining',
      );

      final player = mapToPlayer(payload);

      expect(player.displayName, 'Jake');
      expect(player.deviceIdHash, 'sha256abc');
      expect(player.slot, 1);
      expect(player.isHost, true);
      expect(player.status, PlayerStatus.joining);
    });

    test('maps unknown status to joining', () {
      const payload = LobbyPlayerPayload(
        displayName: 'Danny',
        deviceIdHash: 'sha256def',
        slot: 2,
        isHost: false,
        status: 'unknown_future_status',
      );

      final player = mapToPlayer(payload);

      expect(player.status, PlayerStatus.joining);
    });
  });

  group('LobbyPlayerPayload', () {
    test('parses from JSON', () {
      final json = <String, dynamic>{
        'displayName': 'Maya',
        'deviceIdHash': 'hash123',
        'slot': 3,
        'isHost': false,
        'status': 'joining',
      };

      final payload = LobbyPlayerPayload.fromJson(json);

      expect(payload.displayName, 'Maya');
      expect(payload.deviceIdHash, 'hash123');
      expect(payload.slot, 3);
      expect(payload.isHost, false);
      expect(payload.status, 'joining');
    });
  });

  group('LobbyRoomStatePayload', () {
    test('parses from JSON with player list', () {
      final json = <String, dynamic>{
        'roomCode': 'ABCD',
        'hostDeviceIdHash': 'hostHash',
        'players': [
          <String, dynamic>{
            'displayName': 'Jake',
            'deviceIdHash': 'hash1',
            'slot': 1,
            'isHost': true,
            'status': 'joining',
          },
          <String, dynamic>{
            'displayName': 'Danny',
            'deviceIdHash': 'hash2',
            'slot': 2,
            'isHost': false,
            'status': 'joining',
          },
        ],
      };

      final payload = LobbyRoomStatePayload.fromJson(json);

      expect(payload.roomCode, 'ABCD');
      expect(payload.hostDeviceIdHash, 'hostHash');
      expect(payload.players.length, 2);
      expect(payload.players[0].displayName, 'Jake');
      expect(payload.players[1].displayName, 'Danny');
    });

    test('parses empty player list', () {
      final json = <String, dynamic>{
        'roomCode': 'EFGH',
        'hostDeviceIdHash': 'hostHash',
        'players': <dynamic>[],
      };

      final payload = LobbyRoomStatePayload.fromJson(json);

      expect(payload.players, isEmpty);
    });
  });
}
