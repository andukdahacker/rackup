import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';
import 'package:rackup/features/game/bloc/game_event.dart';

/// Data for a single targeting row.
class TargetData {
  const TargetData({
    required this.deviceIdHash,
    required this.displayName,
    required this.score,
    required this.rank,
    required this.slot,
  });

  final String deviceIdHash;
  final String displayName;
  final int score;
  final int rank;
  final int slot;
}

/// Shows the targeting overlay as a modal bottom sheet.
///
/// Returns the selected target's device ID hash, or null if dismissed.
Future<String?> showTargetingOverlay({
  required BuildContext context,
  required Item item,
  required List<TargetData> targets,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: const Color(0xFF1A1832),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _TargetingSheet(item: item, targets: targets),
  );
}

/// Builds [TargetData] list from leaderboard entries + game players.
///
/// Filters out the referee and the deployer. Sorted by rank ascending.
List<TargetData> buildTargetList({
  required List<LeaderboardEntry> entries,
  required String localDeviceIdHash,
  required String refereeDeviceIdHash,
  required Map<String, int> playerSlots,
}) {
  final targets = <TargetData>[];
  for (final entry in entries) {
    if (entry.deviceIdHash == localDeviceIdHash) continue;
    if (entry.deviceIdHash == refereeDeviceIdHash) continue;
    targets.add(TargetData(
      deviceIdHash: entry.deviceIdHash,
      displayName: entry.displayName,
      score: entry.score,
      rank: entry.rank,
      slot: playerSlots[entry.deviceIdHash] ?? 1,
    ));
  }
  targets.sort((a, b) => a.rank.compareTo(b.rank));
  return targets;
}

class _TargetingSheet extends StatelessWidget {
  const _TargetingSheet({required this.item, required this.targets});

  final Item item;
  final List<TargetData> targets;

  @override
  Widget build(BuildContext context) {
    final isBlueshell = item.type == 'blue_shell';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RackUpColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Title.
            Text(
              'Choose Target',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: RackUpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Target rows or empty state.
            if (targets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  'No valid targets available.',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    color: RackUpColors.textSecondary,
                  ),
                ),
              )
            else
              ...targets.map(
                (target) => _TargetingRow(
                  target: target,
                  isBlueShellFirstPlace:
                      isBlueshell && target.rank == 1,
                  onTap: () =>
                      Navigator.of(context).pop(target.deviceIdHash),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TargetingRow extends StatefulWidget {
  const _TargetingRow({
    required this.target,
    required this.isBlueShellFirstPlace,
    required this.onTap,
  });

  final TargetData target;
  final bool isBlueShellFirstPlace;
  final VoidCallback onTap;

  @override
  State<_TargetingRow> createState() => _TargetingRowState();
}

class _TargetingRowState extends State<_TargetingRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isBlueShellFirstPlace) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  TargetData get target => widget.target;
  bool get isBlueShellFirstPlace => widget.isBlueShellFirstPlace;
  VoidCallback get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final identity = PlayerIdentity.forSlot(target.slot);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isBlueShellFirstPlace
              ? Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                )
              : Border.all(
                  color: RackUpColors.textSecondary.withValues(alpha: 0.2),
                ),
          color: RackUpColors.canvas.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            // Rank.
            SizedBox(
              width: 28,
              child: Text(
                '#${target.rank}',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: RackUpColors.textSecondary,
                ),
              ),
            ),
            // Player shape.
            PlayerShapeWidget(
              shape: identity.shape,
              color: identity.color,
              size: 24,
            ),
            const SizedBox(width: 8),
            // Player name.
            Expanded(
              child: Text(
                target.displayName,
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: identity.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Score.
            Text(
              '${target.score}',
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RackUpColors.textPrimary,
              ),
            ),
            if (isBlueShellFirstPlace) ...[
              const SizedBox(width: 8),
              _PulsingCrosshair(animation: _pulseAnimation),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing crosshair icon for Blue Shell first-place targeting (AC3).
class _PulsingCrosshair extends AnimatedWidget {
  const _PulsingCrosshair({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final opacity = (listenable as Animation<double>).value;
    return Opacity(
      opacity: opacity,
      child: const Icon(
        Icons.gps_fixed,
        color: Color(0xFFFFD700),
        size: 20,
      ),
    );
  }
}
