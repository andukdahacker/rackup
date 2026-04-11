import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rackup/core/models/item.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

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
/// Subscribes to [LeaderboardBloc] internally so ranks/scores update live
/// while the overlay is open (anytime-deployment can happen mid-cascade).
///
/// Returns the selected target's device ID hash, or null if dismissed.
Future<String?> showTargetingOverlay({
  required BuildContext context,
  required Item item,
  required String localDeviceIdHash,
  required String refereeDeviceIdHash,
  required Map<String, int> playerSlots,
}) {
  // Capture the LeaderboardBloc from the calling context — modal bottom sheets
  // are pushed onto the root Navigator and don't inherit our provider tree.
  final leaderboardBloc = context.read<LeaderboardBloc>();

  return showModalBottomSheet<String>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: RackUpColors.overlayBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: leaderboardBloc,
      child: _TargetingSheet(
        item: item,
        localDeviceIdHash: localDeviceIdHash,
        refereeDeviceIdHash: refereeDeviceIdHash,
        playerSlots: playerSlots,
      ),
    ),
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
  const _TargetingSheet({
    required this.item,
    required this.localDeviceIdHash,
    required this.refereeDeviceIdHash,
    required this.playerSlots,
  });

  final Item item;
  final String localDeviceIdHash;
  final String refereeDeviceIdHash;
  final Map<String, int> playerSlots;

  @override
  Widget build(BuildContext context) {
    final isBlueshell = item.type == 'blue_shell';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, lbState) {
            final entries = lbState is LeaderboardActive ? lbState.entries : const <LeaderboardEntry>[];
            final targets = buildTargetList(
              entries: entries,
              localDeviceIdHash: localDeviceIdHash,
              refereeDeviceIdHash: refereeDeviceIdHash,
              playerSlots: playerSlots,
            );

            return Column(
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
                // Target rows or empty state with explicit cancel.
                if (targets.isEmpty)
                  _EmptyTargetsView(
                    onCancel: () => Navigator.of(context).pop(),
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
            );
          },
        ),
      ),
    );
  }
}

/// Empty-state view shown when no valid targets exist (e.g., everyone else
/// disconnected or only the referee remains). Provides an explicit cancel
/// path so the user is not dead-ended.
class _EmptyTargetsView extends StatelessWidget {
  const _EmptyTargetsView({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text(
            'No valid targets available.',
            style: GoogleFonts.oswald(
              fontSize: 16,
              color: RackUpColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: 'Cancel item targeting',
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                'CANCEL',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: RackUpColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
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
    final semanticsLabel = isBlueShellFirstPlace
        ? 'Target ${target.displayName}, rank ${target.rank}, score ${target.score}, currently in first place'
        : 'Target ${target.displayName}, rank ${target.rank}, score ${target.score}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
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
                    color: RackUpColors.itemGold,
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
              if (isBlueShellFirstPlace && _pulseController != null) ...[
                const SizedBox(width: 8),
                _PulsingCrosshair(animation: _pulseAnimation),
              ],
            ],
          ),
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
        color: RackUpColors.itemGold,
        size: 20,
      ),
    );
  }
}
