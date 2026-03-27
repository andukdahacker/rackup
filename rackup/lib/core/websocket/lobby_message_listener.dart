import 'dart:async';

import 'package:rackup/core/protocol/actions.dart';
import 'package:rackup/core/protocol/mapper.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';

/// Listens to WebSocket messages and dispatches lobby events to [RoomBloc].
///
/// Subscribes to [WebSocketCubit.messages] and routes lobby-related actions
/// to the appropriate RoomBloc events. Keeps WebSocketCubit as a pure
/// connection manager (Option A architecture).
class LobbyMessageListener {
  LobbyMessageListener({
    required WebSocketCubit webSocketCubit,
    required RoomBloc roomBloc,
  })  : _subscription = webSocketCubit.messages.listen((message) {
          _handleMessage(message, roomBloc);
        });

  final StreamSubscription<Message> _subscription;

  static void _handleMessage(Message message, RoomBloc roomBloc) {
    try {
      switch (message.action) {
        case Actions.lobbyRoomState:
          final payload = LobbyRoomStatePayload.fromJson(message.payload);
          final players = payload.players.map(mapToPlayer).toList();
          roomBloc.add(RoomStateReceived(
            players: players,
            roomCode: payload.roomCode,
          ));

        case Actions.lobbyPlayerJoined:
          final payload = LobbyPlayerPayload.fromJson(message.payload);
          final player = mapToPlayer(payload);
          roomBloc.add(PlayerJoined(player: player));

        case Actions.lobbyPlayerLeft:
          final deviceIdHash = message.payload['deviceIdHash'] as String;
          roomBloc.add(PlayerLeft(deviceIdHash: deviceIdHash));

        // Story 2.2: lobby.punishment_submitted handling deferred.
        default:
          break;
      }
    } on Exception {
      // Malformed lobby payloads are silently dropped to avoid killing
      // the stream subscription.
    }
  }

  /// Cancels the message subscription.
  void dispose() {
    _subscription.cancel();
  }
}
