import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/audio/audio_listener.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

class MockSoundManager extends Mock implements SoundManager {}

class MockLeaderboardBloc
    extends MockBloc<LeaderboardEvent, LeaderboardState>
    implements LeaderboardBloc {}

void main() {
  late MockSoundManager mockSoundManager;
  late MockLeaderboardBloc mockLeaderboardBloc;
  late StreamController<LeaderboardState> stateController;

  setUpAll(() {
    registerFallbackValue(GameSound.streakFire);
  });

  setUp(() {
    mockSoundManager = MockSoundManager();
    mockLeaderboardBloc = MockLeaderboardBloc();
    stateController = StreamController<LeaderboardState>.broadcast();
    when(() => mockSoundManager.play(any())).thenAnswer((_) async {});
    when(() => mockLeaderboardBloc.state)
        .thenReturn(const LeaderboardInitial());
    whenListen(
      mockLeaderboardBloc,
      stateController.stream,
      initialState: const LeaderboardInitial(),
    );
  });

  tearDown(() {
    stateController.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<LeaderboardBloc>.value(
        value: mockLeaderboardBloc,
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

      stateController.add(const LeaderboardActive(
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

      stateController.add(const LeaderboardActive(
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

      stateController.add(const LeaderboardActive(
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

      stateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
      ));
      await tester.pump();

      verifyNever(() => mockSoundManager.play(any()));
    });

    testWidgets('does not re-trigger when same flags emitted again',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      stateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
      ));
      await tester.pump();

      // Same state emitted again — should not re-trigger
      stateController.add(const LeaderboardActive(
        entries: [],
        previousEntries: [],
        streakMilestone: true,
      ));
      await tester.pump();

      verify(() => mockSoundManager.play(GameSound.streakFire)).called(1);
    });
  });
}
