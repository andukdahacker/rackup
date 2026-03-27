import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/lobby_page.dart';
import 'package:rackup/l10n/l10n.dart';

class MockRoomBloc extends MockBloc<RoomEvent, RoomState>
    implements RoomBloc {}

class MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {}

void main() {
  late MockRoomBloc roomBloc;
  late MockWebSocketCubit webSocketCubit;
  late StreamController<Message> messageController;

  setUp(() {
    roomBloc = MockRoomBloc();
    webSocketCubit = MockWebSocketCubit();
    messageController = StreamController<Message>.broadcast();

    when(() => webSocketCubit.messages).thenAnswer(
      (_) => messageController.stream,
    );
  });

  tearDown(() {
    messageController.close();
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoomBloc>.value(value: roomBloc),
            BlocProvider<WebSocketCubit>.value(value: webSocketCubit),
          ],
          child: const LobbyPage(),
        ),
      ),
    );
  }

  group('LobbyPage', () {
    testWidgets('shows loading when not in RoomLobby state', (tester) async {
      when(() => roomBloc.state).thenReturn(const RoomInitial());
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows room code when in RoomLobby state', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: [],
          roomCode: 'ABCD',
          jwt: 'jwt',
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.text('ABCD'), findsOneWidget);
    });

    testWidgets('shows Share Invite Link button', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: [],
          roomCode: 'ABCD',
          jwt: 'jwt',
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.text('Share Invite Link'), findsOneWidget);
    });

    testWidgets('shows player count', (tester) async {
      const players = [
        Player(
          displayName: 'Jake',
          deviceIdHash: 'hash1',
          slot: 1,
          isHost: true,
          status: PlayerStatus.joining,
        ),
        Player(
          displayName: 'Danny',
          deviceIdHash: 'hash2',
          slot: 2,
          isHost: false,
          status: PlayerStatus.joining,
        ),
      ];

      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: players,
          roomCode: 'ABCD',
          jwt: 'jwt',
        ),
      );
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Players (2)'), findsOneWidget);
    });

    testWidgets('shows player names in list', (tester) async {
      const players = [
        Player(
          displayName: 'Jake',
          deviceIdHash: 'hash1',
          slot: 1,
          isHost: true,
          status: PlayerStatus.joining,
        ),
      ];

      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: players,
          roomCode: 'ABCD',
          jwt: 'jwt',
        ),
      );
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Jake'), findsOneWidget);
    });

    testWidgets('has dark canvas background', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: [],
          roomCode: 'ABCD',
          jwt: 'jwt',
        ),
      );
      await tester.pumpWidget(buildSubject());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, RackUpColors.canvas);
    });
  });
}
