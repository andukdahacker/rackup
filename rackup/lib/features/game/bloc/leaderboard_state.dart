import 'package:equatable/equatable.dart';
import 'package:rackup/features/game/bloc/game_event.dart';

/// States for the LeaderboardBloc.
sealed class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

/// Waiting for first leaderboard data.
class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

/// Leaderboard is active with current and previous entries for animation diffing.
class LeaderboardActive extends LeaderboardState {
  const LeaderboardActive({
    required this.entries,
    required this.previousEntries,
    this.shooterHash = '',
    this.streakMilestone = false,
    this.cascadeProfile = 'routine',
    this.shuffleOccurred = false,
  });

  /// Current sorted leaderboard entries.
  final List<LeaderboardEntry> entries;

  /// Previous entries for animation diffing (empty on first update).
  final List<LeaderboardEntry> previousEntries;

  /// The shooter whose turn just completed.
  final String shooterHash;

  /// True when streak threshold was just crossed.
  final bool streakMilestone;

  /// Cascade timing profile.
  final String cascadeProfile;

  /// True when any entry has rankChanged — consumed by AudioListener (Story 3.6).
  final bool shuffleOccurred;

  @override
  List<Object?> get props => [
        entries,
        previousEntries,
        shooterHash,
        streakMilestone,
        cascadeProfile,
        shuffleOccurred,
      ];
}
