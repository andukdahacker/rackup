import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';
import 'package:rackup/features/game/view/widgets/event_feed_widget.dart';

EventFeedItem _makeEvent(
  String id,
  String text, {
  EventFeedCategory category = EventFeedCategory.score,
}) {
  return EventFeedItem(
    id: id,
    text: text,
    category: category,
    timestamp: DateTime(2026),
  );
}

Widget _buildTestWidget(EventFeedCubit cubit) {
  return MaterialApp(
    home: BlocProvider<EventFeedCubit>.value(
      value: cubit,
      child: const Scaffold(
        body: SizedBox(
          height: 200,
          child: EventFeedWidget(),
        ),
      ),
    ),
  );
}

void main() {
  group('EventFeedWidget', () {
    late EventFeedCubit cubit;

    setUp(() {
      cubit = EventFeedCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders empty initially', (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));
      expect(find.byType(AnimatedList), findsOneWidget);
    });

    testWidgets('renders event rows when events are added', (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));

      cubit.addEvent(_makeEvent('1', 'Alice scored +2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alice scored +2'), findsOneWidget);
    });

    testWidgets('renders correct border color for score category',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));

      cubit.addEvent(
          _makeEvent('1', 'Score event', category: EventFeedCategory.score));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find the container with the left border.
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Score event'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
      final leftSide = (decoration.border! as Border).left;
      expect(leftSide.color, const Color(0xFF22C55E));
      expect(leftSide.width, 3);
    });

    testWidgets('renders correct border color for streak category',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));

      cubit.addEvent(
          _makeEvent('1', 'Streak event', category: EventFeedCategory.streak));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Streak event'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      final leftSide = (decoration.border! as Border).left;
      expect(leftSide.color, RackUpColors.streakGold);
    });

    testWidgets('renders correct border color for system category',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));

      cubit.addEvent(
          _makeEvent('1', 'GAME OVER', category: EventFeedCategory.system));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('GAME OVER'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      final leftSide = (decoration.border! as Border).left;
      expect(leftSide.color, RackUpColors.textPrimary);
    });

    testWidgets('renders multiple event rows', (tester) async {
      await tester.pumpWidget(_buildTestWidget(cubit));

      cubit.addEvent(_makeEvent('1', 'Event one'));
      cubit.addEvent(_makeEvent('2', 'Event two'));
      cubit.addEvent(_makeEvent('3', 'Event three'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Event one'), findsOneWidget);
      expect(find.text('Event two'), findsOneWidget);
      expect(find.text('Event three'), findsOneWidget);
    });
  });
}
