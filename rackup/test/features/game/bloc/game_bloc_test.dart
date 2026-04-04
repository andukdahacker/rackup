import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/protocol/messages.dart';
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
      'GameTurnCompleted sets isTriplePoints from event',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 7,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.medium,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 9,
        newScore: 9,
        newStreak: 1,
        currentShooterHash: 'hash-b',
        currentRound: 8,
        isGameOver: false,
        isTriplePoints: true,
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.isTriplePoints, isTrue);
        expect(state.currentRound, 8);
      },
    );

    blocTest<GameBloc, GameState>(
      'isTriplePoints defaults to false when not set',
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
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.isTriplePoints, isFalse);
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

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted carries punishment field and sets lastPunishment on GameActive',
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
        result: 'missed',
        pointsAwarded: 0,
        newScore: 0,
        newStreak: 0,
        currentShooterHash: 'hash-b',
        currentRound: 1,
        isGameOver: false,
        cascadeProfile: 'streak_milestone',
        punishment: PunishmentPayload(text: 'Do 5 pushups', tier: 'mild'),
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.lastPunishment, isNotNull);
        expect(state.lastPunishment!.text, 'Do 5 pushups');
        expect(state.lastPunishment!.tier, 'mild');
        expect(state.lastCascadeProfile, 'streak_milestone');
      },
    );

    blocTest<GameBloc, GameState>(
      'GameTurnCompleted sets lastPunishment to null on MADE shots (direct constructor clears it)',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
        lastPunishment: const PunishmentPayload(
          text: 'Previous punishment',
          tier: 'medium',
        ),
        lastCascadeProfile: 'item_punishment',
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 3,
        newStreak: 1,
        currentShooterHash: 'hash-b',
        currentRound: 2,
        isGameOver: false,
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.lastPunishment, isNull);
        expect(state.lastCascadeProfile, 'routine');
      },
    );

    blocTest<GameBloc, GameState>(
      'RecordThisReceived copyWith preserves existing lastPunishment',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
        lastPunishment: const PunishmentPayload(
          text: 'Existing punishment',
          tier: 'spicy',
        ),
        lastCascadeProfile: 'spicy',
      ),
      act: (bloc) => bloc.add(const RecordThisReceived(
        subtext: 'On fire!',
        targetHash: 'hash-c',
      )),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.showRecordThis, isTrue);
        // copyWith preserves punishment fields.
        expect(state.lastPunishment, isNotNull);
        expect(state.lastPunishment!.text, 'Existing punishment');
        expect(state.lastCascadeProfile, 'spicy');
      },
    );

    blocTest<GameBloc, GameState>(
      'RecordThisDismissed copyWith preserves existing lastPunishment',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 1,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
        showRecordThis: true,
        recordThisSubtext: 'On fire!',
        lastPunishment: const PunishmentPayload(
          text: 'Still here',
          tier: 'medium',
        ),
        lastCascadeProfile: 'item_punishment',
      ),
      act: (bloc) => bloc.add(const RecordThisDismissed()),
      verify: (bloc) {
        final state = bloc.state as GameActive;
        expect(state.showRecordThis, isFalse);
        expect(state.lastPunishment, isNotNull);
        expect(state.lastPunishment!.text, 'Still here');
        expect(state.lastCascadeProfile, 'item_punishment');
      },
    );

    blocTest<GameBloc, GameState>(
      'game-over with punishment emits GameActive(isGameOver: true) instead of GameEnded',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 10,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.spicy,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'missed',
        pointsAwarded: 0,
        newScore: 0,
        newStreak: 0,
        currentShooterHash: 'hash-b',
        currentRound: 10,
        isGameOver: true,
        cascadeProfile: 'spicy',
        punishment: PunishmentPayload(text: 'Final punishment', tier: 'spicy'),
      )),
      verify: (bloc) {
        expect(bloc.state, isA<GameActive>());
        final state = bloc.state as GameActive;
        expect(state.isGameOver, isTrue);
        expect(state.lastPunishment!.text, 'Final punishment');
        expect(state.lastCascadeProfile, 'spicy');
      },
    );

    blocTest<GameBloc, GameState>(
      'game-over without punishment emits GameEnded immediately',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 10,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.spicy,
      ),
      act: (bloc) => bloc.add(const GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'made',
        pointsAwarded: 3,
        newScore: 3,
        newStreak: 1,
        currentShooterHash: 'hash-b',
        currentRound: 10,
        isGameOver: true,
      )),
      expect: () => [isA<GameEnded>()],
    );

    blocTest<GameBloc, GameState>(
      'GameEndConfirmed transitions GameActive(isGameOver: true) to GameEnded',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 10,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.spicy,
        isGameOver: true,
        lastPunishment: const PunishmentPayload(
          text: 'Punishment',
          tier: 'spicy',
        ),
      ),
      act: (bloc) => bloc.add(const GameEndConfirmed()),
      expect: () => [isA<GameEnded>()],
    );

    blocTest<GameBloc, GameState>(
      'GameEndConfirmed does nothing when isGameOver is false',
      build: GameBloc.new,
      seed: () => GameActive(
        roundCount: 10,
        currentRound: 5,
        refereeDeviceIdHash: 'hash-b',
        currentShooterDeviceIdHash: 'hash-a',
        turnOrder: const ['hash-a', 'hash-b'],
        players: testPlayers,
        tier: EscalationTier.mild,
      ),
      act: (bloc) => bloc.add(const GameEndConfirmed()),
      expect: () => <GameState>[],
    );

    test('GameTurnCompleted event carries punishment in props', () {
      const event = GameTurnCompleted(
        shooterHash: 'hash-a',
        result: 'missed',
        pointsAwarded: 0,
        newScore: 0,
        newStreak: 0,
        currentShooterHash: 'hash-b',
        currentRound: 1,
        isGameOver: false,
        punishment: PunishmentPayload(text: 'Test', tier: 'mild'),
      );
      expect(event.punishment, isNotNull);
      expect(event.punishment!.text, 'Test');
      expect(event.props, contains(event.punishment));
    });

    test('PunishmentPayload equality compares by value', () {
      const a = PunishmentPayload(text: 'Do 5 pushups', tier: 'mild');
      const b = PunishmentPayload(text: 'Do 5 pushups', tier: 'mild');
      const c = PunishmentPayload(text: 'Different', tier: 'mild');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
