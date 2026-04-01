import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/game_theme.dart';

/// States for the GameBloc.
sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Waiting for game data from server.
class GameInitial extends GameState {
  const GameInitial();
}

/// Game is active with full state.
class GameActive extends GameState {
  const GameActive({
    required this.roundCount,
    required this.currentRound,
    required this.refereeDeviceIdHash,
    required this.currentShooterDeviceIdHash,
    required this.turnOrder,
    required this.players,
    required this.tier,
  });

  /// Total number of rounds.
  final int roundCount;

  /// Current round number (starts at 1).
  final int currentRound;

  /// The referee's device ID hash.
  final String refereeDeviceIdHash;

  /// The current shooter's device ID hash.
  final String currentShooterDeviceIdHash;

  /// Device ID hashes in play order.
  final List<String> turnOrder;

  /// All players with their game state.
  final List<GamePlayer> players;

  /// Current escalation tier.
  final EscalationTier tier;

  @override
  List<Object?> get props => [
        roundCount,
        currentRound,
        refereeDeviceIdHash,
        currentShooterDeviceIdHash,
        turnOrder,
        players,
        tier,
      ];
}
