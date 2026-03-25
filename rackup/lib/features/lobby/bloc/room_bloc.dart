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
}
