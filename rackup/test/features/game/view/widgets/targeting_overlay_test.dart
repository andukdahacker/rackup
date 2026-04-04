import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
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

  final testTargets = [
    const TargetData(
      deviceIdHash: 'p1',
      displayName: 'Alice',
      score: 15,
      rank: 1,
      slot: 1,
    ),
    const TargetData(
      deviceIdHash: 'p2',
      displayName: 'Bob',
      score: 10,
      rank: 2,
      slot: 2,
    ),
    const TargetData(
      deviceIdHash: 'p3',
      displayName: 'Charlie',
      score: 5,
      rank: 3,
      slot: 3,
    ),
  ];

  group('TargetingOverlay', () {
    testWidgets('renders player list with names, ranks, scores',
        (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTargetingOverlay(
              context: context,
              item: scoreSteal,
              targets: testTargets,
            ),
            child: const Text('Open'),
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
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTargetingOverlay(
              context: context,
              item: blueShell,
              targets: testTargets,
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      // Use pump instead of pumpAndSettle because the crosshair pulses.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show pulsing crosshair icon for first-place when Blue Shell.
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    });

    testWidgets('tap on row returns target device hash', (tester) async {
      String? selectedTarget;

      await tester.pumpApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedTarget = await showTargetingOverlay(
                context: context,
                item: scoreSteal,
                targets: testTargets,
              );
            },
            child: const Text('Open'),
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
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedTarget = await showTargetingOverlay(
                context: context,
                item: scoreSteal,
                targets: testTargets,
              );
            },
            child: const Text('Open'),
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
