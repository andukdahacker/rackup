import 'package:equatable/equatable.dart';
import 'package:rackup/features/game/bloc/game_event.dart';

/// Events for the LeaderboardBloc.
sealed class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

/// Leaderboard was updated — server broadcast (past tense).
class LeaderboardUpdated extends LeaderboardEvent {
  const LeaderboardUpdated({
    required this.entries,
    this.shooterHash = '',
    this.streakMilestone = false,
    this.cascadeProfile = 'routine',
  });

  /// Sorted leaderboard entries from server.
  final List<LeaderboardEntry> entries;

  /// The shooter whose turn just completed.
  final String shooterHash;

  /// True when streak threshold was just crossed.
  final bool streakMilestone;

  /// Cascade timing profile.
  final String cascadeProfile;

  @override
  List<Object?> get props =>
      [entries, shooterHash, streakMilestone, cascadeProfile];
}
