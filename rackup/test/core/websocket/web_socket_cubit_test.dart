import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/websocket/reconnection_handler.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';

void main() {
  group('WebSocketCubit', () {
    late WebSocketCubit cubit;

    setUp(() {
      cubit = WebSocketCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initial state is WebSocketDisconnected', () {
      expect(cubit.state, isA<WebSocketDisconnected>());
    });

    test('disconnect emits WebSocketDisconnected', () async {
      await cubit.disconnect();
      expect(cubit.state, isA<WebSocketDisconnected>());
    });

    test('close cleans up without error', () async {
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });
  });

  group('ReconnectionHandler', () {
    test('starts with attempt 0', () {
      final handler = ReconnectionHandler();
      expect(handler.attempt, 0);
      expect(handler.elapsedSeconds, 0);
      expect(handler.isExhausted, isFalse);
    });

    test('scheduleReconnect increments attempt', () {
      final handler = ReconnectionHandler()
        ..scheduleReconnect(() {});
      expect(handler.attempt, 1);
      handler.cancel();
    });

    test('reset clears state', () {
      final handler = ReconnectionHandler()
        ..scheduleReconnect(() {})
        ..reset();
      expect(handler.attempt, 0);
      expect(handler.elapsedSeconds, 0);
    });

    test('cancel stops pending timer', () {
      final handler = ReconnectionHandler()
        ..scheduleReconnect(() {})
        ..cancel();
      expect(handler.attempt, 1);
    });
  });
}
