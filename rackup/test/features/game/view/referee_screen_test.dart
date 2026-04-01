import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/features/game/view/referee_screen.dart';

import '../../../helpers/helpers.dart';

void main() {
  group('RefereeScreen', () {
    testWidgets('renders all 4 regions with correct content', (tester) async {
      await tester.pumpApp(
        const RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: GamePlayer(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            slot: 1,
            score: 0,
            streak: 0,
            isReferee: false,
          ),
        ),
      );

      // Status Bar: ProgressTierBar.
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Stage Area: current shooter name.
      expect(find.text('Alice'), findsOneWidget);

      // Action Zone: placeholder.
      expect(find.text('Waiting for turn...'), findsOneWidget);

      // Footer: leaderboard placeholder.
      expect(find.text('Leaderboard'), findsOneWidget);
    });
  });
}
