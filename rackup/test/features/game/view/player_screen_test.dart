import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/view/player_screen.dart';

import '../../../helpers/helpers.dart';

void main() {
  group('PlayerScreen', () {
    final testPlayers = const [
      GamePlayer(
        deviceIdHash: 'hash-a',
        displayName: 'Alice',
        slot: 1,
        score: 0,
        streak: 0,
        isReferee: false,
      ),
      GamePlayer(
        deviceIdHash: 'hash-b',
        displayName: 'Bob',
        slot: 2,
        score: 0,
        streak: 0,
        isReferee: true,
      ),
    ];

    testWidgets(
        'renders all 4 regions with correct content, self-row highlighted',
        (tester) async {
      await tester.pumpApp(
        PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
        ),
      );

      // Header: ProgressTierBar.
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Leaderboard: player names visible.
      expect(find.text('Alice'), findsAtLeast(1));
      expect(find.text('Bob'), findsOneWidget);

      // Event Feed: placeholder.
      expect(find.text('Game started!'), findsOneWidget);

      // My Status: items placeholder.
      expect(find.text('No items'), findsOneWidget);

      // Self-row highlighted: verify Alice's PlayerNameTag uses highlighted state.
      final aliceTag = tester.widgetList<PlayerNameTag>(
        find.byType(PlayerNameTag),
      ).where((tag) => tag.displayName == 'Alice');
      expect(aliceTag, isNotEmpty);
      expect(aliceTag.first.tagState, PlayerNameTagState.highlighted);

      // Bob (non-self) should be normal state.
      final bobTag = tester.widgetList<PlayerNameTag>(
        find.byType(PlayerNameTag),
      ).where((tag) => tag.displayName == 'Bob');
      expect(bobTag, isNotEmpty);
      expect(bobTag.first.tagState, PlayerNameTagState.normal);
    });
  });
}
