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
    on<GameEndReceived>(_onGameEndReceived);
    on<RecordThisReceived>(_onRecordThisReceived);
    on<RecordThisDismissed>(_onRecordThisDismissed);
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
      // P7: Set correctly at init so games with <=3 rounds don't cause
      // a spurious false→true transition on first turn_complete.
      isTriplePoints: initialRound > event.roundCount - 3,
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

    if (event.isGameOver) {
      emit(GameEnded(
        players: updatedPlayers,
        roundCount: current.roundCount,
        refereeDeviceIdHash: current.refereeDeviceIdHash,
      ));
      return;
    }

    emit(current.copyWith(
      currentShooterDeviceIdHash: event.currentShooterHash,
      currentRound: event.currentRound,
      players: updatedPlayers,
      tier: tier,
      isTriplePoints: event.isTriplePoints,
      showRecordThis: false,
      recordThisSubtext: '',
    ));
  }

  void _onGameEndReceived(
    GameEndReceived event,
    Emitter<GameState> emit,
  ) {
    final current = state;
    if (current is GameEnded) return; // Already in terminal state.
    if (current is GameActive) {
      emit(GameEnded(
        players: current.players,
        roundCount: current.roundCount,
        refereeDeviceIdHash: current.refereeDeviceIdHash,
      ));
    }
  }

  void _onRecordThisReceived(
    RecordThisReceived event,
    Emitter<GameState> emit,
  ) {
    final current = state;
    if (current is! GameActive) return;
    emit(current.copyWith(
      showRecordThis: true,
      recordThisSubtext: event.subtext,
    ));
  }

  void _onRecordThisDismissed(
    RecordThisDismissed event,
    Emitter<GameState> emit,
  ) {
    final current = state;
    if (current is! GameActive) return;
    emit(current.copyWith(
      showRecordThis: false,
      recordThisSubtext: '',
    ));
  }
}
