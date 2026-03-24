import 'package:bloc/bloc.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';

/// Manages the WebSocket connection lifecycle.
///
// TODO(story-1.5): Implement WebSocket connection, message routing, and
// reconnection logic.
class WebSocketCubit extends Cubit<WebSocketState> {
  /// Creates a [WebSocketCubit].
  WebSocketCubit() : super(const WebSocketDisconnected());
}
