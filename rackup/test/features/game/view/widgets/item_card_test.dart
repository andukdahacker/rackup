import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';
import 'package:rackup/features/game/view/widgets/item_card.dart';

import '../../../../helpers/helpers.dart';

void main() {
  const shield = Item(
    type: 'shield',
    displayName: 'Shield',
    accentColorHex: '#14B8A6',
    iconData: Icons.shield,
  );

  group('ItemCard', () {
    testWidgets('shows empty placeholder when no item held', (tester) async {
      final bloc = ItemBloc();
      addTearDown(bloc.close);

      await tester.pumpApp(
        BlocProvider<ItemBloc>.value(
          value: bloc,
          child: const ItemCard(),
        ),
      );
      await tester.pump();

      // Empty state: container with 0.3 opacity.
      expect(find.byKey(const ValueKey('item-empty')), findsOneWidget);
      expect(find.text('Shield'), findsNothing);
    });

    testWidgets('renders item name, icon, border, and deploy text',
        (tester) async {
      final bloc = ItemBloc();
      addTearDown(bloc.close);
      bloc.add(const ItemReceived(item: shield));

      await tester.pumpApp(
        BlocProvider<ItemBloc>.value(
          value: bloc,
          child: const ItemCard(),
        ),
      );
      // Allow bloc to process + animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Shield'), findsOneWidget);
      expect(find.text('TAP TO DEPLOY'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('has electric blue border (#3B82F6) when item held',
        (tester) async {
      final bloc = ItemBloc();
      addTearDown(bloc.close);
      bloc.add(const ItemReceived(item: shield));

      await tester.pumpApp(
        BlocProvider<ItemBloc>.value(
          value: bloc,
          child: const ItemCard(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('item-shield')),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.border,
        Border.all(color: RackUpColors.itemBlue, width: 2),
      );
    });

    testWidgets('fires The Reveal animation on item receive',
        (tester) async {
      final bloc = ItemBloc();
      addTearDown(bloc.close);

      await tester.pumpApp(
        BlocProvider<ItemBloc>.value(
          value: bloc,
          child: const ItemCard(),
        ),
      );
      await tester.pump();

      // Initially empty.
      expect(find.byKey(const ValueKey('item-empty')), findsOneWidget);

      // Receive an item.
      bloc.add(const ItemReceived(item: shield));
      await tester.pump(); // Process event.
      await tester.pump(const Duration(milliseconds: 100));

      // During animation, the transform scale should be active.
      expect(find.byType(Transform), findsOneWidget);

      // Let animation complete.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Shield'), findsOneWidget);
    });
  });
}
