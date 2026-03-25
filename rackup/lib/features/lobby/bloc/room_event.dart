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
