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
        // Round 1 of 10: (1-1)/10 = 0% → mild tier (game always starts at mild)
        expect((state as GameActive).tier, EscalationTier.mild);
      },
    );
  });
}
