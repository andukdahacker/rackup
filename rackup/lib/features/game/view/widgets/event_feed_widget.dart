import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';

/// Displays a scrolling feed of recent game events with colored left borders.
///
/// Uses [AnimatedList] driven by [BlocListener] for smooth insert/remove
/// animations. Max 4 visible events (3 on screens < 375dp).
class EventFeedWidget extends StatefulWidget {
  const EventFeedWidget({super.key});

  @override
  State<EventFeedWidget> createState() => _EventFeedWidgetState();
}

class _EventFeedWidgetState extends State<EventFeedWidget> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<EventFeedItem> _currentEvents = [];
  int _lastMaxVisible = EventFeedCubit.maxEvents;

  int _maxVisible(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 375 ? 3 : EventFeedCubit.maxEvents;
  }

  @override
  Widget build(BuildContext context) {
    final maxVisible = _maxVisible(context);

    // Reconcile if maxVisible changed (e.g. rotation).
    if (maxVisible != _lastMaxVisible) {
      _lastMaxVisible = maxVisible;
      _reconcile(context.read<EventFeedCubit>().state, maxVisible);
    }

    return BlocListener<EventFeedCubit, EventFeedState>(
      listener: (context, state) => _reconcile(state, _maxVisible(context)),
      child: AnimatedList(
        key: _listKey,
        initialItemCount: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemBuilder: (context, index, animation) {
          if (index >= _currentEvents.length) {
            return const SizedBox.shrink();
          }
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(-1, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: _EventRow(item: _currentEvents[index]),
          );
        },
      ),
    );
  }

  void _reconcile(EventFeedState state, int maxVisible) {
    final newEvents = state.events.length > maxVisible
        ? state.events.sublist(0, maxVisible)
        : state.events;
    final oldEvents = _currentEvents;

    // Count how many new items were prepended by finding the first
    // old item in the new list.
    var insertCount = newEvents.length;
    if (oldEvents.isNotEmpty) {
      final firstOldId = oldEvents.first.id;
      for (var i = 0; i < newEvents.length; i++) {
        if (newEvents[i].id == firstOldId) {
          insertCount = i;
          break;
        }
      }
    }

    // Insert new items at the top, one at a time from bottom to top
    // so each insert at index 0 pushes previous inserts down.
    for (var i = insertCount - 1; i >= 0; i--) {
      _listKey.currentState?.insertItem(i,
          duration: const Duration(milliseconds: 300));
    }

    // Remove overflow items from the bottom.
    final newLen = oldEvents.length + insertCount;
    if (newLen > newEvents.length) {
      for (var i = newLen - 1; i >= newEvents.length; i--) {
        final removedIdx = i < oldEvents.length + insertCount
            ? i - insertCount
            : i;
        final removed =
            removedIdx >= 0 && removedIdx < oldEvents.length
                ? oldEvents[removedIdx]
                : null;
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => removed != null
              ? _buildRemovedItem(removed, animation)
              : const SizedBox.shrink(),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    _currentEvents = List.of(newEvents);
  }

  Widget _buildRemovedItem(EventFeedItem item, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: _EventRow(item: item),
    );
  }
}

/// A single compact event row with a colored left border.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.item});

  final EventFeedItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _borderColor(item.category),
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          item.text,
          style: const TextStyle(
            fontFamily: 'Barlow',
            fontSize: 13,
            color: RackUpColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static Color _borderColor(EventFeedCategory category) {
    return switch (category) {
      EventFeedCategory.score => const Color(0xFF22C55E),
      EventFeedCategory.streak => RackUpColors.streakGold,
      EventFeedCategory.item => RackUpColors.itemBlue,
      EventFeedCategory.itemFizzle => RackUpColors.textSecondary,
      EventFeedCategory.punishment => RackUpColors.missedRed,
      EventFeedCategory.mission => RackUpColors.missionPurple,
      EventFeedCategory.system => RackUpColors.textPrimary,
    };
  }
}
