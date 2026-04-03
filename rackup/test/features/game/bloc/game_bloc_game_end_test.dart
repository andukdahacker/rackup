import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';

void main() {
  const testPlayers = [
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

  group('GameBloc game end', () {
    blocTest<GameBloc, GameState>(
      'GameTurnCompleted with isGameOver emits GameEnded with final scores',
      build: GameBloc.new,
      seed: () => const GameActive(
        roundCount: 10,
        currentRound: 10,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.spicy,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 30,
        newStreak: 1,
        currentShooterHash: 'hash-a',
        currentRound: 10,
        isGameOver: true,
      )),
      expect: () => [
        isA<GameEnded>()
            .having((s) => s.roundCount, 'roundCount', 10)
            .having((s) => s.refereeDeviceIdHash, 'referee', 'hash-b')
            .having(
              (s) => s.players.first.score,
              'Alice final score',
              30,
            ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'GameEndReceived transitions from GameActive to GameEnded',
      build: GameBloc.new,
      seed: () => const GameActive(
        roundCount: 10,
        currentRound: 10,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.spicy,
      ),
      act: (bloc) => bloc.add(const GameEndReceived()),
      expect: () => [
        isA<GameEnded>()
            .having((s) => s.roundCount, 'roundCount', 10)
            .having((s) => s.players.length, 'players', 2),
      ],
    );

    blocTest<GameBloc, GameState>(
      'GameEndReceived is no-op when already GameEnded',
      build: GameBloc.new,
      seed: () => const GameEnded(
        players: testPlayers,
        roundCount: 10,
        refereeDeviceIdHash: 'hash-b',
      ),
      act: (bloc) => bloc.add(const GameEndReceived()),
      expect: () => <GameState>[],
    );

    blocTest<GameBloc, GameState>(
      'GameEndReceived is no-op when in GameInitial',
      build: GameBloc.new,
      act: (bloc) => bloc.add(const GameEndReceived()),
      expect: () => <GameState>[],
    );
  });
}
