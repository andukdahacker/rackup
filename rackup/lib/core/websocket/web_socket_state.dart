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
