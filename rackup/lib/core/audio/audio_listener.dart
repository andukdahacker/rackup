import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/features/game/bloc/item_deployment_events_cubit.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

/// Widget that listens to game blocs and triggers sound effects.
///
/// This is the single place that decides "this event makes a noise".
/// No bloc ever calls audio directly — all sound triggering goes through here.
///
/// Item deployment sounds listen to [ItemDeploymentEventsCubit] (broadcast
/// to all clients), NOT [ItemBloc] (deployer only). This way the impact
/// sound is audible on every device when an item deploys, matching the
/// "social moment" intent of AC #3 / AC #5.
class AudioListener extends StatelessWidget {
  /// Creates an [AudioListener].
  const AudioListener({
    required this.soundManager,
    required this.child,
    super.key,
  });

  /// The sound manager used to play sound effects.
  final SoundManager soundManager;

  /// The child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Punishment reveal sound (Epic 4): Triggered from GameMessageListener
    // when turn_complete contains a punishment payload, not via BlocListener.

    // EXTENSION POINT: Podium fanfare sound (Epic 8)
    // When PostgameBloc is implemented, add a BlocListener here that
    // triggers `soundManager.play(GameSound.podiumFanfare)` on
    // 1st place podium reveal.

    return MultiBlocListener(
      listeners: [
        BlocListener<LeaderboardBloc, LeaderboardState>(
          listenWhen: (prev, curr) {
            if (curr is! LeaderboardActive) return false;
            final prevActive = prev is LeaderboardActive ? prev : null;
            final milestoneChanged =
                curr.streakMilestone && prevActive?.streakMilestone != true;
            final shuffleChanged =
                curr.shuffleOccurred && prevActive?.shuffleOccurred != true;
            return milestoneChanged || shuffleChanged;
          },
          listener: (context, state) {
            if (state is! LeaderboardActive) return;

            // Both flags can be true simultaneously (a streak milestone causes
            // a leaderboard shuffle). Play streakFire first, then shuffle.
            if (state.streakMilestone) {
              unawaited(soundManager.play(GameSound.streakFire).then((_) {
                if (state.shuffleOccurred) {
                  soundManager.play(GameSound.leaderboardShuffle);
                }
              }));
            } else if (state.shuffleOccurred) {
              unawaited(soundManager.play(GameSound.leaderboardShuffle));
            }
          },
        ),
        BlocListener<ItemDeploymentEventsCubit, ItemDeploymentEventState>(
          // Sequence number guarantees we react to repeated identical events.
          listenWhen: (prev, curr) => curr.sequence != prev.sequence,
          listener: (context, state) {
            // Fizzled — visual-only per spec, no sound.
            if (state.kind != ItemDeploymentEventKind.deployed) return;

            // Optimistic-immediate playback: this listener fires the moment
            // the server broadcasts `item.deployed` to every client, so the
            // sound aligns with the impact animation across all devices.
            final sound = state.itemType == 'blue_shell'
                ? GameSound.blueShellImpact
                : GameSound.itemDeployed;
            unawaited(soundManager.play(sound));
          },
        ),
      ],
      child: child,
    );
  }
}
