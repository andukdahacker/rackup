import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/audio/sound_manager.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

/// Widget that listens to game blocs and triggers sound effects.
///
/// This is the single place that decides "this event makes a noise".
/// No bloc ever calls audio directly — all sound triggering goes through here.
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

    // EXTENSION POINT: Blue Shell impact sound (Epic 5)
    // When ItemBloc is implemented, add a BlocListener here that
    // triggers `soundManager.play(GameSound.blueShellImpact)` on
    // Blue Shell deployment events.

    // EXTENSION POINT: Podium fanfare sound (Epic 8)
    // When PostgameBloc is implemented, add a BlocListener here that
    // triggers `soundManager.play(GameSound.podiumFanfare)` on
    // 1st place podium reveal.

    return BlocListener<LeaderboardBloc, LeaderboardState>(
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

        // Both flags can be true simultaneously (a streak milestone causes a
        // leaderboard shuffle). Play streakFire first, then shuffle.
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
      child: child,
    );
  }
}
