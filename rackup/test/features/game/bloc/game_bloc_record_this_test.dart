import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';

void main() {
  group('GameBloc — RECORD THIS', () {
    const activeState = GameActive(
      roundCount: 10,
      currentRound: 3,
      refereeDeviceIdHash: 'ref',
      currentShooterDeviceIdHash: 'shooter',
      turnOrder: ['shooter'],
      players: [],
      tier: EscalationTier.mild,
    );

    blocTest<GameBloc, GameState>(
      'RecordThisReceived sets showRecordThis=true and subtext',
      build: GameBloc.new,
      seed: () => activeState,
      act: (bloc) => bloc.add(const RecordThisReceived(
        subtext: "Alex's streak just got broken!",
        targetHash: 'shooter',
      )),
      expect: () => [
        activeState.copyWith(
          showRecordThis: true,
          recordThisSubtext: "Alex's streak just got broken!",
        ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'RecordThisDismissed resets showRecordThis=false',
      build: GameBloc.new,
      seed: () => activeState.copyWith(
        showRecordThis: true,
        recordThisSubtext: "Alex's streak just got broken!",
      ),
      act: (bloc) => bloc.add(const RecordThisDismissed()),
      expect: () => [
        activeState.copyWith(
          showRecordThis: false,
          recordThisSubtext: '',
        ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'RecordThisReceived ignored when not in GameActive state',
      build: GameBloc.new,
      // Initial state is GameInitial.
      act: (bloc) => bloc.add(const RecordThisReceived(
        subtext: 'test',
        targetHash: 'hash',
      )),
      expect: () => <GameState>[],
    );

    blocTest<GameBloc, GameState>(
      'RecordThisDismissed ignored when not in GameActive state',
      build: GameBloc.new,
      act: (bloc) => bloc.add(const RecordThisDismissed()),
      expect: () => <GameState>[],
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted resets showRecordThis to false',
      build: GameBloc.new,
      seed: () => activeState.copyWith(
        showRecordThis: true,
        recordThisSubtext: "Alex's streak just got broken!",
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'shooter',
        result: 'made',
        pointsAwarded: 3,
        newScore: 10,
        newStreak: 1,
        currentShooterHash: 'shooter',
        currentRound: 4,
        isGameOver: false,
        streakLabel: '',
        streakMilestone: false,
        leaderboard: [],
        cascadeProfile: 'routine',
        isTriplePoints: false,
      )),
      expect: () => [
        isA<GameActive>()
            .having((s) => s.showRecordThis, 'showRecordThis', false)
            .having((s) => s.recordThisSubtext, 'recordThisSubtext', '')
            .having((s) => s.currentRound, 'currentRound', 4),
      ],
    );
  });
}
