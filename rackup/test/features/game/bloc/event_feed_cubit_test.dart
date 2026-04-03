import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';

EventFeedItem _makeEvent(String id, {EventFeedCategory category = EventFeedCategory.score}) {
  return EventFeedItem(
    id: id,
    text: 'Event $id',
    category: category,
    timestamp: DateTime(2026),
  );
}

void main() {
  group('EventFeedCubit', () {
    blocTest<EventFeedCubit, EventFeedState>(
      'initial state has empty events',
      build: EventFeedCubit.new,
      verify: (cubit) {
        expect(cubit.state.events, isEmpty);
      },
    );

    blocTest<EventFeedCubit, EventFeedState>(
      'addEvent prepends event to list',
      build: EventFeedCubit.new,
      act: (cubit) {
        cubit.addEvent(_makeEvent('1'));
        cubit.addEvent(_makeEvent('2'));
      },
      expect: () => [
        EventFeedState(events: [_makeEvent('1')]),
        EventFeedState(events: [_makeEvent('2'), _makeEvent('1')]),
      ],
    );

    blocTest<EventFeedCubit, EventFeedState>(
      'trims to max 4 events when a 5th is added',
      build: EventFeedCubit.new,
      act: (cubit) {
        for (var i = 1; i <= 5; i++) {
          cubit.addEvent(_makeEvent('$i'));
        }
      },
      verify: (cubit) {
        expect(cubit.state.events, hasLength(4));
        expect(cubit.state.events.first.id, '5');
        expect(cubit.state.events.last.id, '2');
      },
    );

    blocTest<EventFeedCubit, EventFeedState>(
      'newest event is always first (ordering)',
      build: EventFeedCubit.new,
      act: (cubit) {
        cubit.addEvent(_makeEvent('a'));
        cubit.addEvent(_makeEvent('b'));
        cubit.addEvent(_makeEvent('c'));
      },
      verify: (cubit) {
        final ids = cubit.state.events.map((e) => e.id).toList();
        expect(ids, ['c', 'b', 'a']);
      },
    );

    blocTest<EventFeedCubit, EventFeedState>(
      'preserves category on each event',
      build: EventFeedCubit.new,
      act: (cubit) {
        cubit.addEvent(_makeEvent('1', category: EventFeedCategory.streak));
        cubit.addEvent(_makeEvent('2', category: EventFeedCategory.system));
      },
      verify: (cubit) {
        expect(cubit.state.events[0].category, EventFeedCategory.system);
        expect(cubit.state.events[1].category, EventFeedCategory.streak);
      },
    );
  });
}
