import 'package:bloc/bloc.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';

/// Manages the room creation flow.
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  /// Creates a [RoomBloc].
  RoomBloc({
    required DeviceIdentityService deviceIdentityService,
    required RoomApiService roomApiService,
    required WebSocketCubit webSocketCubit,
    required AppConfig config,
  })  : _deviceIdentityService = deviceIdentityService,
        _roomApiService = roomApiService,
        _webSocketCubit = webSocketCubit,
        _config = config,
        super(const RoomInitial()) {
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
    on<RoomStateReceived>(_onRoomStateReceived);
    on<PlayerJoined>(_onPlayerJoined);
    on<PlayerLeft>(_onPlayerLeft);
    on<ResetRoom>(_onResetRoom);
  }

  final DeviceIdentityService _deviceIdentityService;
  final RoomApiService _roomApiService;
  final WebSocketCubit _webSocketCubit;
  final AppConfig _config;

  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<RoomState> emit,
  ) async {
    emit(const RoomCreating());

    try {
      final deviceIdHash = _deviceIdentityService.getHashedDeviceId();
      final response = await _roomApiService.createRoom(deviceIdHash);

      // Trigger WebSocket connection before emitting success.
      try {
        await _webSocketCubit.connect(_config.wsBaseUrl, response.jwt);
      } on Object {
        // WebSocket handles reconnection internally; emit success regardless
        // since the room was created on the server.
      }

      emit(RoomCreatedState(roomCode: response.roomCode, jwt: response.jwt));
    } on RoomApiException catch (e) {
      emit(RoomError(message: e.message));
    } on Exception {
      emit(
        const RoomError(
          message: 'Unable to create room. Please try again.',
        ),
      );
    }
  }

  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<RoomState> emit,
  ) async {
    emit(const RoomJoining());

    try {
      final deviceIdHash = _deviceIdentityService.getHashedDeviceId();
      final response = await _roomApiService.joinRoom(
        event.code,
        event.displayName,
        deviceIdHash,
      );

      try {
        await _webSocketCubit.connect(_config.wsBaseUrl, response.jwt);
      } on Object {
        // WebSocket handles reconnection internally; emit success regardless.
      }

      emit(RoomCreatedState(roomCode: event.code, jwt: response.jwt));
    } on RoomApiException catch (e) {
      final message = switch (e.errorCode) {
        'ROOM_NOT_FOUND' =>
          'Room not found — check the code and try again',
        'ROOM_FULL' => 'Room is full (max 8 players)',
        _ => e.message,
      };
      emit(RoomError(message: message));
    } on Exception {
      emit(
        const RoomError(
          message: 'Connection failed — check your internet and try again.',
        ),
      );
    }
  }

  void _onRoomStateReceived(
    RoomStateReceived event,
    Emitter<RoomState> emit,
  ) {
    final currentState = state;
    final String? jwt = switch (currentState) {
      RoomCreatedState(:final jwt) => jwt,
      RoomLobby(:final jwt) => jwt,
      _ => null,
    };
    // Only transition to lobby if we have a valid JWT.
    if (jwt == null) return;
    emit(RoomLobby(
      players: event.players,
      roomCode: event.roomCode,
      jwt: jwt,
    ));
  }

  void _onPlayerJoined(PlayerJoined event, Emitter<RoomState> emit) {
    final currentState = state;
    if (currentState is RoomLobby) {
      // Replace if player already exists (reconnect), otherwise add.
      final updatedPlayers = currentState.players
          .where((p) => p.deviceIdHash != event.player.deviceIdHash)
          .toList()
        ..add(event.player);
      emit(RoomLobby(
        players: updatedPlayers,
        roomCode: currentState.roomCode,
        jwt: currentState.jwt,
      ));
    }
  }

  void _onPlayerLeft(PlayerLeft event, Emitter<RoomState> emit) {
    final currentState = state;
    if (currentState is RoomLobby) {
      final updatedPlayers = currentState.players
          .where((p) => p.deviceIdHash != event.deviceIdHash)
          .toList();
      emit(RoomLobby(
        players: updatedPlayers,
        roomCode: currentState.roomCode,
        jwt: currentState.jwt,
      ));
    }
  }

  void _onResetRoom(ResetRoom event, Emitter<RoomState> emit) {
    emit(const RoomInitial());
  }
}
