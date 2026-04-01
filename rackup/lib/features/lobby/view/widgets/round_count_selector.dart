import 'package:flutter/material.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';

/// Allows the host to select the number of rounds (5, 10, or 15).
class RoundCountSelector extends StatelessWidget {
  /// Creates a [RoundCountSelector].
  const RoundCountSelector({
    required this.selectedRoundCount,
    required this.onChanged,
    super.key,
  });

  /// The currently selected round count.
  final int selectedRoundCount;

  /// Called when the selection changes.
  final ValueChanged<int> onChanged;

  static const _options = [5, 10, 15];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _options.map((count) {
        final isSelected = count == selectedRoundCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: isSelected ? '$count rounds selected' : '$count rounds',
            child: Material(
              color: isSelected
                  ? RackUpColors.madeGreen
                  : RackUpColors.tierLobby,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onChanged(count),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 40,
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected
                            ? Colors.white
                            : RackUpColors.textSecondary,
                      ),
                      textScaler: ClampedTextScaler.of(
                        context,
                        TextRole.body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
