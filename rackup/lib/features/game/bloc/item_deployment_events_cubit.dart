import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

/// Public broadcast channel for item deployment events visible to ALL
/// clients in a room (not just the deployer).
///
/// [ItemBloc] only tracks the local player's held item, so its state
/// transitions cannot drive sounds for observers (the spec calls out the
/// "social moment" of Blue Shell impact being audible to attacker AND
/// target). This cubit emits a fresh state whenever the server broadcasts
/// `item.deployed` or `item.fizzled`, regardless of who deployed it.
///
/// Subscribed by [AudioListener] so impact sounds play on every device.
class ItemDeploymentEventsCubit extends Cubit<ItemDeploymentEventState> {
  /// Creates an [ItemDeploymentEventsCubit].
  ItemDeploymentEventsCubit()
      : super(const ItemDeploymentEventState(sequence: 0));

  int _sequence = 0;

  /// Emits a `deployed` event. Called for every player on `item.deployed`.
  void notifyDeployed({
    required String itemType,
    required String deployerId,
    String? targetId,
  }) {
    _sequence++;
    emit(
      ItemDeploymentEventState(
        sequence: _sequence,
        kind: ItemDeploymentEventKind.deployed,
        itemType: itemType,
        deployerId: deployerId,
        targetId: targetId,
      ),
    );
  }

  /// Emits a `fizzled` event. Currently fired only on the deployer's
  /// device because `item.fizzled` is unicast.
  void notifyFizzled({
    required String itemType,
    required String reason,
  }) {
    _sequence++;
    emit(
      ItemDeploymentEventState(
        sequence: _sequence,
        kind: ItemDeploymentEventKind.fizzled,
        itemType: itemType,
        reason: reason,
      ),
    );
  }
}

/// Discriminator for the most recent deployment event.
enum ItemDeploymentEventKind { none, deployed, fizzled }

/// State emitted by [ItemDeploymentEventsCubit].
///
/// Uses a monotonically increasing [sequence] so listeners can tell
/// repeated events apart even if every other field is identical
/// (e.g., the same player redeploys the same item back-to-back).
class ItemDeploymentEventState extends Equatable {
  /// Creates an [ItemDeploymentEventState].
  const ItemDeploymentEventState({
    required this.sequence,
    this.kind = ItemDeploymentEventKind.none,
    this.itemType,
    this.deployerId,
    this.targetId,
    this.reason,
  });

  /// Monotonically increasing sequence number for change detection.
  final int sequence;

  /// What kind of event this is.
  final ItemDeploymentEventKind kind;

  /// Item type (e.g. `blue_shell`). Null for the initial state.
  final String? itemType;

  /// Hash of the player who deployed (deployed events only).
  final String? deployerId;

  /// Hash of the targeted player (deployed events with target only).
  final String? targetId;

  /// Reason code from the server (fizzled events only).
  final String? reason;

  @override
  List<Object?> get props =>
      [sequence, kind, itemType, deployerId, targetId, reason];
}
