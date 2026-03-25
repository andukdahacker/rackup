import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/config/app_config.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/room_api_service.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/home/view/home_page.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/view/create_room_page.dart';
import 'package:rackup/features/lobby/view/join_room_page.dart';

/// The application's root router configuration.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) {
        final wsCubit = WebSocketCubit();
        return MultiBlocProvider(
          providers: [
            BlocProvider<WebSocketCubit>.value(value: wsCubit),
            BlocProvider<RoomBloc>(
              create: (context) => RoomBloc(
                deviceIdentityService:
                    context.read<DeviceIdentityService>(),
                roomApiService: context.read<RoomApiService>(),
                webSocketCubit: wsCubit,
                config: context.read<AppConfig>(),
              ),
            ),
          ],
          child: const CreateRoomPage(),
        );
      },
    ),
    GoRoute(
      path: '/join',
      builder: (context, state) {
        final wsCubit = WebSocketCubit();
        return MultiBlocProvider(
          providers: [
            BlocProvider<WebSocketCubit>.value(value: wsCubit),
            BlocProvider<RoomBloc>(
              create: (context) => RoomBloc(
                deviceIdentityService:
                    context.read<DeviceIdentityService>(),
                roomApiService: context.read<RoomApiService>(),
                webSocketCubit: wsCubit,
                config: context.read<AppConfig>(),
              ),
            ),
          ],
          child: const JoinRoomPage(),
        );
      },
    ),
  ],
);
