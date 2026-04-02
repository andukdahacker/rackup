import 'package:bloc/bloc.dart';
import 'package:rackup/core/models/game_tier.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';

/// Manages game session state.
class GameBloc extends Bloc<GameEvent, GameState> {
  /// Creates a [GameBloc].
  GameBloc() : super(const GameInitial()) {
    on<GameInitialized>(_onGameInitialized);
    on<GameTurnCompleted>(_onGameTurnCompleted);
  }

  void _onGameInitialized(
    GameInitialized event,
    Emitter<GameState> emit,
  ) {
    const initialRound = 1;
    final tier = computeTier(initialRound, event.roundCount);

    emit(GameActive(
      roundCount: event.roundCount,
      currentRound: initialRound,
      refereeDeviceIdHash: event.refereeDeviceIdHash,
      currentShooterDeviceIdHash: event.currentShooterDeviceIdHash,
      turnOrder: event.turnOrder,
      players: event.players,
      tier: tier,
    ));
  }

  void _onGameTurnCompleted(
    GameTurnCompleted event,
    Emitter<GameState> emit,
  ) {
    final current = state;
    if (current is! GameActive) return;

    // Update the shooter's score and streak.
    final updatedPlayers = current.players.map((player) {
      if (player.deviceIdHash == event.shooterHash) {
        return player.copyWith(
          score: event.newScore,
          streak: event.newStreak,
        );
      }
      return player;
    }).toList();

    final tier = computeTier(event.currentRound, current.roundCount);

    emit(current.copyWith(
      currentShooterDeviceIdHash: event.currentShooterHash,
      currentRound: event.currentRound,
      players: updatedPlayers,
      tier: tier,
    ));
  }
}
