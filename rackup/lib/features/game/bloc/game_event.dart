import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/game_player.dart';

/// Events for the GameBloc.
sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Game initialized — server broadcast with full game state (past tense).
class GameInitialized extends GameEvent {
  const GameInitialized({
    required this.roundCount,
    required this.refereeDeviceIdHash,
    required this.turnOrder,
    required this.currentShooterDeviceIdHash,
    required this.players,
  });

  /// The number of rounds.
  final int roundCount;

  /// The referee's device ID hash.
  final String refereeDeviceIdHash;

  /// Device ID hashes in play order.
  final List<String> turnOrder;

  /// The current shooter's device ID hash.
  final String currentShooterDeviceIdHash;

  /// All players with their game state.
  final List<GamePlayer> players;

  @override
  List<Object?> get props => [
        roundCount,
        refereeDeviceIdHash,
        turnOrder,
        currentShooterDeviceIdHash,
        players,
      ];
}

/// A turn was completed — server broadcast (past tense).
class GameTurnCompleted extends GameEvent {
  const GameTurnCompleted({
    required this.shooterHash,
    required this.result,
    required this.pointsAwarded,
    required this.newScore,
    required this.newStreak,
    required this.currentShooterHash,
    required this.currentRound,
    required this.isGameOver,
  });

  /// The shooter's device ID hash.
  final String shooterHash;

  /// The shot result: "made" or "missed".
  final String result;

  /// Points awarded for this shot.
  final int pointsAwarded;

  /// The shooter's new total score.
  final int newScore;

  /// The shooter's new streak count.
  final int newStreak;

  /// The next shooter's device ID hash.
  final String currentShooterHash;

  /// The current round number.
  final int currentRound;

  /// Whether the game has ended.
  final bool isGameOver;

  @override
  List<Object?> get props => [
        shooterHash,
        result,
        pointsAwarded,
        newScore,
        newStreak,
        currentShooterHash,
        currentRound,
        isGameOver,
      ];
}
