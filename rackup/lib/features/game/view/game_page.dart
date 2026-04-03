import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/audio/audio_listener.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/services/wake_lock_manager.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/view/player_screen.dart';
import 'package:rackup/features/game/view/referee_screen.dart';
import 'package:rackup/features/game/view/widgets/role_reveal_overlay.dart';
import 'package:rackup/features/game/view/widgets/record_this_overlay.dart';
import 'package:rackup/features/game/view/widgets/triple_points_overlay.dart';

/// Orchestrates role reveal and screen routing based on game state.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _overlayDismissed = false;
  bool _triplePointsShown = false;
  bool _triplePointsOverlayVisible = false;
  NavigatorState? _triplePointsNavigator;
  bool _recordThisOverlayVisible = false;
  NavigatorState? _recordThisNavigator;
  late final SoundManager _soundManager;
  late final WakeLockManager _wakeLockManager;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _soundManager = SoundManager();
    unawaited(_soundManager.init());
    _wakeLockManager = WakeLockManager();
    unawaited(_wakeLockManager.enable());
  }

  @override
  void dispose() {
    try {
      unawaited(_soundManager.dispose());
    } finally {
      unawaited(_wakeLockManager.disable());
    }
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
      child: AudioListener(
        soundManager: _soundManager,
        child: MultiBlocListener(
        listeners: [
          BlocListener<GameBloc, GameState>(
            listenWhen: (prev, curr) {
              if (prev is! GameActive || curr is! GameActive) return false;
              if (prev.isTriplePoints && !curr.isTriplePoints) {
                return true;
              }
              return !prev.isTriplePoints && curr.isTriplePoints;
            },
            listener: (context, state) {
              final active = state as GameActive;
              if (!active.isTriplePoints) {
                _triplePointsShown = false;
                return;
              }
              if (_triplePointsShown) return;
              _triplePointsShown = true;
              _triplePointsOverlayVisible = true;
              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.transparent,
                pageBuilder: (dialogContext, __, ___) {
                  _triplePointsNavigator = Navigator.of(dialogContext);
                  return TriplePointsOverlay(
                    onDismissed: () {
                      _triplePointsOverlayVisible = false;
                      _triplePointsNavigator = null;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  );
                },
              );
            },
          ),
          BlocListener<GameBloc, GameState>(
            listenWhen: (prev, curr) {
              if (prev is! GameActive || curr is! GameActive) return false;
              return !prev.showRecordThis && curr.showRecordThis;
            },
            listener: (context, state) {
              final active = state as GameActive;

              // RECORD THIS overrides triple points (cascade priority).
              if (_triplePointsOverlayVisible) {
                _triplePointsNavigator?.pop();
                _triplePointsNavigator = null;
                _triplePointsOverlayVisible = false;
              }

              _recordThisOverlayVisible = true;

              // Resolve current tier label.
              final tierLabel = switch (active.tier) {
                EscalationTier.mild => 'Mild',
                EscalationTier.medium => 'Medium',
                EscalationTier.spicy => 'Spicy',
                _ => '',
              };

              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.transparent,
                pageBuilder: (dialogContext, __, ___) {
                  _recordThisNavigator = Navigator.of(dialogContext);
                  return RecordThisOverlay(
                    subtext: active.recordThisSubtext,
                    tierLabel: tierLabel,
                    onDismissed: () {
                      _recordThisOverlayVisible = false;
                      _recordThisNavigator = null;
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        context
                            .read<GameBloc>()
                            .add(const RecordThisDismissed());
                      }
                    },
                  );
                },
              );
            },
          ),
          BlocListener<GameBloc, GameState>(
            listenWhen: (prev, curr) => curr is GameEnded,
            listener: (context, state) {
              unawaited(_wakeLockManager.disable());
              if (_triplePointsOverlayVisible) {
                _triplePointsNavigator?.pop();
                _triplePointsNavigator = null;
                _triplePointsOverlayVisible = false;
              }
              if (_recordThisOverlayVisible) {
                _recordThisNavigator?.pop();
                _recordThisNavigator = null;
                _recordThisOverlayVisible = false;
                context
                    .read<GameBloc>()
                    .add(const RecordThisDismissed());
              }
            },
          ),
        ],
        child: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
          if (state is GameEnded) {
            return _buildGameOverScreen(state);
          }

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
      ),
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
      isTriplePoints: state.isTriplePoints,
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
      isTriplePoints: state.isTriplePoints,
    );
  }

  /// Placeholder game-over screen. Epic 8 replaces with full ceremony.
  Widget _buildGameOverScreen(GameEnded state) {
    final sorted = List.of(state.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.bold,
                fontSize: 48,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final player = sorted[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? const Color(0xFFFFD700)
                                  : RackUpColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            player.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              color: RackUpColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${player.score}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: RackUpColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
