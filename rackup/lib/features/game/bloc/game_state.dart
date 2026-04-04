import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/protocol/messages.dart';
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
    this.isTriplePoints = false,
    this.showRecordThis = false,
    this.recordThisSubtext = '',
    this.lastPunishment,
    this.lastCascadeProfile = 'routine',
    this.isGameOver = false,
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

  /// Whether the game is in triple-point territory (final 3 rounds).
  final bool isTriplePoints;

  /// Whether a RECORD THIS overlay should be shown.
  final bool showRecordThis;

  /// Descriptive text for the RECORD THIS alert.
  final String recordThisSubtext;

  /// The last punishment drawn (null for MADE shots).
  final PunishmentPayload? lastPunishment;

  /// Cascade timing profile for the last punishment.
  final String lastCascadeProfile;

  /// Whether this is the final turn and the game should end after punishment
  /// delivery. When true, the referee sees the punishment card first, then
  /// game-over navigation fires after "Delivered" tap.
  final bool isGameOver;

  /// Creates a copy with the given fields replaced.
  GameActive copyWith({
    int? roundCount,
    int? currentRound,
    String? refereeDeviceIdHash,
    String? currentShooterDeviceIdHash,
    List<String>? turnOrder,
    List<GamePlayer>? players,
    EscalationTier? tier,
    bool? isTriplePoints,
    bool? showRecordThis,
    String? recordThisSubtext,
    PunishmentPayload? lastPunishment,
    String? lastCascadeProfile,
    bool? isGameOver,
  }) {
    return GameActive(
      roundCount: roundCount ?? this.roundCount,
      currentRound: currentRound ?? this.currentRound,
      refereeDeviceIdHash: refereeDeviceIdHash ?? this.refereeDeviceIdHash,
      currentShooterDeviceIdHash:
          currentShooterDeviceIdHash ?? this.currentShooterDeviceIdHash,
      turnOrder: turnOrder ?? this.turnOrder,
      players: players ?? this.players,
      tier: tier ?? this.tier,
      isTriplePoints: isTriplePoints ?? this.isTriplePoints,
      showRecordThis: showRecordThis ?? this.showRecordThis,
      recordThisSubtext: recordThisSubtext ?? this.recordThisSubtext,
      lastPunishment: lastPunishment ?? this.lastPunishment,
      lastCascadeProfile: lastCascadeProfile ?? this.lastCascadeProfile,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }

  @override
  List<Object?> get props => [
        roundCount,
        currentRound,
        refereeDeviceIdHash,
        currentShooterDeviceIdHash,
        turnOrder,
        players,
        tier,
        isTriplePoints,
        showRecordThis,
        recordThisSubtext,
        lastPunishment,
        lastCascadeProfile,
        isGameOver,
      ];
}

/// Terminal state — game has ended. No more transitions to [GameActive].
class GameEnded extends GameState {
  const GameEnded({
    required this.players,
    required this.roundCount,
    required this.refereeDeviceIdHash,
  });

  /// All players with their final scores.
  final List<GamePlayer> players;

  /// Total number of rounds played.
  final int roundCount;

  /// The referee's device ID hash.
  final String refereeDeviceIdHash;

  @override
  List<Object?> get props => [players, roundCount, refereeDeviceIdHash];
}
