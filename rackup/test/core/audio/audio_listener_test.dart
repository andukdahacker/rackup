import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/audio/audio_listener.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

class MockSoundManager extends Mock implements SoundManager {}

class MockLeaderboardBloc
    extends MockBloc<LeaderboardEvent, LeaderboardState>
    implements LeaderboardBloc {}

class MockItemBloc extends MockBloc<ItemEvent, ItemState>
    implements ItemBloc {}

void main() {
  late MockSoundManager mockSoundManager;
  late MockLeaderboardBloc mockLeaderboardBloc;
  late MockItemBloc mockItemBloc;
  late StreamController<LeaderboardState> leaderboardStateController;
  late StreamController<ItemState> itemStateController;

  const shield = Item(
    type: 'shield',
    displayName: 'Shield',
    accentColorHex: '#14B8A6',
    iconData: Icons.shield,
    requiresTarget: false,
  );
  const blueShell = Item(
    type: 'blue_shell',
    displayName: 'Blue Shell',
    accentColorHex: '#3B82F6',
    iconData: Icons.gps_fixed,
    requiresTarget: true,
  );

  setUpAll(() {
    registerFallbackValue(GameSound.streakFire);
  });

  setUp(() {
    mockSoundManager = MockSoundManager();
    mockLeaderboardBloc = MockLeaderboardBloc();
    mockItemBloc = MockItemBloc();
    leaderboardStateController =
        StreamController<LeaderboardState>.broadcast();
    itemStateController = StreamController<ItemState>.broadcast();
    when(() => mockSoundManager.play(any())).thenAnswer((_) async {});
    when(() => mockLeaderboardBloc.state)
        .thenReturn(const LeaderboardInitial());
    when(() => mockItemBloc.state).thenReturn(const ItemEmpty());
    whenListen(
      mockLeaderboardBloc,
      leaderboardStateController.stream,
      initialState: const LeaderboardInitial(),
    );
    whenListen(
      mockItemBloc,
      itemStateController.stream,
      initialState: const ItemEmpty(),
    );
  });

  tearDown(() {
    leaderboardStateController.close();
    itemStateController.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LeaderboardBloc>.value(value: mockLeaderboardBloc),
          BlocProvider<ItemBloc>.value(value: mockItemBloc),
        ],
        child: AudioListener(
          soundManager: mockSoundManager,
          child: const SizedBox(),
        ),
      ),
    );
  }

  group('AudioListener', () {
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

    testWidgets(
        'plays itemDeployed on server confirmation (Deploying→Empty)',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Transition: ItemDeploying → ItemEmpty (confirmed).
      itemStateController.add(const ItemDeploying(item: shield));
      await tester.pump();
      itemStateController.add(const ItemEmpty());
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.itemDeployed)).called(1);
    });

    testWidgets(
        'plays blueShellImpact on Blue Shell confirmation',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      itemStateController.add(const ItemDeploying(item: blueShell));
      await tester.pump();
      itemStateController.add(const ItemEmpty());
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.blueShellImpact))
          .called(1);
    });

    testWidgets('does not play sound on fizzle', (tester) async {
      await tester.pumpWidget(buildSubject());

      itemStateController.add(const ItemDeploying(item: shield));
      await tester.pump();
      itemStateController
          .add(const ItemFizzled(item: shield, reason: 'TIMEOUT'));
      await tester.pump();

      verifyNever(() => mockSoundManager.play(GameSound.itemDeployed));
      verifyNever(() => mockSoundManager.play(GameSound.blueShellImpact));
    });

    testWidgets('does not play sound on ItemDeploying alone',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      itemStateController.add(const ItemDeploying(item: shield));
      await tester.pump();

      verifyNever(() => mockSoundManager.play(GameSound.itemDeployed));
      verifyNever(() => mockSoundManager.play(GameSound.blueShellImpact));
    });
  });
}
