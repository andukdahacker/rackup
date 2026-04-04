import 'package:rackup/core/models/item.dart';

/// Events for [ItemBloc].
sealed class ItemEvent {
  const ItemEvent();
}

/// An item was received from an item drop.
class ItemReceived extends ItemEvent {
  const ItemReceived({required this.item, this.replacedItem});

  /// The new item received.
  final Item item;

  /// The previous item that was replaced (null if slot was empty).
  final Item? replacedItem;
}

/// The held item was cleared (deployment in Story 5.2).
class ItemCleared extends ItemEvent {
  const ItemCleared();
}
