import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/game_message_listener.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';

class MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  @override
  Stream<Message> get messages => _messageController.stream;

  void emitMessage(Message message) {
    _messageController.add(message);
  }

  void disposeController() {
    _messageController.close();
  }
}

void main() {
  group('GameMessageListener', () {
    late MockWebSocketCubit mockWsCubit;
    late GameBloc gameBloc;

    setUp(() {
      mockWsCubit = MockWebSocketCubit();
      gameBloc = GameBloc();
    });

    tearDown(() {
      gameBloc.close();
      mockWsCubit.disposeController();
    });

    test('gameInitialized message dispatches GameInitialized event',
        () async {
      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.initialized',
        payload: {
          'roundCount': 10,
          'refereeDeviceIdHash': 'ref-hash',
          'turnOrder': ['hash-a', 'hash-b'],
          'currentShooterDeviceIdHash': 'hash-a',
          'players': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'slot': 1,
              'score': 0,
              'streak': 0,
              'isReferee': false,
            },
            {
              'deviceIdHash': 'hash-b',
              'displayName': 'Bob',
              'slot': 2,
              'score': 0,
              'streak': 0,
              'isReferee': true,
            },
          ],
        },
      ));

      // Allow the stream event to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(gameBloc.state, isA<GameActive>());
      final state = gameBloc.state as GameActive;
      expect(state.roundCount, 10);
      expect(state.refereeDeviceIdHash, 'ref-hash');
      expect(state.players.length, 2);

      listener.dispose();
    });
  });
}
