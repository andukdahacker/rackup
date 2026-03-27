import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/join_room_page.dart';

import '../../../helpers/pump_app.dart';

class MockRoomBloc extends MockBloc<RoomEvent, RoomState>
    implements RoomBloc {}

void main() {
  late MockRoomBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const JoinRoom(code: 'AAAA', displayName: 'Test'),
    );
  });

  setUp(() {
    bloc = MockRoomBloc();
    when(() => bloc.state).thenReturn(const RoomInitial());
  });

  Widget buildSubject({String? initialCode}) {
    return BlocProvider<RoomBloc>.value(
      value: bloc,
      child: JoinRoomPage(initialCode: initialCode),
    );
  }

  group('JoinRoomPage', () {
    testWidgets('shows form with code input, name input, and join button',
        (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.text('Enter Room Code'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('join button is disabled when fields are empty',
        (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.tap(find.text('Join'));
      await tester.pump();

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('shows loading state', (tester) async {
      when(() => bloc.state).thenReturn(const RoomJoining());

      await tester.pumpApp(buildSubject());

      expect(find.text('Joining room...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with message', (tester) async {
      when(() => bloc.state).thenReturn(
        const RoomError(message: 'Room not found'),
      );

      await tester.pumpApp(buildSubject());

      expect(find.text('Room not found'), findsOneWidget);
      expect(find.text('Enter Room Code'), findsOneWidget);
    });

    testWidgets('dispatches JoinRoom with valid code and name',
        (tester) async {
      await tester.pumpApp(buildSubject());

      // Enter 4-character room code across the 4 TextFields.
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'A');
      await tester.enterText(textFields.at(1), 'B');
      await tester.enterText(textFields.at(2), 'C');
      await tester.enterText(textFields.at(3), 'D');

      // Enter display name (last TextField is the name field).
      await tester.enterText(textFields.last, 'Alice');
      await tester.pump();

      // Tap Join button.
      await tester.tap(find.text('Join'));
      await tester.pump();

      verify(
        () => bloc.add(
          const JoinRoom(code: 'ABCD', displayName: 'Alice'),
        ),
      ).called(1);
    });

    testWidgets('shows success state', (tester) async {
      when(() => bloc.state).thenReturn(
        const RoomCreatedState(roomCode: 'ABCD', jwt: 'test-jwt'),
      );

      await tester.pumpApp(buildSubject());

      expect(find.text('Joined!'), findsOneWidget);
      expect(find.text('ABCD'), findsOneWidget);
      expect(find.text('Waiting for game to start...'), findsOneWidget);
    });

    group('deep link pre-fill (initialCode)', () {
      testWidgets('pre-fills code fields with initialCode characters',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));

        final textFields = find.byType(TextField);
        // First 4 TextFields are code fields.
        for (var i = 0; i < 4; i++) {
          final field = tester.widget<TextField>(textFields.at(i));
          expect(field.controller!.text, 'ABCD'[i]);
        }
      });

      testWidgets('code fields are read-only when initialCode is provided',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));

        final textFields = find.byType(TextField);
        // First 4 TextFields are code fields.
        for (var i = 0; i < 4; i++) {
          final field = tester.widget<TextField>(textFields.at(i));
          expect(field.readOnly, isTrue);
        }
      });

      testWidgets('display name field has focus when initialCode is provided',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        // The 5th TextField is the display name field.
        final nameField = tester.widget<TextField>(textFields.last);
        expect(nameField.focusNode!.hasFocus, isTrue);
      });

      testWidgets('heading shows "Join via Link" with initialCode',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));

        expect(find.text('Join via Link'), findsOneWidget);
        expect(find.text('Enter Room Code'), findsNothing);
      });

      testWidgets('on error state, code fields become editable again',
          (tester) async {
        when(() => bloc.state).thenReturn(
          const RoomError(message: 'Room not found'),
        );

        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));

        final textFields = find.byType(TextField);
        // Code fields should be editable on error.
        for (var i = 0; i < 4; i++) {
          final field = tester.widget<TextField>(textFields.at(i));
          expect(field.readOnly, isFalse);
        }
      });

      testWidgets(
          'heading still shows "Join via Link" on error with initialCode',
          (tester) async {
        when(() => bloc.state).thenReturn(
          const RoomError(message: 'Room not found'),
        );

        await tester.pumpApp(buildSubject(initialCode: 'ABCD'));

        // Heading should stay "Join via Link" even on error when deep
        // link was used — only the code fields unlock, not the heading.
        expect(find.text('Join via Link'), findsOneWidget);
        expect(find.text('Enter Room Code'), findsNothing);
      });

      testWidgets(
          'invalid initialCode (wrong length) is ignored — manual entry',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: '12'));

        expect(find.text('Enter Room Code'), findsOneWidget);
        // Code fields should be empty.
        final textFields = find.byType(TextField);
        for (var i = 0; i < 4; i++) {
          final field = tester.widget<TextField>(textFields.at(i));
          expect(field.controller!.text, isEmpty);
        }
      });

      testWidgets(
          'invalid initialCode (too long) is ignored — manual entry',
          (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'ABCDE'));

        expect(find.text('Enter Room Code'), findsOneWidget);
      });

      testWidgets('lowercase initialCode is uppercased', (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'abcd'));

        final textFields = find.byType(TextField);
        for (var i = 0; i < 4; i++) {
          final field = tester.widget<TextField>(textFields.at(i));
          expect(field.controller!.text, 'ABCD'[i]);
        }
      });

      testWidgets('non-alpha initialCode is ignored', (tester) async {
        await tester.pumpApp(buildSubject(initialCode: 'AB1D'));

        expect(find.text('Enter Room Code'), findsOneWidget);
      });
    });
  });
}
