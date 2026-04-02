import 'package:flutter/material.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/protocol/actions.dart' as proto;
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/view/widgets/big_binary_buttons.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';
import 'package:rackup/features/game/view/widgets/undo_button.dart';

/// Action Zone state for the referee shot confirmation flow.
enum _ActionZoneState { idle, confirmed }

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

  /// WebSocket cubit for sending messages.
  final WebSocketCubit webSocketCubit;

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _RefereeScreenState extends State<RefereeScreen> {
  _ActionZoneState _actionState = _ActionZoneState.idle;

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
      Message(
        action: proto.Actions.refereeUndoShot,
        payload: const <String, dynamic>{},
      ),
    );
    setState(() => _actionState = _ActionZoneState.idle);
  }

  void _onUndoExpired() {
    setState(() => _actionState = _ActionZoneState.idle);
  }

  @override
  void didUpdateWidget(covariant RefereeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the turn changes, reset to idle. Compare both shooter and round
    // to handle same-shooter consecutive turns (small games).
    if (oldWidget.currentShooter.deviceIdHash !=
            widget.currentShooter.deviceIdHash ||
        oldWidget.currentRound != widget.currentRound) {
      setState(() => _actionState = _ActionZoneState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar (~60dp).
            ProgressTierBar(
              currentRound: widget.currentRound,
              totalRounds: widget.totalRounds,
              tier: widget.tier,
            ),
            // Stage Area (~40%).
            Expanded(
              flex: 40,
              child: Center(
                child: PlayerNameTag(
                  displayName: widget.currentShooter.displayName,
                  slot: widget.currentShooter.slot,
                  size: PlayerNameTagSize.large,
                ),
              ),
            ),
            // Action Zone (~35%).
            Expanded(
              flex: 35,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _actionState == _ActionZoneState.idle
                      ? BigBinaryButtons(
                          key: const ValueKey('buttons'),
                          onMade: () => _onShotConfirmed('made'),
                          onMissed: () => _onShotConfirmed('missed'),
                        )
                      : UndoButton(
                          key: const ValueKey('undo'),
                          onUndo: _onUndo,
                          onExpired: _onUndoExpired,
                        ),
                ),
              ),
            ),
            // Footer (~80dp).
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 16,
                    color: RackUpColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
