import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/create_room_page.dart';
import 'package:rackup/l10n/l10n.dart';

class MockRoomBloc extends MockBloc<RoomEvent, RoomState>
    implements RoomBloc {}

void main() {
  late MockRoomBloc roomBloc;

  setUp(() {
    roomBloc = MockRoomBloc();
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RackUpColors.canvas,
        textTheme: RackUpTypography.buildTextTheme(),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RackUpGameTheme(
        data: const RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: false,
        ),
        child: BlocProvider<RoomBloc>.value(
          value: roomBloc,
          child: const CreateRoomPage(),
        ),
      ),
    );
  }

  group('CreateRoomPage', () {
    testWidgets('shows loading state', (tester) async {
      when(() => roomBloc.state).thenReturn(const RoomCreating());

      await tester.pumpWidget(buildSubject());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating room...'), findsOneWidget);
    });

    testWidgets('shows loading on success (navigates to lobby)', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomCreatedState(roomCode: 'ABCD', jwt: 'jwt'),
      );

      await tester.pumpWidget(buildSubject());

      // RoomCreatedState now shows loading while navigating to /lobby.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating room...'), findsOneWidget);
    });

    testWidgets('shows error with retry button', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomError(message: 'Network error'),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('tapping Try Again dispatches CreateRoom', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomError(message: 'Failed'),
      );

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Try Again'));

      verify(() => roomBloc.add(const CreateRoom())).called(1);
    });
  });
}
