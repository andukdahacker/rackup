import 'package:flutter/material.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';
import 'package:rackup/features/game/view/widgets/progress_tier_bar.dart';

/// The Player Screen — 4-region layout for non-referee players.
///
/// Regions: Header (~60dp), Leaderboard (~50%), Event Feed (~25%),
/// My Status (~15%).
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    required this.currentRound,
    required this.totalRounds,
    required this.tier,
    required this.players,
    required this.myDeviceIdHash,
    super.key,
  });

  /// Current round number.
  final int currentRound;

  /// Total rounds.
  final int totalRounds;

  /// Current escalation tier.
  final EscalationTier tier;

  /// All players in the game.
  final List<GamePlayer> players;

  /// The current device's ID hash (for highlighting self row).
  final String myDeviceIdHash;

  @override
  Widget build(BuildContext context) {
    GamePlayer? myPlayer;
    for (final p in players) {
      if (p.deviceIdHash == myDeviceIdHash) {
        myPlayer = p;
        break;
      }
    }

    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header (~60dp).
            ProgressTierBar(
              currentRound: currentRound,
              totalRounds: totalRounds,
              tier: tier,
            ),
            // Leaderboard (~50%).
            Expanded(
              flex: 50,
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  final isSelf = player.deviceIdHash == myDeviceIdHash;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: PlayerNameTag(
                            displayName: player.displayName,
                            slot: player.slot,
                            tagState: isSelf
                                ? PlayerNameTagState.highlighted
                                : PlayerNameTagState.normal,
                          ),
                        ),
                        Text(
                          '${player.score}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: RackUpColors.textPrimary,
                          ),
                          textScaler:
                              ClampedTextScaler.of(context, TextRole.body),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Event Feed (~25%).
            Expanded(
              flex: 25,
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.topLeft,
                child: Text(
                  'Game started!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: RackUpColors.textSecondary,
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                ),
              ),
            ),
            // My Status (~15%).
            Expanded(
              flex: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (myPlayer != null)
                      Expanded(
                        child: PlayerNameTag(
                          displayName: myPlayer!.displayName,
                          slot: myPlayer!.slot,
                          size: PlayerNameTagSize.compact,
                        ),
                      ),
                    Text(
                      '${myPlayer?.score ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: RackUpColors.textPrimary,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'No items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RackUpColors.textSecondary,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
