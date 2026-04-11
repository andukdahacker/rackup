import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/item_bloc.dart';
import 'package:rackup/features/game/bloc/item_event.dart';
import 'package:rackup/features/game/bloc/item_state.dart';

class _MockWebSocketCubit extends Mock implements WebSocketCubit {}

class _FakeMessage extends Fake implements Message {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMessage());
  });

  const shield = Item(
    type: 'shield',
    displayName: 'Shield',
    accentColorHex: '#14B8A6',
    iconData: Icons.shield,
    requiresTarget: false,
  );
  const blueShell = Item(
    type: 'blue_shell',
    displayName: 'Blue Shell',
    accentColorHex: '#3B82F6',
    iconData: Icons.gps_fixed,
    requiresTarget: true,
  );

  late _MockWebSocketCubit mockWsCubit;

  setUp(() {
    mockWsCubit = _MockWebSocketCubit();
    when(() => mockWsCubit.sendMessage(any())).thenAnswer((_) {});
  });

  ItemBloc buildBloc() => ItemBloc(webSocketCubit: mockWsCubit);

  group('ItemBloc', () {
    blocTest<ItemBloc, ItemState>(
      'initial state is ItemEmpty',
      build: buildBloc,
      verify: (bloc) {
        expect(bloc.state, isA<ItemEmpty>());
      },
    );

    blocTest<ItemBloc, ItemState>(
      'emits ItemHeld on ItemReceived',
      build: buildBloc,
      act: (bloc) => bloc.add(const ItemReceived(item: shield)),
      expect: () => [const ItemHeld(item: shield)],
    );

    blocTest<ItemBloc, ItemState>(
      'emits ItemEmpty on ItemCleared',
      build: buildBloc,
      seed: () => const ItemHeld(item: shield),
      act: (bloc) => bloc.add(const ItemCleared()),
      expect: () => [const ItemEmpty()],
    );

    blocTest<ItemBloc, ItemState>(
      'replaces item on second ItemReceived',
      build: buildBloc,
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

    blocTest<ItemBloc, ItemState>(
      'DeployItem from ItemHeld emits ItemDeploying',
      build: buildBloc,
      seed: () => const ItemHeld(item: shield),
      act: (bloc) => bloc.add(const DeployItem()),
      expect: () => [
        const ItemDeploying(item: shield),
      ],
    );

    blocTest<ItemBloc, ItemState>(
      'DeployItem from ItemEmpty is ignored',
      build: buildBloc,
      act: (bloc) => bloc.add(const DeployItem()),
      expect: () => <ItemState>[],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemDeployConfirmed from ItemDeploying emits ItemEmpty',
      build: buildBloc,
      seed: () => const ItemDeploying(item: shield),
      act: (bloc) => bloc.add(const ItemDeployConfirmed()),
      expect: () => [const ItemEmpty()],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemDeployConfirmed without prior Deploying is ignored',
      build: buildBloc,
      seed: () => const ItemEmpty(),
      act: (bloc) => bloc.add(const ItemDeployConfirmed()),
      expect: () => <ItemState>[],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemDeployRejected emits ItemFizzled then ItemEmpty',
      build: buildBloc,
      seed: () => const ItemDeploying(item: shield),
      act: (bloc) => bloc.add(
        const ItemDeployRejected(reason: 'ITEM_CONSUMED'),
      ),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const ItemFizzled(item: shield, reason: 'ITEM_CONSUMED'),
        const ItemEmpty(),
      ],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemDeployRejected without prior Deploying is ignored',
      build: buildBloc,
      seed: () => const ItemHeld(item: shield),
      act: (bloc) =>
          bloc.add(const ItemDeployRejected(reason: 'ITEM_CONSUMED')),
      expect: () => <ItemState>[],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemReceived during ItemDeploying is ignored',
      build: buildBloc,
      seed: () => const ItemDeploying(item: shield),
      act: (bloc) => bloc.add(const ItemReceived(item: blueShell)),
      expect: () => <ItemState>[],
    );

    blocTest<ItemBloc, ItemState>(
      'ItemReceived during ItemFizzled is replayed after fizzle window',
      build: buildBloc,
      seed: () => const ItemDeploying(item: shield),
      act: (bloc) async {
        bloc.add(const ItemDeployRejected(reason: 'INVALID_TARGET'));
        // Wait briefly so the fizzle state is observed before the drop.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const ItemReceived(item: blueShell));
      },
      wait: const Duration(milliseconds: 700),
      expect: () => [
        const ItemFizzled(item: shield, reason: 'INVALID_TARGET'),
        const ItemHeld(item: blueShell),
      ],
    );
  });
}
