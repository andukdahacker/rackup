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
    this.streakLabel = '',
    this.streakMilestone = false,
    this.leaderboard = const [],
    this.cascadeProfile = 'routine',
    this.isTriplePoints = false,
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

  /// Streak label: "", "warming_up", "on_fire", "unstoppable".
  final String streakLabel;

  /// True when streak threshold was just crossed.
  final bool streakMilestone;

  /// Leaderboard snapshot from server.
  final List<LeaderboardEntry> leaderboard;

  /// Cascade timing profile.
  final String cascadeProfile;

  /// Whether the game is in triple-point territory (final 3 rounds).
  final bool isTriplePoints;

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
        streakLabel,
        streakMilestone,
        leaderboard,
        cascadeProfile,
        isTriplePoints,
      ];
}

/// A leaderboard entry from the server, used in events.
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.deviceIdHash,
    required this.displayName,
    required this.score,
    required this.streak,
    required this.streakLabel,
    required this.rank,
    this.rankChanged = false,
  });

  final String deviceIdHash;
  final String displayName;
  final int score;
  final int streak;
  final String streakLabel;
  final int rank;
  final bool rankChanged;

  @override
  List<Object?> get props =>
      [deviceIdHash, displayName, score, streak, streakLabel, rank, rankChanged];
}

/// Game end confirmation received from server (safety net).
class GameEndReceived extends GameEvent {
  const GameEndReceived();
}

/// A "RECORD THIS" moment was detected by the server.
class RecordThisReceived extends GameEvent {
  const RecordThisReceived({
    required this.subtext,
    required this.targetHash,
  });

  /// Descriptive text for the alert overlay.
  final String subtext;

  /// Device ID hash of the target player (excluded from alert).
  final String targetHash;

  @override
  List<Object?> get props => [subtext, targetHash];
}

/// Resets the RECORD THIS overlay flag after it dismisses.
class RecordThisDismissed extends GameEvent {
  const RecordThisDismissed();
}
