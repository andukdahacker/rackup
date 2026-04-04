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

/// The held item was cleared (fallback/undo).
class ItemCleared extends ItemEvent {
  const ItemCleared();
}

/// User deploys the held item (imperative naming per convention).
class DeployItem extends ItemEvent {
  const DeployItem({this.targetId});

  /// Device ID hash of the target player. Null for non-targeted items.
  final String? targetId;
}

/// Server confirmed the item deployment.
class ItemDeployConfirmed extends ItemEvent {
  const ItemDeployConfirmed();
}

/// Server rejected the item deployment.
class ItemDeployRejected extends ItemEvent {
  const ItemDeployRejected({required this.reason});

  /// Reason code (e.g., "ITEM_CONSUMED", "INVALID_TARGET").
  final String reason;
}
