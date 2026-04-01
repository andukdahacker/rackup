import 'package:equatable/equatable.dart';

/// A player during the game phase.
///
/// Distinct from lobby [Player] — includes score, streak, and referee status
/// but drops lobby-specific status. Maps from [GamePlayerPayload] via
/// `mapper.dart`.
class GamePlayer extends Equatable {
  /// Creates a [GamePlayer].
  const GamePlayer({
    required this.deviceIdHash,
    required this.displayName,
    required this.slot,
    required this.score,
    required this.streak,
    required this.isReferee,
  });

  /// SHA-256 hash of the player's device ID.
  final String deviceIdHash;

  /// The player's display name.
  final String displayName;

  /// 1-based slot index (1–8) for color+shape identity.
  final int slot;

  /// The player's current score.
  final int score;

  /// The player's current streak.
  final int streak;

  /// Whether this player is the referee.
  final bool isReferee;

  /// Creates a copy with the given fields replaced.
  GamePlayer copyWith({
    String? deviceIdHash,
    String? displayName,
    int? slot,
    int? score,
    int? streak,
    bool? isReferee,
  }) {
    return GamePlayer(
      deviceIdHash: deviceIdHash ?? this.deviceIdHash,
      displayName: displayName ?? this.displayName,
      slot: slot ?? this.slot,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      isReferee: isReferee ?? this.isReferee,
    );
  }

  @override
  List<Object?> get props =>
      [deviceIdHash, displayName, slot, score, streak, isReferee];
}
