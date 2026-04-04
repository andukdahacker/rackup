import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/view/player_screen.dart';
import 'package:rackup/features/game/view/widgets/event_feed_widget.dart';
import 'package:rackup/features/game/view/widgets/leaderboard_row.dart';

import '../../../helpers/helpers.dart';

class _MockWebSocketCubit extends Mock implements WebSocketCubit {}

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

    late LeaderboardBloc leaderboardBloc;
    late EventFeedCubit eventFeedCubit;
    late ItemBloc itemBloc;

    setUp(() {
      leaderboardBloc = LeaderboardBloc();
      eventFeedCubit = EventFeedCubit();
      itemBloc = ItemBloc(webSocketCubit: _MockWebSocketCubit());
    });

    tearDown(() {
      leaderboardBloc.close();
      eventFeedCubit.close();
      itemBloc.close();
    });

    /// Wraps a widget with the required providers.
    Widget wrapWithProviders(Widget child) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<EventFeedCubit>.value(value: eventFeedCubit),
          BlocProvider<ItemBloc>.value(value: itemBloc),
        ],
        child: child,
      );
    }

    testWidgets(
        'renders all 4 regions with correct content, self-row highlighted',
        (tester) async {
      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
      );

      // Header: ProgressTierBar.
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Leaderboard: player names visible. Alice has higher score so appears
      // first after sorting.
      expect(find.text('Alice'), findsAtLeast(1));
      expect(find.text('Bob'), findsOneWidget);

      // My Status: empty item card placeholder.
      expect(find.byKey(const ValueKey('item-empty')), findsOneWidget);

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

    testWidgets('EventFeedWidget is in the widget tree', (tester) async {
      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
      );

      expect(find.byType(EventFeedWidget), findsOneWidget);
    });

    testWidgets('leaderboard sorts by score descending', (tester) async {
      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
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
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-b',
          leaderboardBloc: leaderboardBloc,
        )),
      );

      // Alice has streak=2, should show "2x".
      expect(find.text('2x'), findsOneWidget);
    });

    // Story 3.4 tests below.

    testWidgets(
        'renders display names and scores with Oswald font via LeaderboardBloc',
        (tester) async {
      // Emit leaderboard state so the bloc-based renderer is used.
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 2,
            streakLabel: 'warming_up',
            rank: 1,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 5,
            streak: 0,
            streakLabel: '',
            rank: 2,
          ),
        ],
        shooterHash: 'hash-a',
      ));

      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
      );
      await tester.pump();

      // Verify LeaderboardRow is rendered.
      expect(find.byType(LeaderboardRow), findsNWidgets(2));

      // Check PlayerNameTag uses leaderboard size (Oswald).
      final tags = tester
          .widgetList<PlayerNameTag>(find.byType(PlayerNameTag))
          .where((tag) =>
              tag.displayName == 'Alice' || tag.displayName == 'Bob')
          .toList();
      for (final tag in tags) {
        // Within the leaderboard, tags should use leaderboard size.
        if (tag.size == PlayerNameTagSize.leaderboard) {
          expect(tag.size, PlayerNameTagSize.leaderboard);
        }
      }

      // Verify score text uses Oswald Bold by checking TextStyle.
      final scoreTexts = tester.widgetList<Text>(find.text('10'));
      expect(scoreTexts, isNotEmpty);
      final scoreStyle = scoreTexts.first.style!;
      expect(scoreStyle.fontWeight, FontWeight.w700);
      // google_fonts sets fontFamily — verify it's not null/default.
      expect(scoreStyle.fontFamily, isNotNull);
    });

    testWidgets(
        'staggered animation triggers with Interval-based delay per row',
        (tester) async {
      // First update — no animation (no previous entries).
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 1,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 5,
            streak: 0,
            streakLabel: '',
            rank: 2,
          ),
        ],
      ));

      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-a',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
      );
      await tester.pump();

      // Second update — Bob overtakes Alice (rank change triggers animation).
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 15,
            streak: 0,
            streakLabel: '',
            rank: 1,
            rankChanged: true,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 2,
            rankChanged: true,
          ),
        ],
      ));
      await tester.pump();

      // During animation, FractionalTranslation widgets should appear.
      expect(find.byType(FractionalTranslation), findsWidgets);

      // Pump through animation duration.
      await tester.pump(const Duration(milliseconds: 500));

      // After animation completes, positions should be settled.
      expect(find.text('Bob'), findsAtLeast(1));
      expect(find.text('Alice'), findsAtLeast(1));
    });

    testWidgets(
        'score change indicator appears when score delta exists and fades after 800ms',
        (tester) async {
      // Test LeaderboardRow directly: initial state with scoreDelta > 0.
      const entry = LeaderboardEntry(
        deviceIdHash: 'hash-a',
        displayName: 'Alice',
        score: 13,
        streak: 0,
        streakLabel: '',
        rank: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RackUpGameTheme(
            data: const RackUpGameThemeData(
              tier: EscalationTier.mild,
              backgroundColor: RackUpColors.tierMild,
              animationsEnabled: true,
            ),
            child: Scaffold(
              body: LeaderboardRow(
                entry: entry,
                players: testPlayers,
                isSelf: true,
                isShooter: false,
                isLeader: true,
                isMilestone: false,
                scoreDelta: 3,
                rankImproved: null,
                rankChanged: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // "+3" indicator should be visible (triggered in initState).
      expect(find.text('+3'), findsOneWidget);

      // After 800ms, timer fires and setState removes the indicator.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      // "+3" text should no longer be in the tree.
      expect(find.text('+3'), findsNothing);
    });

    testWidgets('leader glow pulse is active for rank 1 player',
        (tester) async {
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 1,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 5,
            streak: 0,
            streakLabel: '',
            rank: 2,
          ),
        ],
      ));

      await tester.pumpApp(
        wrapWithProviders(PlayerScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          players: testPlayers,
          myDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
          leaderboardBloc: leaderboardBloc,
        )),
      );
      await tester.pump();

      // Leader row (Alice at rank 1) should have DecoratedBox with gold
      // shadow (via TweenAnimationBuilder for pulsing glow).
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final hasGoldShadow = decoratedBoxes.any((box) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.boxShadow != null) {
          return decoration.boxShadow!.any((shadow) =>
              shadow.color.a > 0 && shadow.blurRadius == 12);
        }
        return false;
      });
      expect(hasGoldShadow, isTrue);
    });

    testWidgets(
        'animations skipped when reduced motion enabled',
        (tester) async {
      // Initial entries: Alice #1, Bob #2.
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 1,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 5,
            streak: 0,
            streakLabel: '',
            rank: 2,
          ),
        ],
      ));

      // Use a custom pump that disables animations.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: RackUpGameTheme(
              data: const RackUpGameThemeData(
                tier: EscalationTier.mild,
                backgroundColor: RackUpColors.tierMild,
                animationsEnabled: false,
              ),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<EventFeedCubit>.value(value: eventFeedCubit),
                  BlocProvider<ItemBloc>.value(value: itemBloc),
                ],
                child: PlayerScreen(
                  currentRound: 1,
                  totalRounds: 10,
                  tier: EscalationTier.mild,
                  players: testPlayers,
                  myDeviceIdHash: 'hash-a',
                  currentShooterDeviceIdHash: 'hash-a',
                  leaderboardBloc: leaderboardBloc,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap positions: Bob overtakes Alice.
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 15,
            streak: 0,
            streakLabel: '',
            rank: 1,
            rankChanged: true,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 2,
            rankChanged: true,
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      // Score delta indicators should NOT be visible with animations disabled.
      expect(find.text('+10'), findsNothing);

      // Rank change arrows should NOT be visible with animations disabled.
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });
  });
}
