import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/reconnection_handler.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages the WebSocket connection lifecycle.
///
/// States: Disconnected → Connecting → Connected → Reconnecting.
/// After 60s of failed reconnection → ConnectionFailed.
class WebSocketCubit extends Cubit<WebSocketState> {
  /// Creates a [WebSocketCubit].
  WebSocketCubit() : super(const WebSocketDisconnected());

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final ReconnectionHandler _reconnectionHandler = ReconnectionHandler();
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  String? _wsUrl;
  String? _jwt;

  /// Stream of parsed [Message] objects received from the WebSocket.
  Stream<Message> get messages => _messageController.stream;

  /// Connects to the WebSocket server.
  Future<void> connect(String wsUrl, String jwt) async {
    _wsUrl = wsUrl;
    _jwt = jwt;
    _reconnectionHandler.reset();

    await _doConnect(wsUrl, jwt);
  }

  Future<void> _doConnect(String wsUrl, String jwt) async {
    if (isClosed) return;
    emit(const WebSocketConnecting());

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('$wsUrl/ws'),
        headers: <String, dynamic>{'Authorization': 'Bearer $jwt'},
      );

      await _channel!.ready;

      emit(WebSocketConnected(_channel!));
      _reconnectionHandler.reset();

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } on Exception {
      _attemptReconnect();
    }
  }

  void _onMessage(dynamic data) {
    if (data is String) {
      try {
        final message = Message.fromRawJson(data);
        _messageController.add(message);
      } on FormatException {
        // Malformed messages are silently dropped.
      }
    }
  }

  void _onError(Object error) {
    _attemptReconnect();
  }

  void _onDone() {
    if (state is WebSocketDisconnected || state is WebSocketConnectionFailed) {
      return;
    }
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (isClosed) return;
    if (_wsUrl == null || _jwt == null) {
      emit(const WebSocketConnectionFailed('No connection parameters'));
      return;
    }

    final scheduled = _reconnectionHandler.scheduleReconnect(() async {
      await _doConnect(_wsUrl!, _jwt!);
    });

    if (scheduled) {
      emit(
        WebSocketReconnecting(
          attempt: _reconnectionHandler.attempt,
          elapsedSeconds: _reconnectionHandler.elapsedSeconds,
        ),
      );
    } else {
      emit(const WebSocketConnectionFailed(
        'Connection lost. Unable to reconnect after 60 seconds.',
      ));
    }
  }

  /// Sends a [Message] over the WebSocket connection.
  void sendMessage(Message message) {
    if (state is WebSocketConnected) {
      _channel?.sink.add(message.toRawJson());
    }
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    _reconnectionHandler.cancel();
    _wsUrl = null;
    _jwt = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    if (!isClosed) {
      emit(const WebSocketDisconnected());
    }
  }

  @override
  Future<void> close() async {
    _reconnectionHandler.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    await _messageController.close();
    return super.close();
  }
}
