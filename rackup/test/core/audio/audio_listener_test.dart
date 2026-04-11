import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/audio/audio_listener.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/features/game/bloc/item_deployment_events_cubit.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

class MockSoundManager extends Mock implements SoundManager {}

class MockLeaderboardBloc
    extends MockBloc<LeaderboardEvent, LeaderboardState>
    implements LeaderboardBloc {}

class MockItemDeploymentEventsCubit
    extends MockCubit<ItemDeploymentEventState>
    implements ItemDeploymentEventsCubit {}

void main() {
  late MockSoundManager mockSoundManager;
  late MockLeaderboardBloc mockLeaderboardBloc;
  late MockItemDeploymentEventsCubit mockItemEvents;
  late StreamController<LeaderboardState> leaderboardStateController;
  late StreamController<ItemDeploymentEventState> itemEventsController;

  setUpAll(() {
    registerFallbackValue(GameSound.streakFire);
  });

  setUp(() {
    mockSoundManager = MockSoundManager();
    mockLeaderboardBloc = MockLeaderboardBloc();
    mockItemEvents = MockItemDeploymentEventsCubit();
    leaderboardStateController =
        StreamController<LeaderboardState>.broadcast();
    itemEventsController =
        StreamController<ItemDeploymentEventState>.broadcast();
    when(() => mockSoundManager.play(any())).thenAnswer((_) async {});
    when(() => mockLeaderboardBloc.state)
        .thenReturn(const LeaderboardInitial());
    when(() => mockItemEvents.state)
        .thenReturn(const ItemDeploymentEventState(sequence: 0));
    whenListen(
      mockLeaderboardBloc,
      leaderboardStateController.stream,
      initialState: const LeaderboardInitial(),
    );
    whenListen(
      mockItemEvents,
      itemEventsController.stream,
      initialState: const ItemDeploymentEventState(sequence: 0),
    );
  });

  tearDown(() {
    leaderboardStateController.close();
    itemEventsController.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LeaderboardBloc>.value(value: mockLeaderboardBloc),
          BlocProvider<ItemDeploymentEventsCubit>.value(value: mockItemEvents),
        ],
        child: AudioListener(
          soundManager: mockSoundManager,
          child: const SizedBox(),
        ),
      ),
    );
  }

  group('AudioListener — leaderboard sounds', () {
    testWidgets('plays streakFire when streakMilestone is true',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.streakFire)).called(1);
      verifyNever(() => mockSoundManager.play(GameSound.leaderboardShuffle));
    });

    testWidgets('plays leaderboardShuffle when shuffleOccurred is true',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        shuffleOccurred: true,
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.leaderboardShuffle))
          .called(1);
      verifyNever(() => mockSoundManager.play(GameSound.streakFire));
    });

    testWidgets('plays both sounds when both flags are true',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
        shuffleOccurred: true,
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.streakFire)).called(1);
      verify(() => mockSoundManager.play(GameSound.leaderboardShuffle))
          .called(1);
    });

    testWidgets('does not play sounds when neither flag is true',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
      ));
      await tester.pump();

      verifyNever(() => mockSoundManager.play(any()));
    });

    testWidgets('does not re-trigger when same flags emitted again',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
      ));
      await tester.pump();

      // Same state emitted again — should not re-trigger
      leaderboardStateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.streakFire)).called(1);
    });
  });

  group('AudioListener — item deployment sounds', () {
    testWidgets('plays itemDeployed when generic item deploys for any client',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      itemEventsController.add(const ItemDeploymentEventState(
        sequence: 1,
        kind: ItemDeploymentEventKind.deployed,
        itemType: 'shield',
        deployerId: 'p1',
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.itemDeployed)).called(1);
      verifyNever(() => mockSoundManager.play(GameSound.blueShellImpact));
    });

    testWidgets('plays blueShellImpact when blue shell deploys', (tester) async {
      await tester.pumpWidget(buildSubject());

      itemEventsController.add(const ItemDeploymentEventState(
        sequence: 1,
        kind: ItemDeploymentEventKind.deployed,
        itemType: 'blue_shell',
        deployerId: 'p1',
        targetId: 'p2',
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.blueShellImpact))
          .called(1);
      verifyNever(() => mockSoundManager.play(GameSound.itemDeployed));
    });

    testWidgets('does not play sound on fizzle event', (tester) async {
      await tester.pumpWidget(buildSubject());

      itemEventsController.add(const ItemDeploymentEventState(
        sequence: 1,
        kind: ItemDeploymentEventKind.fizzled,
        itemType: 'shield',
        reason: 'INVALID_TARGET',
      ));
      await tester.pump();

      verifyNever(() => mockSoundManager.play(GameSound.itemDeployed));
      verifyNever(() => mockSoundManager.play(GameSound.blueShellImpact));
    });

    testWidgets(
        'plays sound again for repeated identical events (sequence bumps)',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      itemEventsController.add(const ItemDeploymentEventState(
        sequence: 1,
        kind: ItemDeploymentEventKind.deployed,
        itemType: 'shield',
        deployerId: 'p1',
      ));
      await tester.pump();

      itemEventsController.add(const ItemDeploymentEventState(
        sequence: 2,
        kind: ItemDeploymentEventKind.deployed,
        itemType: 'shield',
        deployerId: 'p1',
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.itemDeployed)).called(2);
    });
  });
}
