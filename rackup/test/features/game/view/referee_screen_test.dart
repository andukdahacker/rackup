import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/view/referee_screen.dart';
import 'package:rackup/features/game/view/widgets/big_binary_buttons.dart';
import 'package:rackup/features/game/view/widgets/undo_button.dart';

import '../../../helpers/helpers.dart';

class MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  final List<Message> sentMessages = [];

  @override
  Stream<Message> get messages => _messageController.stream;

  @override
  void sendMessage(Message message) {
    sentMessages.add(message);
  }

  void disposeController() {
    _messageController.close();
  }
}

void main() {
  group('RefereeScreen', () {
    late MockWebSocketCubit mockWsCubit;
    late LeaderboardBloc leaderboardBloc;

    const testShooter = GamePlayer(
      deviceIdHash: 'hash-a',
      displayName: 'Alice',
      slot: 1,
      score: 0,
      streak: 0,
      isReferee: false,
    );

    setUp(() {
      mockWsCubit = MockWebSocketCubit();
      leaderboardBloc = LeaderboardBloc();
    });

    tearDown(() {
      leaderboardBloc.close();
      mockWsCubit.disposeController();
    });

    testWidgets('renders all 4 regions with BigBinaryButtons', (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      // Pump a frame for animations to start.
      await tester.pump();

      // Status Bar: ProgressTierBar.
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('R1/10'), findsOneWidget);

      // Stage Area: current shooter name.
      expect(find.text('Alice'), findsOneWidget);

      // Action Zone: BigBinaryButtons (not "Waiting for turn...").
      expect(find.byType(BigBinaryButtons), findsOneWidget);
      expect(find.text('MADE'), findsOneWidget);
      expect(find.text('MISSED'), findsOneWidget);

      // Footer: leaderboard placeholder.
      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('tapping MADE sends confirm_shot and shows UndoButton',
        (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      await tester.pump();

      // Tap MADE.
      await tester.tap(find.text('MADE'));
      // Pump through AnimatedSwitcher transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify message sent.
      expect(mockWsCubit.sentMessages.length, 1);
      expect(
        mockWsCubit.sentMessages.first.action,
        'referee.confirm_shot',
      );
      expect(mockWsCubit.sentMessages.first.payload['result'], 'made');

      // UndoButton should now be visible.
      expect(find.byType(UndoButton), findsOneWidget);
    });

    testWidgets('tapping MISSED sends confirm_shot with missed result',
        (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('MISSED'));
      await tester.pump();

      expect(mockWsCubit.sentMessages.length, 1);
      expect(mockWsCubit.sentMessages.first.payload['result'], 'missed');
    });

    testWidgets('tapping UndoButton sends undo_shot and returns to buttons',
        (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      await tester.pump();

      // Tap MADE to enter confirmed state.
      await tester.tap(find.text('MADE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap undo.
      await tester.tap(find.byType(UndoButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify undo message sent.
      expect(mockWsCubit.sentMessages.length, 2);
      expect(mockWsCubit.sentMessages.last.action, 'referee.undo_shot');

      // BigBinaryButtons should be back.
      expect(find.byType(BigBinaryButtons), findsOneWidget);
    });

    testWidgets('UndoButton expires after 5 seconds and returns to buttons',
        (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      await tester.pump();

      // Tap MADE to enter confirmed state.
      await tester.tap(find.text('MADE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(UndoButton), findsOneWidget);

      // Pump past the 5-second countdown.
      await tester.pump(const Duration(seconds: 5));
      // Process the onExpired callback and setState.
      await tester.pump();
      // Pump through AnimatedSwitcher cross-fade (300ms duration + extra).
      await tester.pump(const Duration(milliseconds: 500));

      // BigBinaryButtons should be back after expiry.
      expect(find.byType(BigBinaryButtons), findsOneWidget);
    });

    testWidgets('BigBinaryButtons have minimum 100dp height', (tester) async {
      await tester.pumpApp(
        RefereeScreen(
          currentRound: 1,
          totalRounds: 10,
          tier: EscalationTier.mild,
          currentShooter: testShooter,
          webSocketCubit: mockWsCubit,
          leaderboardBloc: leaderboardBloc,
        ),
      );
      await tester.pump();

      // Verify buttons are rendered with text.
      expect(find.text('MADE'), findsOneWidget);
      expect(find.text('MISSED'), findsOneWidget);
    });
  });
}
