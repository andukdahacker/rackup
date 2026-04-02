import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';

void main() {
  group('GameBloc', () {
    final testPlayers = [
      const GamePlayer(
        deviceIdHash: 'hash-a',
        displayName: 'Alice',
        slot: 1,
        score: 0,
        streak: 0,
        isReferee: false,
      ),
      const GamePlayer(
        deviceIdHash: 'hash-b',
        displayName: 'Bob',
        slot: 2,
        score: 0,
        streak: 0,
        isReferee: true,
      ),
    ];

    blocTest<GameBloc, GameState>(
      'emits GameActive with correct state on GameInitialized',
      build: GameBloc.new,
      act: (bloc) => bloc.add(GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'hash-b',
        turnOrder: const ['hash-a', 'hash-b'],
        currentShooterDeviceIdHash: 'hash-a',
        players: testPlayers,
      )),
      expect: () => [
        GameActive(
          roundCount: 10,
          currentRound: 1,
          refereeDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-a',
          turnOrder: const ['hash-a', 'hash-b'],
          players: testPlayers,
          tier: EscalationTier.mild,
        ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'GameActive.tier is mild for round 1 (0% progression)',
      build: GameBloc.new,
      act: (bloc) => bloc.add(GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'hash-b',
        turnOrder: const ['hash-a', 'hash-b'],
        currentShooterDeviceIdHash: 'hash-a',
        players: testPlayers,
      )),
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<GameActive>());
        expect((state as GameActive).tier, EscalationTier.mild);
      },
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted updates player score, streak, and current shooter',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 3,
        newStreak: 1,
        currentShooterHash: 'hash-b',
        currentRound: 1,
        isGameOver: false,
      )),
      expect: () => [
        GameActive(
          roundCount: 10,
          currentRound: 1,
          refereeDeviceIdHash: 'hash-b',
          currentShooterDeviceIdHash: 'hash-b',
          turnOrder: const ['hash-a', 'hash-b'],
          players: [
            const GamePlayer(
              deviceIdHash: 'hash-a',
              displayName: 'Alice',
              slot: 1,
              score: 3,
              streak: 1,
              isReferee: false,
            ),
            const GamePlayer(
              deviceIdHash: 'hash-b',
              displayName: 'Bob',
              slot: 2,
              score: 0,
              streak: 0,
              isReferee: true,
            ),
          ],
          tier: EscalationTier.mild,
        ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted recalculates tier on round change',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 3,
        newStreak: 1,
        currentShooterHash: 'hash-a',
        currentRound: 5,
        isGameOver: false,
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        // Round 5 of 10: (5-1)/10 = 40% → medium tier
        expect(state.tier, EscalationTier.medium);
        expect(state.currentRound, 5);
      },
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted with undo reverts score and shooter',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-b',
        turnOrder: const ['hash-a', 'hash-b'],
        players: [
          const GamePlayer(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            slot: 1,
            score: 3,
            streak: 1,
            isReferee: false,
          ),
          const GamePlayer(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            slot: 2,
            score: 0,
            streak: 0,
            isReferee: true,
          ),
        ],
        tier: EscalationTier.mild,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: '',
        pointsAwarded: 0,
        newScore: 0,
        newStreak: 0,
        currentShooterHash: 'hash-a',
        currentRound: 1,
        isGameOver: false,
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        final alice = state.players.firstWhere(
          (p) => p.deviceIdHash == 'hash-a',
        );
        expect(alice.score, 0);
        expect(alice.streak, 0);
        expect(state.currentShooterDeviceIdHash, 'hash-a');
      },
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted ignored when not in GameActive state',
      build: GameBloc.new,
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 3,
        newStreak: 1,
        currentShooterHash: 'hash-b',
        currentRound: 1,
        isGameOver: false,
      )),
      expect: () => <GameState>[],
    );
  });
}
