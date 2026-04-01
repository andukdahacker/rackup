import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rackup/core/protocol/actions.dart';
import 'package:rackup/core/protocol/mapper.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';

/// Listens to WebSocket messages and dispatches game events to [GameBloc].
///
/// Subscribes to [WebSocketCubit.messages] and routes game-related actions.
/// Created at the shell level so it receives `game.*` messages even during
/// the lobby→game navigation transition.
class GameMessageListener {
  GameMessageListener({
    required WebSocketCubit webSocketCubit,
    required GameBloc gameBloc,
  }) : _subscription = webSocketCubit.messages.listen((message) {
          _handleMessage(message, gameBloc);
        });

  final StreamSubscription<Message> _subscription;

  static void _handleMessage(Message message, GameBloc gameBloc) {
    try {
      switch (message.action) {
        case Actions.gameInitialized:
          final payload =
              GameInitializedPayload.fromJson(message.payload);
          final players = payload.players.map(mapToGamePlayer).toList();
          gameBloc.add(GameInitialized(
            roundCount: payload.roundCount,
            refereeDeviceIdHash: payload.refereeDeviceIdHash,
            turnOrder: payload.turnOrder,
            currentShooterDeviceIdHash:
                payload.currentShooterDeviceIdHash,
            players: players,
          ));

        default:
          break;
      }
    } on Object catch (e) {
      // Malformed game payloads are dropped with a debug log.
      assert(() {
        debugPrint('GameMessageListener: dropped malformed payload: $e');
        return true;
      }());
    }
  }

  /// Cancels the message subscription.
  void dispose() {
    _subscription.cancel();
  }
}
