import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _hasAnimated = false;
  int _itemSequence = 0;

  @override
  void initState() {
    super.initState();
    // The Reveal: 150ms anticipation (scale 0.95) + 250ms payoff (easeOutBack).
    _controller = AnimationController(
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
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playRevealAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemBloc, ItemState>(
      listener: (context, state) {
        if (state is ItemHeld) {
          _itemSequence++;
          _playRevealAnimation();
          _hasAnimated = true;
        } else if (state is ItemEmpty) {
          _hasAnimated = false;
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
                        child: _HeldCard(item: item),
                      )
                    : _HeldCard(item: item),
            },
          );
        },
      ),
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
  const _HeldCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final accentColor = item.accentColor;

    return Container(
      key: ValueKey('item-${item.type}'),
      width: 120,
      height: 56,
      decoration: BoxDecoration(
        color: RackUpColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: RackUpColors.itemBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: RackUpColors.itemBlue.withValues(alpha: 0.18),
            blurRadius: 8,
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
          // Deploy arrow (visual affordance only in Story 5.1).
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
