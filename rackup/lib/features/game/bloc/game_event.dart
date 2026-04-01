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
