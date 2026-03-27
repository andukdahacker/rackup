import 'package:equatable/equatable.dart';

/// Player status in the lobby.
///
/// Extensible for Story 2.2 which will add `writing` and `ready` statuses
/// when punishment submission is implemented.
enum PlayerStatus {
  /// Player is joining the lobby.
  joining,
}

/// A player in a game room.
///
/// Immutable domain model used in Bloc states. Maps from protocol payloads
/// via `mapper.dart`.
class Player extends Equatable {
  /// Creates a [Player].
  const Player({
    required this.displayName,
    required this.deviceIdHash,
    required this.slot,
    required this.isHost,
    required this.status,
  });

  /// The player's display name.
  final String displayName;

  /// SHA-256 hash of the player's device ID.
  final String deviceIdHash;

  /// 1-based slot index (1–8) for color+shape identity.
  final int slot;

  /// Whether this player is the room host.
  final bool isHost;

  /// The player's current lobby status.
  final PlayerStatus status;

  @override
  List<Object?> get props => [displayName, deviceIdHash, slot, isHost, status];
}
