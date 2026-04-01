import 'dart:async';
import 'dart:developer' as developer;

import 'package:rackup/core/models/player.dart';
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
    void Function(String code, String message)? onError,
  })  : _subscription = webSocketCubit.messages.listen((message) {
          _handleMessage(message, roomBloc, onError);
        });

  final StreamSubscription<Message> _subscription;

  static void _handleMessage(
    Message message,
    RoomBloc roomBloc,
    void Function(String code, String message)? onError,
  ) {
    try {
      switch (message.action) {
        case Actions.lobbyRoomState:
          final payload = LobbyRoomStatePayload.fromJson(message.payload);
          final players = payload.players.map(mapToPlayer).toList();
          roomBloc.add(RoomStateReceived(
            players: players,
            roomCode: payload.roomCode,
            hostDeviceIdHash: payload.hostDeviceIdHash,
            allReadyOrTimedOut: payload.allReadyOrTimedOut,
          ));

        case Actions.lobbyPlayerJoined:
          final payload = LobbyPlayerPayload.fromJson(message.payload);
          final player = mapToPlayer(payload);
          roomBloc.add(PlayerJoined(player: player));

        case Actions.lobbyPlayerLeft:
          final deviceIdHash = message.payload['deviceIdHash'] as String;
          roomBloc.add(PlayerLeft(deviceIdHash: deviceIdHash));

        case Actions.lobbyPlayerStatusChanged:
          final payload =
              PlayerStatusChangedPayload.fromJson(message.payload);
          final status = switch (payload.status) {
            'writing' => PlayerStatus.writing,
            'ready' => PlayerStatus.ready,
            _ => PlayerStatus.joining,
          };
          roomBloc.add(PlayerStatusChanged(
            deviceIdHash: payload.deviceIdHash,
            status: status,
          ));

        case Actions.lobbyGameStarted:
          final payload = GameStartedPayload.fromJson(message.payload);
          roomBloc.add(GameStarted(roundCount: payload.roundCount));

        case Actions.error:
          final code = message.payload['code'] as String? ?? 'UNKNOWN';
          final errorMessage =
              message.payload['message'] as String? ?? 'Unknown error';
          developer.log(
            'Server error: $code — $errorMessage',
            name: 'LobbyMessageListener',
          );
          onError?.call(code, errorMessage);

        default:
          break;
      }
    } on Object {
      // Malformed lobby payloads are silently dropped to avoid killing
      // the stream subscription. Catches both Exception and Error (e.g.,
      // TypeError from null casts).
    }
  }

  /// Cancels the message subscription.
  void dispose() {
    _subscription.cancel();
  }
}
