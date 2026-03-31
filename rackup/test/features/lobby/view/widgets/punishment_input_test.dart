import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/widgets/punishment_input.dart';

class MockRoomBloc extends MockBloc<RoomEvent, RoomState>
    implements RoomBloc {}

class MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {}

class FakeMessage extends Fake implements Message {}

class FakeWebSocketChannel extends Fake implements WebSocketChannel {}

void main() {
  late MockRoomBloc roomBloc;
  late MockWebSocketCubit webSocketCubit;

  setUpAll(() {
    registerFallbackValue(const PunishmentSubmitted(text: ''));
    registerFallbackValue(FakeMessage());
  });

  setUp(() {
    roomBloc = MockRoomBloc();
    webSocketCubit = MockWebSocketCubit();
    when(() => roomBloc.state).thenReturn(
      const RoomLobby(players: [], roomCode: 'ABCD', jwt: 'jwt'),
    );
    when(() => webSocketCubit.state)
        .thenReturn(const WebSocketDisconnected());
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RackUpColors.canvas,
        textTheme: RackUpTypography.buildTextTheme(),
        useMaterial3: true,
      ),
      home: RackUpGameTheme(
        data: const RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: false,
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoomBloc>.value(value: roomBloc),
            BlocProvider<WebSocketCubit>.value(value: webSocketCubit),
          ],
          child: const Scaffold(body: PunishmentInput()),
        ),
      ),
    );
  }

  group('PunishmentInput', () {
    testWidgets('renders text field with placeholder', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders Random button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Random'), findsOneWidget);
    });

    testWidgets('shows focused state with blue border on focus',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // TextField is focused — the focused border should be active.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('shows Submit button when text is non-empty',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      // Initially no Submit button.
      expect(find.text('Submit'), findsNothing);
      // Type text.
      await tester.enterText(find.byType(TextField), 'Test punishment');
      await tester.pump();
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('Random button populates text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Random'));
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isNotEmpty);
      // Submit button should appear.
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('submitting transitions to submitted state',
        (tester) async {
      when(() => webSocketCubit.state)
          .thenReturn(WebSocketConnected(FakeWebSocketChannel()));
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'Do a dance');
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Verify PunishmentSubmitted event dispatched.
      verify(() => roomBloc.add(any(that: isA<PunishmentSubmitted>())))
          .called(1);

      // Submitted state: checkmark visible, no Submit/Random buttons.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
      expect(find.text('Random'), findsNothing);
    });

    testWidgets('text field becomes read-only after submission',
        (tester) async {
      when(() => webSocketCubit.state)
          .thenReturn(WebSocketConnected(FakeWebSocketChannel()));
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
    });

    testWidgets('submit does nothing when WebSocket is disconnected',
        (tester) async {
      when(() => webSocketCubit.state)
          .thenReturn(const WebSocketDisconnected());
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      // Should NOT transition to submitted state.
      verifyNever(() => roomBloc.add(any(that: isA<PunishmentSubmitted>())));
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
    });

    testWidgets('sends writing status on first keystroke',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'H');
      await tester.pump();
      verify(() => webSocketCubit.sendMessage(any())).called(1);
    });

    testWidgets('has semantics label on text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.bySemanticsLabel('Enter a custom punishment'),
        findsOneWidget,
      );
    });
  });
}
