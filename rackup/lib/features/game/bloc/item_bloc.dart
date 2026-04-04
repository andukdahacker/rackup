import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rackup/core/protocol/actions.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

/// Timeout for server to respond to a deploy request.
const _deployTimeout = Duration(seconds: 5);

/// Manages held item state for the local player.
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
  Timer? _deployTimer;

  void _onItemReceived(ItemReceived event, Emitter<ItemState> emit) {
    // Ignore new drops during active deployment.
    if (state is ItemDeploying) return;
    emit(ItemHeld(item: event.item));
  }

  void _onItemCleared(ItemCleared event, Emitter<ItemState> emit) {
    emit(const ItemEmpty());
  }

  void _onDeployItem(DeployItem event, Emitter<ItemState> emit) {
    final current = state;
    if (current is! ItemHeld) return;

    emit(ItemDeploying(item: current.item, targetId: event.targetId));

    // Start timeout — if server never responds, treat as fizzle.
    _deployTimer?.cancel();
    _deployTimer = Timer(_deployTimeout, () {
      if (!isClosed && state is ItemDeploying) {
        add(const ItemDeployRejected(reason: 'TIMEOUT'));
      }
    });

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
    _deployTimer?.cancel();
    emit(const ItemEmpty());
  }

  Future<void> _onItemDeployRejected(
    ItemDeployRejected event,
    Emitter<ItemState> emit,
  ) async {
    _deployTimer?.cancel();
    final current = state;
    if (current is ItemDeploying) {
      emit(ItemFizzled(item: current.item, reason: event.reason));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!isClosed) {
        emit(const ItemEmpty());
      }
    }
  }

  @override
  Future<void> close() {
    _deployTimer?.cancel();
    return super.close();
  }
}
