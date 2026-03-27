import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/lobby_message_listener.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';

class MockWebSocketCubit extends Mock implements WebSocketCubit {}

class MockRoomBloc extends Mock implements RoomBloc {}

void main() {
  late MockWebSocketCubit webSocketCubit;
  late MockRoomBloc roomBloc;
  late StreamController<Message> messageController;

  setUpAll(() {
    registerFallbackValue(const ResetRoom());
  });

  setUp(() {
    webSocketCubit = MockWebSocketCubit();
    roomBloc = MockRoomBloc();
    messageController = StreamController<Message>.broadcast();

    when(() => webSocketCubit.messages).thenAnswer(
      (_) => messageController.stream,
    );
  });

  tearDown(() {
    messageController.close();
  });

  group('LobbyMessageListener', () {
    test('dispatches RoomStateReceived on lobby.room_state', () async {
      final listener = LobbyMessageListener(
        webSocketCubit: webSocketCubit,
        roomBloc: roomBloc,
      );

      messageController.add(Message(
        action: 'lobby.room_state',
        payload: jsonDecode(jsonEncode({
          'roomCode': 'ABCD',
          'hostDeviceIdHash': 'host-hash',
          'players': [
            {
              'displayName': 'Jake',
              'deviceIdHash': 'hash1',
              'slot': 1,
              'isHost': true,
              'status': 'joining',
            },
          ],
        })) as Map<String, dynamic>,
      ));

      // Allow microtask to complete.
      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => roomBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as RoomStateReceived;
      expect(event.roomCode, 'ABCD');
      expect(event.players.length, 1);
      expect(event.players.first.displayName, 'Jake');
      expect(event.players.first.status, PlayerStatus.joining);

      listener.dispose();
    });

    test('dispatches PlayerJoined on lobby.player_joined', () async {
      final listener = LobbyMessageListener(
        webSocketCubit: webSocketCubit,
        roomBloc: roomBloc,
      );

      messageController.add(Message(
        action: 'lobby.player_joined',
        payload: jsonDecode(jsonEncode({
          'displayName': 'Danny',
          'deviceIdHash': 'hash2',
          'slot': 2,
          'isHost': false,
          'status': 'joining',
        })) as Map<String, dynamic>,
      ));

      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => roomBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as PlayerJoined;
      expect(event.player.displayName, 'Danny');
      expect(event.player.slot, 2);

      listener.dispose();
    });

    test('dispatches PlayerLeft on lobby.player_left', () async {
      final listener = LobbyMessageListener(
        webSocketCubit: webSocketCubit,
        roomBloc: roomBloc,
      );

      messageController.add(Message(
        action: 'lobby.player_left',
        payload: <String, dynamic>{'deviceIdHash': 'hash-leaving'},
      ));

      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => roomBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      final event = captured.first as PlayerLeft;
      expect(event.deviceIdHash, 'hash-leaving');

      listener.dispose();
    });

    test('ignores unknown message actions', () async {
      final listener = LobbyMessageListener(
        webSocketCubit: webSocketCubit,
        roomBloc: roomBloc,
      );

      messageController.add(Message(
        action: 'game.turn_complete',
        payload: <String, dynamic>{},
      ));

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => roomBloc.add(any()));

      listener.dispose();
    });

    test('dispose cancels subscription', () async {
      final listener = LobbyMessageListener(
        webSocketCubit: webSocketCubit,
        roomBloc: roomBloc,
      );

      listener.dispose();

      messageController.add(Message(
        action: 'lobby.player_left',
        payload: <String, dynamic>{'deviceIdHash': 'hash'},
      ));

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => roomBloc.add(any()));
    });
  });
}
