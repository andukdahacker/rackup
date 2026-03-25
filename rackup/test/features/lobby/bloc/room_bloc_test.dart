import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';

class MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

class MockRoomApiService extends Mock implements RoomApiService {}

class MockWebSocketCubit extends Mock implements WebSocketCubit {}

class MockAppConfig extends Mock implements AppConfig {}

void main() {
  late MockDeviceIdentityService deviceIdentityService;
  late MockRoomApiService roomApiService;
  late MockWebSocketCubit webSocketCubit;
  late MockAppConfig config;

  setUp(() {
    deviceIdentityService = MockDeviceIdentityService();
    roomApiService = MockRoomApiService();
    webSocketCubit = MockWebSocketCubit();
    config = MockAppConfig();

    when(() => deviceIdentityService.getHashedDeviceId())
        .thenReturn('test-hash');
    when(() => config.wsBaseUrl).thenReturn('ws://localhost:8080');
  });

  RoomBloc buildBloc() => RoomBloc(
        deviceIdentityService: deviceIdentityService,
        roomApiService: roomApiService,
        webSocketCubit: webSocketCubit,
        config: config,
      );

  group('RoomBloc', () {
    test('initial state is RoomInitial', () {
      expect(buildBloc().state, const RoomInitial());
    });

    blocTest<RoomBloc, RoomState>(
      'emits [RoomCreating, RoomCreatedState] on success',
      build: () {
        when(() => roomApiService.createRoom('test-hash')).thenAnswer(
          (_) async => const CreateRoomResponse(
            roomCode: 'ABCD',
            jwt: 'test-jwt',
          ),
        );
        when(
          () => webSocketCubit.connect(
            'ws://localhost:8080',
            'test-jwt',
          ),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateRoom()),
      expect: () => [
        const RoomCreating(),
        const RoomCreatedState(roomCode: 'ABCD', jwt: 'test-jwt'),
      ],
      verify: (_) {
        verify(
          () => webSocketCubit.connect('ws://localhost:8080', 'test-jwt'),
        ).called(1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomCreating, RoomError] on API failure',
      build: () {
        when(() => roomApiService.createRoom('test-hash')).thenThrow(
          const RoomApiException(
            statusCode: 503,
            message: 'Server at capacity',
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateRoom()),
      expect: () => [
        const RoomCreating(),
        const RoomError(message: 'Server at capacity'),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomCreating, RoomError] on unexpected exception',
      build: () {
        when(() => roomApiService.createRoom('test-hash'))
            .thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateRoom()),
      expect: () => [
        const RoomCreating(),
        const RoomError(
          message: 'Unable to create room. Please try again.',
        ),
      ],
    );
  });
}
