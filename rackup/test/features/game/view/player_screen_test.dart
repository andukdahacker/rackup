import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/view/player_screen.dart';

import '../../../helpers/helpers.dart';

void main() {
  group('PlayerScreen', () {
    const testPlayers = [
      GamePlayer(
        deviceIdHash: 'hash-a',
        displayName: 'Alice',
        slot: 1,
        score: 10,
        streak: 2,
        isReferee: false,
      ),
      GamePlayer(
        deviceIdHash: 'hash-b',
        displayName: 'Bob',
        slot: 2,
        score: 5,
        streak: 0,
        isReferee: true,
      ),
    ];

    testWidgets(
        'renders all 4 regions with correct content, self-row highlighted',
        (tester) async {
      await tester.pumpApp(
        const PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-a',
        ),
      );

      // Header: ProgressTierBar.
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Leaderboard: player names visible. Alice has higher score so appears
      // first after sorting.
      expect(find.text('Alice'), findsAtLeast(1));
      expect(find.text('Bob'), findsOneWidget);

      // My Status: items placeholder.
      expect(find.text('No items'), findsOneWidget);

      // Self-row highlighted: verify Alice's PlayerNameTag uses highlighted
      // state.
      final aliceTag = tester
          .widgetList<PlayerNameTag>(find.byType(PlayerNameTag))
          .where((tag) => tag.displayName == 'Alice');
      expect(aliceTag, isNotEmpty);
      expect(aliceTag.first.tagState, PlayerNameTagState.highlighted);

      // Bob (non-self) should be normal state.
      final bobTag = tester
          .widgetList<PlayerNameTag>(find.byType(PlayerNameTag))
          .where((tag) => tag.displayName == 'Bob');
      expect(bobTag, isNotEmpty);
      expect(bobTag.first.tagState, PlayerNameTagState.normal);
    });

    testWidgets('shows turn indicator text for current shooter',
        (tester) async {
      await tester.pumpApp(
        const PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
        ),
      );

      // Event feed shows current shooter turn indicator.
      expect(find.text("It's Alice's turn"), findsOneWidget);
    });

    testWidgets('leaderboard sorts by score descending', (tester) async {
      await tester.pumpApp(
        const PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
        ),
      );

      // Alice (score 10) should appear before Bob (score 5).
      final alicePos = tester.getTopLeft(
        find.text('Alice').first,
      );
      final bobPos = tester.getTopLeft(find.text('Bob').first);
      expect(alicePos.dy, lessThan(bobPos.dy));
    });

    testWidgets('shows streak indicator in My Status when streak > 0',
        (tester) async {
      await tester.pumpApp(
        const PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-b',
        ),
      );

      // Alice has streak=2, should show "2x".
      expect(find.text('2x'), findsOneWidget);
    });
  });
}
