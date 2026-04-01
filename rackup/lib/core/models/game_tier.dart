import 'package:rackup/core/theme/game_theme.dart';

/// Computes the [EscalationTier] for the given round and total rounds.
///
/// Progression percentage is `(currentRound - 1) / totalRounds * 100`.
/// Delegates to [RackUpGameTheme.tierForProgression] for tier determination.
EscalationTier computeTier(int currentRound, int totalRounds) {
  if (totalRounds <= 0) return EscalationTier.mild;
  final percentage = (currentRound - 1) / totalRounds * 100;
  return RackUpGameTheme.tierForProgression(percentage);
}
