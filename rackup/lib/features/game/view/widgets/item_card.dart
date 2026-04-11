import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_state.dart' as gs;
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';
import 'package:rackup/features/game/view/widgets/targeting_overlay.dart';

/// Displays the player's held item or an empty placeholder.
///
/// Compact card for the My Status zone (~120dp wide, 56dp tall).
/// Uses The Reveal animation on item receive and a swap animation
/// on item replacement.
class ItemCard extends StatefulWidget {
  const ItemCard({super.key});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _deployController;
  late final Animation<double> _deployGlow;
  late final AnimationController _fizzleController;
  late final Animation<double> _fizzleShake;
  bool _hasAnimated = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // The Reveal: 150ms anticipation (scale 0.95) + 250ms payoff (easeOutBack).
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.95),
        weight: 37.5, // ~150ms anticipation
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 62.5, // ~250ms payoff
      ),
    ]).animate(_revealController);

    // Deploy: gold glow flash over 500ms.
    _deployController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _deployGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 60),
    ]).animate(_deployController);

    // Fizzle: quick shake over 400ms.
    _fizzleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fizzleShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 3.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: -2.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 20),
    ]).animate(_fizzleController);
  }

  @override
  void dispose() {
    _revealController.dispose();
    _deployController.dispose();
    _fizzleController.dispose();
    super.dispose();
  }

  void _playRevealAnimation() {
    _revealController.forward(from: 0.0);
  }

  void _onTapItem(BuildContext context, Item item) {
    if (item.requiresTarget) {
      _showTargeting(context, item);
    } else {
      context.read<ItemBloc>().add(const DeployItem());
    }
  }

  Future<void> _showTargeting(BuildContext context, Item item) async {
    final gameState = context.read<GameBloc>().state;
    final lbState = context.read<LeaderboardBloc>().state;

    if (gameState is! gs.GameActive || lbState is! LeaderboardActive) {
      _showTargetingError(
        context,
        'Cannot deploy item right now — game is not active.',
      );
      return;
    }

    // Get local device ID hash — required to filter the deployer out of the
    // target list. If the identity service is missing from the provider tree,
    // we surface a snackbar instead of silently swallowing the tap (P8).
    final localHash = _getLocalDeviceIdHash();
    if (localHash == null) {
      _showTargetingError(
        context,
        'Cannot identify this device — please rejoin the game.',
      );
      return;
    }

    // Build slot map from game players.
    final playerSlots = <String, int>{};
    for (final p in gameState.players) {
      playerSlots[p.deviceIdHash] = p.slot;
    }

    if (!context.mounted) return;
    final selectedHash = await showTargetingOverlay(
      context: context,
      item: item,
      localDeviceIdHash: localHash,
      refereeDeviceIdHash: gameState.refereeDeviceIdHash,
      playerSlots: playerSlots,
    );

    if (!context.mounted) return;
    // Re-check ItemBloc state — the bloc may have moved off ItemHeld while
    // the modal was open (e.g., a server fizzle preempted the local tap).
    final currentItemState = context.read<ItemBloc>().state;
    if (selectedHash != null && currentItemState is ItemHeld) {
      context.read<ItemBloc>().add(DeployItem(targetId: selectedHash));
    }
  }

  void _showTargetingError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Reads the local device ID hash. Catches [ProviderNotFoundException]
  /// specifically so genuine programming errors are not swallowed.
  String? _getLocalDeviceIdHash() {
    try {
      return context.read<DeviceIdentityService>().getHashedDeviceId();
    } on ProviderNotFoundException catch (e) {
      debugPrint('ItemCard: DeviceIdentityService not provided: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemBloc, ItemState>(
      listener: (context, state) {
        // Any non-ItemHeld transition resets the press flag so a stale touch
        // doesn't carry over into a new state.
        if (state is! ItemHeld && _isPressed) {
          setState(() => _isPressed = false);
        }
        if (state is ItemHeld) {
          _playRevealAnimation();
          _hasAnimated = true;
        } else if (state is ItemEmpty) {
          _hasAnimated = false;
        } else if (state is ItemDeploying) {
          _fizzleController.reset();
          _deployController.forward(from: 0.0);
        } else if (state is ItemFizzled) {
          _deployController.reset();
          _fizzleController.forward(from: 0.0);
        }
      },
      child: BlocBuilder<ItemBloc, ItemState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: switch (state) {
              ItemEmpty() => const _EmptyCard(),
              ItemHeld(:final item) =>
                _hasAnimated
                    ? AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: child,
                          );
                        },
                        child: _buildHeldCard(context, item),
                      )
                    : _buildHeldCard(context, item),
              ItemDeploying(:final item) => _DeployingCard(
                  item: item,
                  glowAnimation: _deployGlow,
                ),
              ItemFizzled(:final item) =>
                AnimatedBuilder(
                  animation: _fizzleShake,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_fizzleShake.value, 0),
                      child: child,
                    );
                  },
                  child: _FizzleCard(item: item),
                ),
            },
          );
        },
      ),
    );
  }

  Widget _buildHeldCard(BuildContext context, Item item) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _onTapItem(context, item);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: _HeldCard(item: item, isPressed: _isPressed),
    );
  }
}

/// Empty state placeholder at 30% opacity.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: const ValueKey('item-empty'),
        width: 120,
        height: 56,
        decoration: BoxDecoration(
          color: RackUpColors.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: RackUpColors.textSecondary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Held item card with icon, name, and "TAP TO DEPLOY" affordance.
class _HeldCard extends StatelessWidget {
  const _HeldCard({required this.item, this.isPressed = false});

  final Item item;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final accentColor = item.accentColor;
    final borderColor = isPressed
        ? RackUpColors.itemGold
        : RackUpColors.itemBlue;
    final glowAlpha = isPressed ? 0.35 : 0.18;

    return Container(
      key: ValueKey('item-${item.type}'),
      width: 120,
      height: 56,
      decoration: BoxDecoration(
        color: RackUpColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: glowAlpha),
            blurRadius: isPressed ? 12 : 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Item icon with accent background.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.iconData,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          // Name and deploy text.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: RackUpColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'TAP TO DEPLOY',
                    style: TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 10,
                      color: RackUpColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: RackUpColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Deploying state: gold glow flash (~500ms masking server latency).
class _DeployingCard extends StatelessWidget {
  const _DeployingCard({required this.item, required this.glowAnimation});

  final Item item;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, _) {
        final glowIntensity = glowAnimation.value;
        return Container(
          key: const ValueKey('item-deploying'),
          width: 120,
          height: 56,
          decoration: BoxDecoration(
            color: RackUpColors.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color.lerp(
                RackUpColors.itemBlue,
                RackUpColors.itemGold,
                glowIntensity,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: RackUpColors.itemGold
                    .withValues(alpha: 0.3 * glowIntensity),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: Text(
              'DEPLOYING...',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color.lerp(
                  RackUpColors.textPrimary,
                  RackUpColors.itemGold,
                  glowIntensity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fizzle state: dim border, shake, then fade.
class _FizzleCard extends StatelessWidget {
  const _FizzleCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('item-fizzle'),
      width: 120,
      height: 56,
      decoration: BoxDecoration(
        color: RackUpColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RackUpColors.textSecondary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: const Center(
        child: Text(
          'Fizzled!',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: RackUpColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
