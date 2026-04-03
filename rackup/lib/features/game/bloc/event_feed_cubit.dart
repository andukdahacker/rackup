import 'package:bloc/bloc.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';

/// Lightweight cubit managing a list of recent event feed items (max 4).
///
/// This is a simple list manager — event generation logic lives in
/// [GameMessageListener], not here.
class EventFeedCubit extends Cubit<EventFeedState> {
  /// Creates an [EventFeedCubit].
  EventFeedCubit() : super(const EventFeedState());

  /// Maximum number of visible events.
  static const maxEvents = 4;

  /// Adds an event to the feed. Newest events appear first.
  /// Trims the list to [maxEvents] items.
  void addEvent(EventFeedItem event) {
    final updated = [event, ...state.events];
    if (updated.length > maxEvents) {
      emit(EventFeedState(events: updated.sublist(0, maxEvents)));
    } else {
      emit(EventFeedState(events: updated));
    }
  }
}
