import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rackup/core/protocol/actions.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

/// Manages held item state for the local player.
///
/// State transitions:
///
///     ItemEmpty → ItemHeld (drop)
///     ItemHeld → ItemDeploying (user taps deploy)
///     ItemDeploying → ItemEmpty (server confirms)
///     ItemDeploying → ItemFizzled → ItemEmpty (server rejects)
///
/// There is intentionally no client-side deploy timeout. The server is the
/// canonical source of truth — relying on a local timer creates state
/// divergence (server confirms after timeout, client already showed fizzle).
/// WebSocket reconnection is responsible for resyncing item state.
class ItemBloc extends Bloc<ItemEvent, ItemState> {
  /// Creates an [ItemBloc].
  ItemBloc({required WebSocketCubit webSocketCubit})
      : _webSocketCubit = webSocketCubit,
        super(const ItemEmpty()) {
    on<ItemReceived>(_onItemReceived);
    on<ItemCleared>(_onItemCleared);
    on<DeployItem>(_onDeployItem);
    on<ItemDeployConfirmed>(_onItemDeployConfirmed);
    on<ItemDeployRejected>(_onItemDeployRejected);
  }

  final WebSocketCubit _webSocketCubit;

  /// Item drop received during an in-flight fizzle window. Replayed when
  /// the fizzle→empty transition completes so the player doesn't lose a
  /// freshly-dropped item to a stale fizzle animation.
  ItemReceived? _pendingDropAfterFizzle;

  void _onItemReceived(ItemReceived event, Emitter<ItemState> emit) {
    // Ignore new drops during active deployment.
    if (state is ItemDeploying) return;
    // Defer drops received during the fizzle animation window — replayed
    // by the fizzle handler once it transitions to ItemEmpty.
    if (state is ItemFizzled) {
      _pendingDropAfterFizzle = event;
      return;
    }
    emit(ItemHeld(item: event.item));
  }

  void _onItemCleared(ItemCleared event, Emitter<ItemState> emit) {
    emit(const ItemEmpty());
  }

  void _onDeployItem(DeployItem event, Emitter<ItemState> emit) {
    final current = state;
    if (current is! ItemHeld) return;

    emit(ItemDeploying(item: current.item, targetId: event.targetId));

    _webSocketCubit.sendMessage(
      Message(
        action: Actions.itemDeploy,
        payload: ItemDeployPayload(
          item: current.item.type,
          targetId: event.targetId,
        ).toJson(),
      ),
    );
  }

  void _onItemDeployConfirmed(
    ItemDeployConfirmed event,
    Emitter<ItemState> emit,
  ) {
    if (state is! ItemDeploying) return;
    emit(const ItemEmpty());
  }

  Future<void> _onItemDeployRejected(
    ItemDeployRejected event,
    Emitter<ItemState> emit,
  ) async {
    final current = state;
    if (current is! ItemDeploying) return;

    emit(ItemFizzled(item: current.item, reason: event.reason));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (isClosed || emit.isDone) return;

    final pending = _pendingDropAfterFizzle;
    _pendingDropAfterFizzle = null;
    if (pending != null) {
      emit(ItemHeld(item: pending.item));
    } else {
      emit(const ItemEmpty());
    }
  }
}
