import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/cascade/cascade_timing.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/protocol/actions.dart' as proto;
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';
import 'package:rackup/features/game/view/widgets/big_binary_buttons.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';
import 'package:rackup/features/game/view/widgets/punishment_announcement_card.dart';
import 'package:rackup/features/game/view/widgets/streak_fire_indicator.dart';
import 'package:rackup/features/game/view/widgets/undo_button.dart';

/// Action Zone state for the referee shot confirmation flow.
enum _ActionZoneState { idle, confirmed, punishment }

/// The Referee Command Center — 4-region layout.
///
/// Regions: Status Bar (~60dp), Stage Area (~40%), Action Zone (~35%),
/// Footer (~80dp).
class RefereeScreen extends StatefulWidget {
  const RefereeScreen({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    required this.currentShooter,
    required this.webSocketCubit,
    required this.leaderboardBloc,
    this.isTriplePoints = false,
    this.lastPunishment,
    this.lastCascadeProfile = 'routine',
    this.isGameOver = false,
    this.gameBloc,
    super.key,
  });

  /// Current round number.
  final int currentRound;

  /// Total rounds.
  final int totalRounds;

  /// Current escalation tier.
  final EscalationTier tier;

  /// The player currently shooting.
  final GamePlayer currentShooter;

  /// Whether the game is in triple-point territory.
  final bool isTriplePoints;

  /// The last punishment drawn (null for MADE shots).
  final PunishmentPayload? lastPunishment;

  /// Cascade timing profile for punishment reveal delay.
  final String lastCascadeProfile;

  /// Whether this is the final turn (game ends after punishment delivery).
  final bool isGameOver;

  /// GameBloc for dispatching GameEndConfirmed after punishment delivery.
  final GameBloc? gameBloc;

  /// WebSocket cubit for sending messages.
  final WebSocketCubit webSocketCubit;

  /// LeaderboardBloc for footer leaderboard peek.
  final LeaderboardBloc leaderboardBloc;

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _RefereeScreenState extends State<RefereeScreen> {
  _ActionZoneState _actionState = _ActionZoneState.idle;
  PunishmentPayload? _pendingPunishment;
  String _pendingCascadeProfile = 'routine';
  bool _gameOverPending = false;
  Timer? _cascadeTimer;

  void _onShotConfirmed(String result) {
    // Guard against rapid double-tap.
    if (_actionState != _ActionZoneState.idle) return;
    widget.webSocketCubit.sendMessage(
      Message(
        action: proto.Actions.refereeConfirmShot,
        payload: ConfirmShotPayload(result: result).toJson(),
      ),
    );
    setState(() => _actionState = _ActionZoneState.confirmed);
  }

  void _onUndo() {
    widget.webSocketCubit.sendMessage(
      const Message(
        action: proto.Actions.refereeUndoShot,
        payload: <String, dynamic>{},
      ),
    );
    // Optimistic reset: if undo succeeds, server sends corrected turn_complete
    // for the same shooter. If undo fails (UNDO_EXPIRED), the turn already
    // advanced from the original shot — currentShooter prop reflects the next
    // player, so showing MADE/MISSED buttons for them is correct.
    _cascadeTimer?.cancel();
    setState(() {
      _actionState = _ActionZoneState.idle;
      _pendingPunishment = null;
    });
  }

  void _onUndoExpired() {
    if (_pendingPunishment != null) {
      // Wait cascade delay for suspense before showing punishment.
      final delay = CascadeTiming.delayFor(_pendingCascadeProfile);
      if (delay > Duration.zero) {
        _cascadeTimer = Timer(delay, () {
          if (!mounted) return;
          setState(() => _actionState = _ActionZoneState.punishment);
        });
      } else {
        setState(() => _actionState = _ActionZoneState.punishment);
      }
    } else {
      setState(() => _actionState = _ActionZoneState.idle);
    }
  }

  void _onPunishmentDelivered() {
    if (_gameOverPending) {
      // Dispatch GameEndConfirmed so GameBloc transitions to GameEnded.
      // The GameEnded BlocListener in game_page handles navigation.
      widget.gameBloc?.add(const GameEndConfirmed());
      setState(() {
        _actionState = _ActionZoneState.idle;
        _pendingPunishment = null;
        _gameOverPending = false;
      });
      return;
    }
    setState(() {
      _actionState = _ActionZoneState.idle;
      _pendingPunishment = null;
    });
  }

  @override
  void didUpdateWidget(covariant RefereeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Capture punishment from new props before any reset logic.
    if (widget.lastPunishment != null &&
        widget.lastPunishment != oldWidget.lastPunishment) {
      _pendingPunishment = widget.lastPunishment;
      _pendingCascadeProfile = widget.lastCascadeProfile;
      if (widget.isGameOver) {
        _gameOverPending = true;
      }
    }

    final turnChanged =
        oldWidget.currentShooter.deviceIdHash !=
            widget.currentShooter.deviceIdHash ||
        oldWidget.currentRound != widget.currentRound;

    if (!turnChanged) return;

    // Race condition fix: if in confirmed state (undo running), do NOT reset
    // to idle — the undo/punishment flow is still in progress.
    if (_actionState == _ActionZoneState.confirmed) return;

    // For idle or punishment states, reset to idle on turn change.
    _cascadeTimer?.cancel();
    setState(() {
      _actionState = _ActionZoneState.idle;
      _pendingPunishment = null;
    });
  }

  @override
  void dispose() {
    _cascadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = RackUpGameTheme.maybeOf(context);
    final bgColor = themeData?.backgroundColor ?? RackUpColors.canvas;
    final transitionDuration =
        themeData?.tierTransitionDuration ?? Duration.zero;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedContainer(
        duration: transitionDuration,
        color: bgColor,
        child: SafeArea(
          child: Column(
            children: [
              // Status Bar (~60dp).
              ProgressTierBar(
                currentRound: widget.currentRound,
                totalRounds: widget.totalRounds,
                tier: widget.tier,
                isTriplePoints: widget.isTriplePoints,
              ),
            // Stage Area (~40%).
            Expanded(
              flex: 40,
              child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
                bloc: widget.leaderboardBloc,
                builder: (context, lbState) {
                  // Derive streak info from leaderboard state if available.
                  String streakLabel;
                  bool isMilestone;
                  if (lbState is LeaderboardActive) {
                    final shooterEntry = lbState.entries
                        .where(
                          (e) =>
                              e.deviceIdHash ==
                              widget.currentShooter.deviceIdHash,
                        )
                        .firstOrNull;
                    streakLabel = shooterEntry?.streakLabel ?? '';
                    isMilestone = lbState.streakMilestone &&
                        lbState.shooterHash ==
                            widget.currentShooter.deviceIdHash;
                  } else {
                    streakLabel = '';
                    isMilestone = false;
                  }

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerNameTag(
                          displayName:
                              widget.currentShooter.displayName,
                          slot: widget.currentShooter.slot,
                          size: PlayerNameTagSize.large,
                        ),
                        if (streakLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          StreakFireIndicator(
                            streakLabel: streakLabel,
                            isMilestone: isMilestone,
                          ),
                        ],
                        // Milestone banner in Stage Area.
                        if (isMilestone && streakLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _milestoneBannerText(streakLabel),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: RackUpColors.streakGold,
                            ),
                            textScaler: ClampedTextScaler.of(
                              context,
                              TextRole.body,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Action Zone (~35%).
            Expanded(
              flex: 35,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (_actionState) {
                    _ActionZoneState.idle => BigBinaryButtons(
                        key: const ValueKey('buttons'),
                        onMade: () => _onShotConfirmed('made'),
                        onMissed: () => _onShotConfirmed('missed'),
                      ),
                    _ActionZoneState.confirmed => UndoButton(
                        key: const ValueKey('undo'),
                        onUndo: _onUndo,
                        onExpired: _onUndoExpired,
                      ),
                    _ActionZoneState.punishment => PunishmentAnnouncementCard(
                        key: const ValueKey('punishment'),
                        punishment: _pendingPunishment!,
                        onDelivered: _onPunishmentDelivered,
                      ),
                  },
                ),
              ),
            ),
            // Footer (~80dp) — leaderboard peek (top 3).
            SizedBox(
              height: 80,
              child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
                bloc: widget.leaderboardBloc,
                builder: (context, state) {
                  if (state is! LeaderboardActive ||
                      state.entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 16,
                          color: RackUpColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final top3 = state.entries.take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final entry in top3)
                          _FooterLeaderboardEntry(entry: entry),
                      ],
                    ),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  static String _milestoneBannerText(String streakLabel) {
    return switch (streakLabel) {
      'warming_up' => 'WARMING UP!',
      'on_fire' => 'ON FIRE!',
      'unstoppable' => 'UNSTOPPABLE!',
      _ => '',
    };
  }
}

class _FooterLeaderboardEntry extends StatelessWidget {
  const _FooterLeaderboardEntry({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#${entry.rank}',
          style: TextStyle(
            fontSize: 12,
            color: entry.rank == 1
                ? RackUpColors.streakGold
                : RackUpColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
          textScaler: ClampedTextScaler.of(context, TextRole.body),
        ),
        Text(
          entry.displayName,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RackUpColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
          textScaler: ClampedTextScaler.of(context, TextRole.body),
        ),
        Text(
          '${entry.score}',
          style: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: RackUpColors.textPrimary,
          ),
          textScaler: ClampedTextScaler.of(context, TextRole.body),
        ),
      ],
    );
  }
}
