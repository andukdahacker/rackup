import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/view/player_screen.dart';
import 'package:rackup/features/game/view/referee_screen.dart';
import 'package:rackup/features/game/view/widgets/role_reveal_overlay.dart';

/// Orchestrates role reveal and screen routing based on game state.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _overlayDismissed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Finds a player by device ID hash, or null if not found.
  static GamePlayer? _findPlayer(
    List<GamePlayer> players,
    String deviceIdHash,
  ) {
    for (final p in players) {
      if (p.deviceIdHash == deviceIdHash) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is! GameActive) {
            return const Scaffold(
              backgroundColor: RackUpColors.canvas,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final myDeviceIdHash =
              context.read<DeviceIdentityService>().getHashedDeviceId();
          final isReferee = state.refereeDeviceIdHash == myDeviceIdHash;

          final progressionPercentage = state.roundCount > 0
              ? (state.currentRound - 1) / state.roundCount * 100
              : 0.0;

          return RackUpGameTheme(
            data: RackUpGameTheme.fromProgression(
              percentage: progressionPercentage,
              animationsEnabled:
                  !MediaQuery.of(context).disableAnimations,
            ),
            child: isReferee
                ? _buildRefereeContent(state, myDeviceIdHash)
                : _buildPlayerContent(state, myDeviceIdHash),
          );
        },
      ),
    );
  }

  Widget _buildRefereeContent(GameActive state, String myDeviceIdHash) {
    if (!_overlayDismissed) {
      final referee = _findPlayer(state.players, state.refereeDeviceIdHash);
      if (referee == null) return const SizedBox.shrink();

      return RoleRevealOverlay(
        refereeName: referee.displayName,
        refereeSlot: referee.slot,
        onDismissed: () {
          setState(() {
            _overlayDismissed = true;
          });
        },
      );
    }

    final currentShooter =
        _findPlayer(state.players, state.currentShooterDeviceIdHash);
    if (currentShooter == null) return const SizedBox.shrink();

    return RefereeScreen(
      currentRound: state.currentRound,
      totalRounds: state.roundCount,
      tier: state.tier,
      currentShooter: currentShooter,
      webSocketCubit: context.read<WebSocketCubit>(),
      leaderboardBloc: context.read<LeaderboardBloc>(),
    );
  }

  Widget _buildPlayerContent(GameActive state, String myDeviceIdHash) {
    return PlayerScreen(
      currentRound: state.currentRound,
      totalRounds: state.roundCount,
      tier: state.tier,
      players: state.players,
      myDeviceIdHash: myDeviceIdHash,
      currentShooterDeviceIdHash: state.currentShooterDeviceIdHash,
      leaderboardBloc: context.read<LeaderboardBloc>(),
    );
  }
}
