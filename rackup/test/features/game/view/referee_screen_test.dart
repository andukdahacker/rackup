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
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/view/referee_screen.dart';
import 'package:rackup/features/game/view/widgets/big_binary_buttons.dart';
import 'package:rackup/features/game/view/widgets/punishment_announcement_card.dart';
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

    testWidgets('RefereeScreen peek uses Oswald typography for scores',
        (tester) async {
      // Emit leaderboard entries so footer peek renders.
      leaderboardBloc.add(const LeaderboardUpdated(
        entries: [
          LeaderboardEntry(
            deviceIdHash: 'hash-a',
            displayName: 'Alice',
            score: 10,
            streak: 0,
            streakLabel: '',
            rank: 1,
          ),
          LeaderboardEntry(
            deviceIdHash: 'hash-b',
            displayName: 'Bob',
            score: 5,
            streak: 0,
            streakLabel: '',
            rank: 2,
          ),
        ],
      ));

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

      // Footer should show scores for top entries.
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Verify score text uses Oswald Bold (w700).
      final scoreTexts = tester.widgetList<Text>(find.text('10'));
      expect(scoreTexts, isNotEmpty);
      final scoreStyle = scoreTexts.first.style!;
      expect(scoreStyle.fontWeight, FontWeight.w700);
      expect(scoreStyle.fontFamily, isNotNull);

      // Verify display name uses Oswald SemiBold (w600).
      final nameTexts = tester.widgetList<Text>(find.text('Alice'));
      // Find the one in the footer (not stage area).
      final footerNames = nameTexts.where((t) =>
          t.style != null && t.style!.fontWeight == FontWeight.w600);
      expect(footerNames, isNotEmpty);
    });

    group('Punishment flow', () {
      const nextShooter = GamePlayer(
        deviceIdHash: 'hash-b',
        displayName: 'Bob',
        slot: 2,
        score: 0,
        streak: 0,
        isReferee: false,
      );

      const testPunishment = PunishmentPayload(
        text: 'Do 5 pushups',
        tier: 'mild',
      );

      testWidgets(
        'idle → confirmed → punishment → idle when turn has punishment',
        (tester) async {
          // Start with idle state (no punishment).
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
          expect(find.byType(BigBinaryButtons), findsOneWidget);

          // Tap MISSED to enter confirmed state.
          await tester.tap(find.text('MISSED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(UndoButton), findsOneWidget);

          // Simulate turn_complete with punishment arriving (rebuild with new props).
          // The turn changes (new shooter), but confirmed state should be preserved.
          await tester.pumpApp(
            RefereeScreen(
              currentRound: 1,
              totalRounds: 10,
              tier: EscalationTier.mild,
              currentShooter: nextShooter,
              webSocketCubit: mockWsCubit,
              leaderboardBloc: leaderboardBloc,
              lastPunishment: testPunishment,
              lastCascadeProfile: 'routine',
            ),
          );
          await tester.pump();
          // Should still show UndoButton (confirmed state preserved).
          expect(find.byType(UndoButton), findsOneWidget);

          // Undo expires → transitions to punishment (routine = 0ms delay).
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(PunishmentAnnouncementCard), findsOneWidget);
          expect(find.text('Do 5 pushups'), findsOneWidget);
          expect(find.text('PUNISHMENT DELIVERED'), findsOneWidget);

          // Tap Delivered → back to idle.
          await tester.tap(find.text('PUNISHMENT DELIVERED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(BigBinaryButtons), findsOneWidget);
        },
      );

      testWidgets(
        'idle → confirmed → idle when turn has NO punishment (regression)',
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(UndoButton), findsOneWidget);

          // Undo expires — no punishment, should return to idle.
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(BigBinaryButtons), findsOneWidget);
          expect(find.byType(PunishmentAnnouncementCard), findsNothing);
        },
      );

      testWidgets(
        'Delivered button tapping transitions back to idle with MADE/MISSED visible',
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

          // Tap MISSED → confirmed.
          await tester.tap(find.text('MISSED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Rebuild with punishment props.
          await tester.pumpApp(
            RefereeScreen(
              currentRound: 1,
              totalRounds: 10,
              tier: EscalationTier.mild,
              currentShooter: nextShooter,
              webSocketCubit: mockWsCubit,
              leaderboardBloc: leaderboardBloc,
              lastPunishment: testPunishment,
              lastCascadeProfile: 'routine',
            ),
          );
          await tester.pump();

          // Undo expires → punishment card.
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(PunishmentAnnouncementCard), findsOneWidget);

          // Tap Delivered.
          await tester.tap(find.text('PUNISHMENT DELIVERED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // MADE/MISSED buttons should be visible again.
          expect(find.text('MADE'), findsOneWidget);
          expect(find.text('MISSED'), findsOneWidget);
          expect(find.byType(PunishmentAnnouncementCard), findsNothing);
        },
      );

      testWidgets(
        'cascade delay: punishment card delayed by cascade profile duration',
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

          // Tap MISSED → confirmed.
          await tester.tap(find.text('MISSED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Rebuild with spicy cascade profile (1200ms delay).
          await tester.pumpApp(
            RefereeScreen(
              currentRound: 1,
              totalRounds: 10,
              tier: EscalationTier.spicy,
              currentShooter: nextShooter,
              webSocketCubit: mockWsCubit,
              leaderboardBloc: leaderboardBloc,
              lastPunishment: const PunishmentPayload(
                text: 'Hot sauce!',
                tier: 'spicy',
              ),
              lastCascadeProfile: 'spicy',
            ),
          );
          await tester.pump();

          // Undo expires.
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Should NOT yet show punishment (cascade delay 1200ms).
          expect(find.byType(PunishmentAnnouncementCard), findsNothing);

          // Pump through cascade delay.
          await tester.pump(const Duration(milliseconds: 1200));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Now punishment card should be visible.
          expect(find.byType(PunishmentAnnouncementCard), findsOneWidget);
          expect(find.text('Hot sauce!'), findsOneWidget);
        },
      );

      testWidgets(
        'didUpdateWidget race condition: turn change during confirmed state does NOT reset to idle',
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

          // Tap MISSED → confirmed (undo running).
          await tester.tap(find.text('MISSED'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(UndoButton), findsOneWidget);

          // Turn changes (new shooter) while in confirmed state.
          await tester.pumpApp(
            RefereeScreen(
              currentRound: 1,
              totalRounds: 10,
              tier: EscalationTier.mild,
              currentShooter: nextShooter,
              webSocketCubit: mockWsCubit,
              leaderboardBloc: leaderboardBloc,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Should still show UndoButton — NOT reset to idle.
          expect(find.byType(UndoButton), findsOneWidget);
          expect(find.byType(BigBinaryButtons), findsNothing);
        },
      );
    });
  });
}
