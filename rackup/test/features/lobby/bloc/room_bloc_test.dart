import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/protocol/messages.dart'
    show CreateRoomResponse, JoinRoomResponse, Message;
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

class FakeMessage extends Fake implements Message {}

void main() {
  late MockDeviceIdentityService deviceIdentityService;
  late MockRoomApiService roomApiService;
  late MockWebSocketCubit webSocketCubit;
  late MockAppConfig config;

  setUpAll(() {
    registerFallbackValue(FakeMessage());
  });

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

  group('JoinRoom', () {
    blocTest<RoomBloc, RoomState>(
      'emits [RoomJoining, RoomCreatedState] on success',
      build: () {
        when(
          () => roomApiService.joinRoom('ABCD', 'Alice', 'test-hash'),
        ).thenAnswer(
          (_) async => const JoinRoomResponse(jwt: 'join-jwt'),
        );
        when(
          () => webSocketCubit.connect('ws://localhost:8080', 'join-jwt'),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const JoinRoom(code: 'ABCD', displayName: 'Alice')),
      expect: () => [
        const RoomJoining(),
        const RoomCreatedState(roomCode: 'ABCD', jwt: 'join-jwt'),
      ],
      verify: (_) {
        verify(
          () => webSocketCubit.connect('ws://localhost:8080', 'join-jwt'),
        ).called(1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomJoining, RoomError] with ROOM_NOT_FOUND',
      build: () {
        when(
          () => roomApiService.joinRoom('ZZZZ', 'Alice', 'test-hash'),
        ).thenThrow(
          const RoomApiException(
            statusCode: 404,
            message: 'Room not found',
            errorCode: 'ROOM_NOT_FOUND',
          ),
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const JoinRoom(code: 'ZZZZ', displayName: 'Alice')),
      expect: () => [
        const RoomJoining(),
        const RoomError(
          message: 'Room not found — check the code and try again',
        ),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomJoining, RoomError] with ROOM_FULL',
      build: () {
        when(
          () => roomApiService.joinRoom('ABCD', 'Alice', 'test-hash'),
        ).thenThrow(
          const RoomApiException(
            statusCode: 409,
            message: 'Room is full',
            errorCode: 'ROOM_FULL',
          ),
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const JoinRoom(code: 'ABCD', displayName: 'Alice')),
      expect: () => [
        const RoomJoining(),
        const RoomError(message: 'Room is full (max 8 players)'),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'emits [RoomJoining, RoomError] on network exception',
      build: () {
        when(
          () => roomApiService.joinRoom('ABCD', 'Alice', 'test-hash'),
        ).thenThrow(Exception('network error'));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const JoinRoom(code: 'ABCD', displayName: 'Alice')),
      expect: () => [
        const RoomJoining(),
        const RoomError(
          message:
              'Connection failed — check your internet and try again.',
        ),
      ],
    );
  });

  group('Lobby events', () {
    const player1 = Player(
      displayName: 'Jake',
      deviceIdHash: 'hash1',
      slot: 1,
      isHost: true,
      status: PlayerStatus.joining,
    );

    const player2 = Player(
      displayName: 'Danny',
      deviceIdHash: 'hash2',
      slot: 2,
      isHost: false,
      status: PlayerStatus.joining,
    );

    blocTest<RoomBloc, RoomState>(
      'RoomStateReceived transitions from RoomCreatedState to RoomLobby',
      build: buildBloc,
      seed: () => const RoomCreatedState(roomCode: 'ABCD', jwt: 'jwt-123'),
      act: (bloc) => bloc.add(
        const RoomStateReceived(
          players: [player1],
          roomCode: 'ABCD',
        ),
      ),
      expect: () => [
        const RoomLobby(
          players: [player1],
          roomCode: 'ABCD',
          jwt: 'jwt-123',
        ),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerJoined adds player to lobby list',
      build: buildBloc,
      seed: () => const RoomLobby(
        players: [player1],
        roomCode: 'ABCD',
        jwt: 'jwt-123',
      ),
      act: (bloc) => bloc.add(const PlayerJoined(player: player2)),
      expect: () => [
        const RoomLobby(
          players: [player1, player2],
          roomCode: 'ABCD',
          jwt: 'jwt-123',
        ),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerJoined replaces existing player on reconnect (no duplicate)',
      build: buildBloc,
      seed: () => const RoomLobby(
        players: [player1, player2],
        roomCode: 'ABCD',
        jwt: 'jwt-123',
      ),
      act: (bloc) => bloc.add(const PlayerJoined(player: player2)),
      // Same player list equals same state — Equatable prevents emit.
      expect: () => <RoomState>[],
      verify: (bloc) {
        final state = bloc.state as RoomLobby;
        // Verify no duplicates.
        final count = state.players
            .where((p) => p.deviceIdHash == 'hash2')
            .length;
        expect(count, 1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerLeft removes player from lobby list',
      build: buildBloc,
      seed: () => const RoomLobby(
        players: [player1, player2],
        roomCode: 'ABCD',
        jwt: 'jwt-123',
      ),
      act: (bloc) => bloc.add(const PlayerLeft(deviceIdHash: 'hash2')),
      expect: () => [
        const RoomLobby(
          players: [player1],
          roomCode: 'ABCD',
          jwt: 'jwt-123',
        ),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerLeft does nothing when not in RoomLobby state',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlayerLeft(deviceIdHash: 'hash2')),
      expect: () => <RoomState>[],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerJoined does nothing when not in RoomLobby state',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlayerJoined(player: player1)),
      expect: () => <RoomState>[],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerStatusChanged updates player status in lobby',
      build: buildBloc,
      seed: () => const RoomLobby(
        players: [player1, player2],
        roomCode: 'ABCD',
        jwt: 'jwt-123',
      ),
      act: (bloc) => bloc.add(const PlayerStatusChanged(
        deviceIdHash: 'hash2',
        status: PlayerStatus.writing,
      )),
      expect: () => [
        const RoomLobby(
          players: [
            player1,
            Player(
              displayName: 'Danny',
              deviceIdHash: 'hash2',
              slot: 2,
              isHost: false,
              status: PlayerStatus.writing,
            ),
          ],
          roomCode: 'ABCD',
          jwt: 'jwt-123',
        ),
      ],
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerStatusChanged does nothing when not in RoomLobby state',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlayerStatusChanged(
        deviceIdHash: 'hash1',
        status: PlayerStatus.ready,
      )),
      expect: () => <RoomState>[],
    );

    blocTest<RoomBloc, RoomState>(
      'PunishmentSubmitted sends message via WebSocket',
      build: () {
        when(() => webSocketCubit.sendMessage(any())).thenReturn(null);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PunishmentSubmitted(text: 'Do a dance')),
      expect: () => <RoomState>[],
      verify: (_) {
        verify(() => webSocketCubit.sendMessage(any())).called(1);
      },
    );

    blocTest<RoomBloc, RoomState>(
      'PlayerStatusChanged updates to ready status',
      build: buildBloc,
      seed: () => const RoomLobby(
        players: [player1],
        roomCode: 'ABCD',
        jwt: 'jwt-123',
      ),
      act: (bloc) => bloc.add(const PlayerStatusChanged(
        deviceIdHash: 'hash1',
        status: PlayerStatus.ready,
      )),
      expect: () => [
        const RoomLobby(
          players: [
            Player(
              displayName: 'Jake',
              deviceIdHash: 'hash1',
              slot: 1,
              isHost: true,
              status: PlayerStatus.ready,
            ),
          ],
          roomCode: 'ABCD',
          jwt: 'jwt-123',
        ),
      ],
    );
  });
}
