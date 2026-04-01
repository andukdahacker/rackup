import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/home/view/home_page.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/lobby/view/create_room_page.dart';
import 'package:rackup/features/lobby/view/join_room_page.dart';
import 'package:rackup/features/lobby/view/lobby_page.dart';
import 'package:rackup/l10n/l10n.dart';

class _MockGoRouter extends Mock implements GoRouter {}

class _MockRoomBloc extends MockBloc<RoomEvent, RoomState>
    implements RoomBloc {}

class _MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {}

class _MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

/// Helper to pump a widget with full theme and game theme.
Future<void> _pumpWithTheme(
  WidgetTester tester,
  Widget widget, {
  bool disableAnimations = false,
  double textScaleFactor = 1.0,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RackUpColors.canvas,
        colorScheme: const ColorScheme.dark(
          surface: RackUpColors.canvas,
          primary: RackUpColors.itemBlue,
          secondary: RackUpColors.missionPurple,
          error: RackUpColors.missedRed,
        ),
        textTheme: RackUpTypography.buildTextTheme(),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        );
      },
      home: Builder(
        builder: (context) {
          final disable = MediaQuery.of(context).disableAnimations;
          return RackUpGameTheme(
            data: RackUpGameThemeData(
              tier: EscalationTier.lobby,
              backgroundColor: RackUpColors.tierLobby,
              animationsEnabled: !disable,
            ),
            child: widget,
          );
        },
      ),
    ),
  );
}

void main() {
  group('Accessibility: Semantics on Home page', () {
    late GoRouter mockRouter;

    setUp(() {
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push<Object?>(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => null);
    });

    testWidgets('headline has header semantics', (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      // Find Semantics with header: true wrapping the headline.
      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.header == true,
        ),
      );
      expect(semanticsWidgets, isNotEmpty,
          reason: 'Headline should have Semantics with header: true');
    });

    testWidgets('Create Room button has semantics label', (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Create Room',
        ),
      );
      expect(semanticsWidgets.length, 1);
    });

    testWidgets('Join Room button has semantics label', (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Join Room',
        ),
      );
      expect(semanticsWidgets.length, 1);
    });
  });

  group('Accessibility: Semantics on Join Room page', () {
    late _MockRoomBloc bloc;

    setUpAll(() {
      registerFallbackValue(
        const JoinRoom(code: 'AAAA', displayName: 'Test'),
      );
    });

    setUp(() {
      bloc = _MockRoomBloc();
      when(() => bloc.state).thenReturn(const RoomInitial());
    });

    testWidgets('code input fields have digit semantics labels',
        (tester) async {
      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
      );

      for (var i = 1; i <= 4; i++) {
        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Room code digit $i of 4',
        );
        expect(semanticsFinder, findsOneWidget,
            reason: 'Code field $i should have label '
                '"Room code digit $i of 4"');
      }
    });

    testWidgets('display name field has semantics label', (tester) async {
      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
      );

      // Label is now provided via InputDecoration.labelText on the TextField.
      final textFieldFinder = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Display name',
      );
      expect(textFieldFinder, findsOneWidget);
    });

    testWidgets('Join button has "Join room" semantics label', (tester) async {
      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Join room',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('heading has header semantics', (tester) async {
      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      );
      // At least one header (the form heading); AppBar may also add one.
      expect(semanticsFinder, findsAtLeastNWidgets(1));
    });
  });

  group('Accessibility: Semantics on Create Room page', () {
    late _MockRoomBloc roomBloc;

    setUp(() {
      roomBloc = _MockRoomBloc();
    });

    testWidgets('Share Invite Link button has semantics in lobby', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomLobby(
          players: [],
          roomCode: 'ABCD',
          jwt: 'jwt',
          hostDeviceIdHash: 'host',
        ),
      );

      final mockWsCubit = _MockWebSocketCubit();
      when(() => mockWsCubit.messages).thenAnswer(
        (_) => const Stream.empty(),
      );

      final mockDeviceIdentityService = _MockDeviceIdentityService();
      when(() => mockDeviceIdentityService.getHashedDeviceId())
          .thenReturn('host');

      await _pumpWithTheme(
        tester,
        RepositoryProvider<DeviceIdentityService>.value(
          value: mockDeviceIdentityService,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<RoomBloc>.value(value: roomBloc),
              BlocProvider<WebSocketCubit>.value(value: mockWsCubit),
            ],
            child: const LobbyPage(),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Share Invite Link',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Try Again button has semantics', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomError(message: 'Network error'),
      );

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: roomBloc,
          child: const CreateRoomPage(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Try Again',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('loading state has live region semantics', (tester) async {
      when(() => roomBloc.state).thenReturn(const RoomCreating());

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: roomBloc,
          child: const CreateRoomPage(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('error state has live region semantics for message',
        (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomError(message: 'Network error'),
      );

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: roomBloc,
          child: const CreateRoomPage(),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('error icon is excluded from semantics', (tester) async {
      when(() => roomBloc.state).thenReturn(
        const RoomError(message: 'Error'),
      );

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: roomBloc,
          child: const CreateRoomPage(),
        ),
      );

      // Find ExcludeSemantics wrapping an Icon widget specifically.
      final excludeFinder = find.byWidgetPredicate(
        (w) =>
            w is ExcludeSemantics &&
            w.excluding &&
            w.child is Icon,
      );
      expect(excludeFinder, findsOneWidget);
    });
  });

  group('Accessibility: Reduced motion', () {
    test('tierTransitionDuration is zero when animations disabled', () {
      const data = RackUpGameThemeData(
        tier: EscalationTier.mild,
        backgroundColor: RackUpColors.tierMild,
        animationsEnabled: false,
      );
      expect(data.tierTransitionDuration, Duration.zero);
    });

    test('tierTransitionDuration is 500ms when animations enabled', () {
      const data = RackUpGameThemeData(
        tier: EscalationTier.mild,
        backgroundColor: RackUpColors.tierMild,
        animationsEnabled: true,
      );
      expect(data.tierTransitionDuration, const Duration(milliseconds: 500));
    });

    testWidgets('app propagates disableAnimations to game theme',
        (tester) async {
      late RackUpGameThemeData captured;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final disable = MediaQuery.of(context).disableAnimations;
                return RackUpGameTheme(
                  data: RackUpGameTheme.fromProgression(
                    percentage: 50,
                    animationsEnabled: !disable,
                  ),
                  child: Builder(
                    builder: (innerContext) {
                      captured = RackUpGameTheme.of(innerContext);
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(captured.animationsEnabled, isFalse);
      expect(captured.tierTransitionDuration, Duration.zero);
    });
  });

  group('Accessibility: Tap target sizes', () {
    late GoRouter mockRouter;

    setUp(() {
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push<Object?>(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => null);
    });

    testWidgets('Home page buttons meet 56dp minimum height', (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height != null &&
              widget.height! >= RackUpSpacing.minTapTarget,
        ),
      );
      // At least 2 buttons (Create Room, Join Room)
      expect(sizedBoxes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('Home page primary buttons are 64dp height', (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == RackUpSpacing.primaryButtonHeight,
        ),
      );
      expect(sizedBoxes.length, 2);
    });

    testWidgets('Join Room page join button is 64dp height', (tester) async {
      final bloc = _MockRoomBloc();
      when(() => bloc.state).thenReturn(const RoomInitial());

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == RackUpSpacing.primaryButtonHeight,
        ),
      );
      expect(sizedBoxes.length, greaterThanOrEqualTo(1));
    });
  });

  group('Accessibility: Text scaling', () {
    late GoRouter mockRouter;

    setUp(() {
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push<Object?>(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => null);
    });

    testWidgets('Home page renders without overflow at 2.0x text scale',
        (tester) async {
      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
        textScaleFactor: 2,
      );

      // Verify the page renders without throwing layout errors.
      expect(tester.takeException(), isNull);
      expect(find.text('Turn pool night into chaos'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join Room'), findsOneWidget);
    });

    testWidgets('Join Room page renders without overflow at 2.0x text scale',
        (tester) async {
      final bloc = _MockRoomBloc();
      when(() => bloc.state).thenReturn(const RoomInitial());

      await _pumpWithTheme(
        tester,
        BlocProvider<RoomBloc>.value(
          value: bloc,
          child: const JoinRoomPage(),
        ),
        textScaleFactor: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Enter Room Code'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets(
        'Lobby page renders without overflow at 2.0x text scale',
        (tester) async {
      final bloc = _MockRoomBloc();
      when(() => bloc.state).thenReturn(
        const RoomLobby(
          players: [],
          roomCode: 'ABCD',
          jwt: 'jwt',
          hostDeviceIdHash: 'host',
        ),
      );
      final mockWsCubit = _MockWebSocketCubit();
      when(() => mockWsCubit.messages).thenAnswer(
        (_) => const Stream.empty(),
      );

      final mockDeviceIdentityService = _MockDeviceIdentityService();
      when(() => mockDeviceIdentityService.getHashedDeviceId())
          .thenReturn('host');

      await _pumpWithTheme(
        tester,
        RepositoryProvider<DeviceIdentityService>.value(
          value: mockDeviceIdentityService,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<RoomBloc>.value(value: bloc),
              BlocProvider<WebSocketCubit>.value(value: mockWsCubit),
            ],
            child: const LobbyPage(),
          ),
        ),
        textScaleFactor: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ABCD'), findsOneWidget);
      expect(find.text('Share Invite Link'), findsOneWidget);
    });
  });

  group('Accessibility: No precision gestures', () {
    testWidgets('no GestureDetector with pan/scale/longPressMove on Home',
        (tester) async {
      final mockRouter = _MockGoRouter();
      when(() => mockRouter.push<Object?>(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => null);

      await _pumpWithTheme(
        tester,
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );

      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );
      for (final gd in gestureDetectors) {
        expect(gd.onPanUpdate, isNull,
            reason: 'No precision pan gestures allowed');
        expect(gd.onScaleUpdate, isNull,
            reason: 'No precision scale gestures allowed');
        expect(gd.onLongPressMoveUpdate, isNull,
            reason: 'No precision long-press-drag gestures allowed');
      }
    });
  });
}
