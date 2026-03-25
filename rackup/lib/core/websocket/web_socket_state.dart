import 'package:web_socket_channel/web_socket_channel.dart';

/// State for the WebSocket connection.
sealed class WebSocketState {
  /// Creates a [WebSocketState].
  const WebSocketState();
}

/// The WebSocket is not connected.
class WebSocketDisconnected extends WebSocketState {
  /// Creates a [WebSocketDisconnected].
  const WebSocketDisconnected();
}

/// The WebSocket is connecting.
class WebSocketConnecting extends WebSocketState {
  /// Creates a [WebSocketConnecting].
  const WebSocketConnecting();
}

/// The WebSocket is connected and ready.
class WebSocketConnected extends WebSocketState {
  /// Creates a [WebSocketConnected] with the active [channel].
  const WebSocketConnected(this.channel);

  /// The active WebSocket channel.
  final WebSocketChannel channel;
}

/// The WebSocket is attempting to reconnect.
class WebSocketReconnecting extends WebSocketState {
  /// Creates a [WebSocketReconnecting].
  const WebSocketReconnecting({
    required this.attempt,
    required this.elapsedSeconds,
  });

  /// The current reconnection attempt number.
  final int attempt;

  /// Total seconds elapsed since first disconnect.
  final int elapsedSeconds;
}

/// The WebSocket connection has permanently failed after exhausting
/// reconnection attempts (60 seconds).
class WebSocketConnectionFailed extends WebSocketState {
  /// Creates a [WebSocketConnectionFailed].
  const WebSocketConnectionFailed(this.reason);

  /// Human-readable failure reason.
  final String reason;
}
