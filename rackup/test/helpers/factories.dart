import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/config/dev_config.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';

/// Creates a default [AppConfig] for testing.
AppConfig createTestConfig() => const DevConfig();

class _MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

class _MockRoomApiService extends Mock implements RoomApiService {}

class _MockWebSocketCubit extends Mock implements WebSocketCubit {}

/// Creates a [RoomBloc] with mock dependencies for testing.
RoomBloc createTestRoomBloc({
  DeviceIdentityService? deviceIdentityService,
  RoomApiService? roomApiService,
  WebSocketCubit? webSocketCubit,
  AppConfig? config,
}) {
  return RoomBloc(
    deviceIdentityService:
        deviceIdentityService ?? _MockDeviceIdentityService(),
    roomApiService: roomApiService ?? _MockRoomApiService(),
    webSocketCubit: webSocketCubit ?? _MockWebSocketCubit(),
    config: config ?? createTestConfig(),
  );
}

/// Creates a mock [RoomApiService] for testing.
RoomApiService createTestRoomApiService() => _MockRoomApiService();
