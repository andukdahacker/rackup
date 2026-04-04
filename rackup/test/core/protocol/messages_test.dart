import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/protocol/messages.dart';

void main() {
  group('ItemDeployPayload', () {
    test('toJson includes item and targetId', () {
      const payload = ItemDeployPayload(
        item: 'blue_shell',
        targetId: 'target-hash',
      );
      final json = payload.toJson();
      expect(json['item'], 'blue_shell');
      expect(json['targetId'], 'target-hash');
    });

    test('toJson omits targetId when null', () {
      const payload = ItemDeployPayload(item: 'shield');
      final json = payload.toJson();
      expect(json['item'], 'shield');
      expect(json.containsKey('targetId'), isFalse);
    });
  });

  group('ItemDeployedPayload', () {
    test('fromJson parses all fields', () {
      final payload = ItemDeployedPayload.fromJson(const {
        'item': 'blue_shell',
        'deployerId': 'deployer-hash',
        'targetId': 'target-hash',
        'leaderboard': [
          {
            'deviceIdHash': 'p1',
            'displayName': 'Alice',
            'score': 10,
            'streak': 2,
            'streakLabel': 'warming_up',
            'rank': 1,
          },
        ],
      });
      expect(payload.item, 'blue_shell');
      expect(payload.deployerId, 'deployer-hash');
      expect(payload.targetId, 'target-hash');
      expect(payload.leaderboard, hasLength(1));
      expect(payload.leaderboard[0].displayName, 'Alice');
    });

    test('fromJson handles null targetId', () {
      final payload = ItemDeployedPayload.fromJson(const {
        'item': 'shield',
        'deployerId': 'deployer-hash',
        'leaderboard': <Map<String, dynamic>>[],
      });
      expect(payload.targetId, isNull);
      expect(payload.leaderboard, isEmpty);
    });
  });

  group('ItemFizzledPayload', () {
    test('fromJson parses all fields', () {
      final payload = ItemFizzledPayload.fromJson(const {
        'item': 'shield',
        'reason': 'ITEM_CONSUMED',
      });
      expect(payload.item, 'shield');
      expect(payload.reason, 'ITEM_CONSUMED');
    });
  });
}
