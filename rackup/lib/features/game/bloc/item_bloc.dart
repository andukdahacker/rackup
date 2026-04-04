import 'package:bloc/bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

/// Manages held item state for the local player.
class ItemBloc extends Bloc<ItemEvent, ItemState> {
  /// Creates an [ItemBloc].
  ItemBloc() : super(const ItemEmpty()) {
    on<ItemReceived>(_onItemReceived);
    on<ItemCleared>(_onItemCleared);
  }

  void _onItemReceived(ItemReceived event, Emitter<ItemState> emit) {
    emit(ItemHeld(item: event.item));
  }

  void _onItemCleared(ItemCleared event, Emitter<ItemState> emit) {
    emit(const ItemEmpty());
  }
}
