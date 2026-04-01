import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/player.dart';

/// Events for the RoomBloc.
sealed class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped "Create Room".
class CreateRoom extends RoomEvent {
  const CreateRoom();
}

/// User tapped "Join" with a room code and display name.
class JoinRoom extends RoomEvent {
  /// Creates a [JoinRoom] event.
  const JoinRoom({required this.code, required this.displayName});

  /// The 4-character room code.
  final String code;

  /// The player's display name.
  final String displayName;

  @override
  List<Object?> get props => [code, displayName];
}

/// Room was created successfully.
class RoomCreated extends RoomEvent {
  const RoomCreated({required this.roomCode, required this.jwt});

  final String roomCode;
  final String jwt;

  @override
  List<Object?> get props => [roomCode, jwt];
}

/// Room creation failed.
class RoomCreateFailed extends RoomEvent {
  const RoomCreateFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// WebSocket connection established after room creation.
class WebSocketConnectedEvent extends RoomEvent {
  const WebSocketConnectedEvent();
}

/// Full room state received from server (lobby.room_state).
class RoomStateReceived extends RoomEvent {
  const RoomStateReceived({
    required this.players,
    required this.roomCode,
    required this.hostDeviceIdHash,
    required this.allReadyOrTimedOut,
  });

  /// All players in the room.
  final List<Player> players;

  /// The room code.
  final String roomCode;

  /// The host's device ID hash.
  final String hostDeviceIdHash;

  /// Whether all punishments are submitted or the timeout has elapsed.
  final bool allReadyOrTimedOut;

  @override
  List<Object?> get props =>
      [players, roomCode, hostDeviceIdHash, allReadyOrTimedOut];
}

/// A new player joined the lobby (lobby.player_joined).
class PlayerJoined extends RoomEvent {
  const PlayerJoined({required this.player});

  /// The player who joined.
  final Player player;

  @override
  List<Object?> get props => [player];
}

/// A player left the lobby (lobby.player_left).
class PlayerLeft extends RoomEvent {
  const PlayerLeft({required this.deviceIdHash});

  /// The device ID hash of the player who left.
  final String deviceIdHash;

  @override
  List<Object?> get props => [deviceIdHash];
}

/// A player's lobby status changed (lobby.player_status_changed).
class PlayerStatusChanged extends RoomEvent {
  const PlayerStatusChanged({
    required this.deviceIdHash,
    required this.status,
  });

  /// The device ID hash of the player whose status changed.
  final String deviceIdHash;

  /// The new status.
  final PlayerStatus status;

  @override
  List<Object?> get props => [deviceIdHash, status];
}

/// Player submitted a punishment.
class PunishmentSubmitted extends RoomEvent {
  const PunishmentSubmitted({required this.text});

  /// The punishment text.
  final String text;

  @override
  List<Object?> get props => [text];
}

/// Host requested to start the game (imperative — user action).
class StartGameRequested extends RoomEvent {
  const StartGameRequested({required this.roundCount});

  /// The configured round count (5, 10, or 15).
  final int roundCount;

  @override
  List<Object?> get props => [roundCount];
}

/// Game has started (past tense — server event).
class GameStarted extends RoomEvent {
  const GameStarted({required this.roundCount});

  /// The round count from the server.
  final int roundCount;

  @override
  List<Object?> get props => [roundCount];
}

/// Resets the room state back to initial.
class ResetRoom extends RoomEvent {
  const ResetRoom();
}
