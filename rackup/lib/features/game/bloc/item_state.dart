import 'package:equatable/equatable.dart';
import 'package:rackup/core/models/item.dart';

/// State for [ItemBloc].
sealed class ItemState extends Equatable {
  const ItemState();
}

/// No item is currently held.
class ItemEmpty extends ItemState {
  const ItemEmpty();

  @override
  List<Object?> get props => [];
}

/// An item is currently held.
class ItemHeld extends ItemState {
  const ItemHeld({required this.item});

  /// The currently held item.
  final Item item;

  @override
  List<Object?> get props => [item];
}

/// Item is being deployed (optimistic — awaiting server confirmation).
class ItemDeploying extends ItemState {
  const ItemDeploying({required this.item, this.targetId});

  /// The item being deployed.
  final Item item;

  /// Target player device ID hash (null for non-targeted items).
  final String? targetId;

  @override
  List<Object?> get props => [item, targetId];
}

/// Item deployment failed (fizzled).
class ItemFizzled extends ItemState {
  const ItemFizzled({required this.item, required this.reason});

  /// The item that fizzled.
  final Item item;

  /// Reason code for the failure.
  final String reason;

  @override
  List<Object?> get props => [item, reason];
}
