import 'package:equatable/equatable.dart';

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

/// Room creation failed.
class RoomError extends RoomState {
  const RoomError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
