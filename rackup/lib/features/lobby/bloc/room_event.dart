import 'package:equatable/equatable.dart';

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

/// Resets the room state back to initial.
class ResetRoom extends RoomEvent {
  const ResetRoom();
}
