import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

void main() {
  const shield = Item(
    type: 'shield',
    displayName: 'Shield',
    accentColorHex: '#14B8A6',
    iconData: Icons.shield,
  );
  const blueShell = Item(
    type: 'blue_shell',
    displayName: 'Blue Shell',
    accentColorHex: '#3B82F6',
    iconData: Icons.gps_fixed,
  );

  group('ItemBloc', () {
    blocTest<ItemBloc, ItemState>(
      'initial state is ItemEmpty',
      build: ItemBloc.new,
      verify: (bloc) {
        expect(bloc.state, isA<ItemEmpty>());
      },
    );

    blocTest<ItemBloc, ItemState>(
      'emits ItemHeld on ItemReceived',
      build: ItemBloc.new,
      act: (bloc) => bloc.add(const ItemReceived(item: shield)),
      expect: () => [const ItemHeld(item: shield)],
    );

    blocTest<ItemBloc, ItemState>(
      'emits ItemEmpty on ItemCleared',
      build: ItemBloc.new,
      seed: () => const ItemHeld(item: shield),
      act: (bloc) => bloc.add(const ItemCleared()),
      expect: () => [const ItemEmpty()],
    );

    blocTest<ItemBloc, ItemState>(
      'replaces item on second ItemReceived',
      build: ItemBloc.new,
      act: (bloc) {
        bloc.add(const ItemReceived(item: shield));
        bloc.add(
          const ItemReceived(item: blueShell, replacedItem: shield),
        );
      },
      expect: () => [
        const ItemHeld(item: shield),
        const ItemHeld(item: blueShell),
      ],
    );
  });
}
