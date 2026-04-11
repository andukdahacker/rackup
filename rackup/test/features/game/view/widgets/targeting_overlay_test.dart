import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/view/widgets/targeting_overlay.dart';

import '../../../../helpers/helpers.dart';

void main() {
  const blueShell = Item(
    type: 'blue_shell',
    displayName: 'Blue Shell',
    accentColorHex: '#3B82F6',
    iconData: Icons.gps_fixed,
    requiresTarget: true,
  );

  const scoreSteal = Item(
    type: 'score_steal',
    displayName: 'Score Steal',
    accentColorHex: '#FF6B6B',
    iconData: Icons.swap_horiz,
    requiresTarget: true,
  );

  // Three non-deployer, non-referee players for the targeting list.
  const testEntries = [
    LeaderboardEntry(
      deviceIdHash: 'p1',
      displayName: 'Alice',
      score: 15,
      streak: 0,
      streakLabel: '',
      rank: 1,
    ),
    LeaderboardEntry(
      deviceIdHash: 'p2',
      displayName: 'Bob',
      score: 10,
      streak: 0,
      streakLabel: '',
      rank: 2,
    ),
    LeaderboardEntry(
      deviceIdHash: 'p3',
      displayName: 'Charlie',
      score: 5,
      streak: 0,
      streakLabel: '',
      rank: 3,
    ),
  ];

  const testSlots = {'p1': 1, 'p2': 2, 'p3': 3, 'me': 4, 'ref': 5};

  /// Wraps [child] with a `LeaderboardBloc` seeded with [entries].
  Widget wrapWithLeaderboard(
    Widget child, {
    List<LeaderboardEntry> entries = testEntries,
  }) {
    final bloc = LeaderboardBloc()
      ..add(LeaderboardRefreshed(entries: entries));
    return BlocProvider<LeaderboardBloc>.value(value: bloc, child: child);
  }

  group('TargetingOverlay', () {
    testWidgets('renders player list with names, ranks, scores',
        (tester) async {
      await tester.pumpApp(
        wrapWithLeaderboard(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTargetingOverlay(
                context: context,
                item: scoreSteal,
                localDeviceIdHash: 'me',
                refereeDeviceIdHash: 'ref',
                playerSlots: testSlots,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('Blue Shell shows gold border on first-place row',
        (tester) async {
      await tester.pumpApp(
        wrapWithLeaderboard(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTargetingOverlay(
                context: context,
                item: blueShell,
                localDeviceIdHash: 'me',
                refereeDeviceIdHash: 'ref',
                playerSlots: testSlots,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show pulsing crosshair icon for first-place when Blue Shell.
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });

    testWidgets('tap on row returns target device hash', (tester) async {
      String? selectedTarget;

      await tester.pumpApp(
        wrapWithLeaderboard(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedTarget = await showTargetingOverlay(
                  context: context,
                  item: scoreSteal,
                  localDeviceIdHash: 'me',
                  refereeDeviceIdHash: 'ref',
                  playerSlots: testSlots,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      expect(selectedTarget, 'p2');
    });

    testWidgets('tap outside dismisses overlay', (tester) async {
      String? selectedTarget = 'not-null';

      await tester.pumpApp(
        wrapWithLeaderboard(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedTarget = await showTargetingOverlay(
                  context: context,
                  item: scoreSteal,
                  localDeviceIdHash: 'me',
                  refereeDeviceIdHash: 'ref',
                  playerSlots: testSlots,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap outside the bottom sheet (at the top of the screen).
      await tester.tapAt(const Offset(100, 10));
      await tester.pumpAndSettle();

      expect(selectedTarget, isNull);
    });

    testWidgets('shows cancel button when no targets are available',
        (tester) async {
      String? result = 'not-null';

      // Empty leaderboard → empty target list.
      await tester.pumpApp(
        wrapWithLeaderboard(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showTargetingOverlay(
                  context: context,
                  item: scoreSteal,
                  localDeviceIdHash: 'me',
                  refereeDeviceIdHash: 'ref',
                  playerSlots: const {},
                );
              },
              child: const Text('Open'),
            ),
          ),
          entries: const [],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No valid targets available.'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('refreshes targets when leaderboard updates while open',
        (tester) async {
      late LeaderboardBloc bloc;
      bloc = LeaderboardBloc()
        ..add(const LeaderboardRefreshed(entries: testEntries));

      await tester.pumpApp(
        BlocProvider<LeaderboardBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTargetingOverlay(
                context: context,
                item: scoreSteal,
                localDeviceIdHash: 'me',
                refereeDeviceIdHash: 'ref',
                playerSlots: testSlots,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);

      // Push a new leaderboard with Alice removed.
      bloc.add(const LeaderboardRefreshed(entries: [
        LeaderboardEntry(
          deviceIdHash: 'p2',
          displayName: 'Bob',
          score: 10,
          streak: 0,
          streakLabel: '',
          rank: 1,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('buildTargetList', () {
    test('filters out deployer and referee', () {
      final entries = [
        const LeaderboardEntry(
          deviceIdHash: 'deployer',
          displayName: 'Me',
          score: 10,
          streak: 0,
          streakLabel: '',
          rank: 1,
        ),
        const LeaderboardEntry(
          deviceIdHash: 'referee',
          displayName: 'Ref',
          score: 0,
          streak: 0,
          streakLabel: '',
          rank: 4,
        ),
        const LeaderboardEntry(
          deviceIdHash: 'target1',
          displayName: 'Target',
          score: 5,
          streak: 0,
          streakLabel: '',
          rank: 2,
        ),
      ];
      final targets = buildTargetList(
        entries: entries,
        localDeviceIdHash: 'deployer',
        refereeDeviceIdHash: 'referee',
        playerSlots: {'deployer': 1, 'referee': 2, 'target1': 3},
      );
      expect(targets, hasLength(1));
      expect(targets[0].deviceIdHash, 'target1');
    });

    test('sorts by rank ascending', () {
      final entries = [
        const LeaderboardEntry(
          deviceIdHash: 'p3',
          displayName: 'Third',
          score: 5,
          streak: 0,
          streakLabel: '',
          rank: 3,
        ),
        const LeaderboardEntry(
          deviceIdHash: 'p1',
          displayName: 'First',
          score: 15,
          streak: 0,
          streakLabel: '',
          rank: 1,
        ),
      ];
      final targets = buildTargetList(
        entries: entries,
        localDeviceIdHash: 'me',
        refereeDeviceIdHash: 'ref',
        playerSlots: {'p1': 1, 'p3': 3},
      );
      expect(targets[0].rank, 1);
      expect(targets[1].rank, 3);
    });
  });
}
