import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';

void main() {
  group('WebSocketCubit', () {
    test('initial state is WebSocketDisconnected', () async {
      final cubit = WebSocketCubit();
      expect(cubit.state, isA<WebSocketDisconnected>());
      await cubit.close();
    });
  });
}
