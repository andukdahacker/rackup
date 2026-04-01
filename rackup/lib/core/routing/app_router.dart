import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/websocket/game_message_listener.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/view/game_page.dart';
import 'package:rackup/features/home/view/home_page.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/view/create_room_page.dart';
import 'package:rackup/features/lobby/view/join_room_page.dart';
import 'package:rackup/features/lobby/view/lobby_page.dart';

/// The application's root router configuration.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // ShellRoute hoists WebSocketCubit and RoomBloc so they persist
    // across /create → /lobby and /join → /lobby navigation.
    ShellRoute(
      builder: (context, state, child) {
        return _RoomShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateRoomPage(),
        ),
        GoRoute(
          path: '/join',
          builder: (context, state) => const JoinRoomPage(),
        ),
        // Deep link route: rackup.app/join/CODE pre-fills the room code.
        // TODO(phase-1.5): Deferred deep linking — preserve room code through
        // App Store install. Requires server-side redirect page at
        // rackup.app/join/:code or third-party service (Branch/custom).
        // MVP handles app-already-installed case only.
        GoRoute(
          path: '/join/:code',
          builder: (context, state) {
            final code = state.pathParameters['code'];
            return JoinRoomPage(initialCode: code);
          },
        ),
        GoRoute(
          path: '/lobby',
          builder: (context, state) => const LobbyPage(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => const GamePage(),
        ),
      ],
    ),
  ],
);

/// Shell widget that provides WebSocketCubit, RoomBloc, and GameBloc to all child routes.
class _RoomShell extends StatefulWidget {
  const _RoomShell({required this.child});

  final Widget child;

  @override
  State<_RoomShell> createState() => _RoomShellState();
}

class _RoomShellState extends State<_RoomShell> {
  late final WebSocketCubit _wsCubit;
  late final RoomBloc _roomBloc;
  late final GameBloc _gameBloc;
  GameMessageListener? _gameMessageListener;

  @override
  void initState() {
    super.initState();
    _wsCubit = WebSocketCubit();
    _gameBloc = GameBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create RoomBloc lazily on first build when context is available.
    if (!_blocCreated) {
      _roomBloc = RoomBloc(
        deviceIdentityService: context.read<DeviceIdentityService>(),
        roomApiService: context.read<RoomApiService>(),
        webSocketCubit: _wsCubit,
        config: context.read<AppConfig>(),
      );
      _gameMessageListener = GameMessageListener(
        webSocketCubit: _wsCubit,
        gameBloc: _gameBloc,
      );
      _blocCreated = true;
    }
  }

  bool _blocCreated = false;

  @override
  void dispose() {
    _gameMessageListener?.dispose();
    _gameBloc.close();
    _roomBloc.close();
    _wsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WebSocketCubit>.value(value: _wsCubit),
        BlocProvider<RoomBloc>.value(value: _roomBloc),
        BlocProvider<GameBloc>.value(value: _gameBloc),
      ],
      child: widget.child,
    );
  }
}
