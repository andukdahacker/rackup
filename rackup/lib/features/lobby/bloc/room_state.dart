import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/player.dart';

/// States for the RoomBloc.
sealed class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no room operation in progress.
class RoomInitial extends RoomState {
  const RoomInitial();
}

/// Room creation is in progress.
class RoomCreating extends RoomState {
  const RoomCreating();
}

/// Room joining is in progress.
class RoomJoining extends RoomState {
  const RoomJoining();
}

/// Room was created successfully.
class RoomCreatedState extends RoomState {
  const RoomCreatedState({required this.roomCode, required this.jwt});

  /// The 4-character room code.
  final String roomCode;

  /// The JWT for WebSocket authentication.
  final String jwt;

  @override
  List<Object?> get props => [roomCode, jwt];
}

/// Lobby state — room is active and showing player list.
class RoomLobby extends RoomState {
  const RoomLobby({
    required this.players,
    required this.roomCode,
    required this.jwt,
    required this.hostDeviceIdHash,
    this.allReadyOrTimedOut = false,
  });

  /// All players currently in the lobby.
  final List<Player> players;

  /// The 4-character room code.
  final String roomCode;

  /// The JWT for WebSocket authentication.
  final String jwt;

  /// The host's device ID hash.
  final String hostDeviceIdHash;

  /// Whether all punishments are submitted or the timeout has elapsed.
  final bool allReadyOrTimedOut;

  /// Whether all players have submitted punishments (status == ready).
  bool get allPunishmentsReady =>
      players.isNotEmpty &&
      players.every((p) => p.status == PlayerStatus.ready);

  @override
  List<Object?> get props =>
      [players, roomCode, jwt, hostDeviceIdHash, allReadyOrTimedOut];
}

/// Game is starting — transitioning from lobby to game.
class RoomStarting extends RoomState {
  const RoomStarting({required this.roundCount});

  /// The configured number of rounds.
  final int roundCount;

  @override
  List<Object?> get props => [roundCount];
}

/// Room creation failed.
class RoomError extends RoomState {
  const RoomError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
