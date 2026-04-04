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
