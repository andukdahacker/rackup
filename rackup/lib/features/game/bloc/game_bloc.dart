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
    on<GameEndConfirmed>(_onGameEndConfirmed);
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
      // When game-over coincides with a punishment, emit GameActive first
      // so the referee can display and announce the punishment card.
      // GameEnded is deferred until punishment delivery (via GameEndConfirmed).
      if (event.punishment != null) {
        emit(GameActive(
          roundCount: current.roundCount,
          currentRound: event.currentRound,
          refereeDeviceIdHash: current.refereeDeviceIdHash,
          currentShooterDeviceIdHash: event.currentShooterHash,
          turnOrder: current.turnOrder,
          players: updatedPlayers,
          tier: tier,
          isTriplePoints: event.isTriplePoints,
          showRecordThis: false,
          recordThisSubtext: '',
          lastPunishment: event.punishment,
          lastCascadeProfile: event.cascadeProfile,
          isGameOver: true,
        ));
        return;
      }
      emit(GameEnded(
        players: updatedPlayers,
        roundCount: current.roundCount,
        refereeDeviceIdHash: current.refereeDeviceIdHash,
      ));
      return;
    }

    // Use direct constructor (not copyWith) so nullable lastPunishment
    // is correctly set to null on MADE shots. copyWith's `?? this.field`
    // pattern cannot clear a non-null value to null.
    emit(GameActive(
      roundCount: current.roundCount,
      currentRound: event.currentRound,
      refereeDeviceIdHash: current.refereeDeviceIdHash,
      currentShooterDeviceIdHash: event.currentShooterHash,
      turnOrder: current.turnOrder,
      players: updatedPlayers,
      tier: tier,
      isTriplePoints: event.isTriplePoints,
      showRecordThis: false,
      recordThisSubtext: '',
      lastPunishment: event.punishment,
      lastCascadeProfile: event.cascadeProfile,
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

  void _onGameEndConfirmed(
    GameEndConfirmed event,
    Emitter<GameState> emit,
  ) {
    final current = state;
    if (current is! GameActive || !current.isGameOver) return;
    emit(GameEnded(
      players: current.players,
      roundCount: current.roundCount,
      refereeDeviceIdHash: current.refereeDeviceIdHash,
    ));
  }
}
