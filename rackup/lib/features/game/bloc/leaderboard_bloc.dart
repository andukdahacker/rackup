import 'package:bloc/bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

/// Manages leaderboard state with previous entries for animation diffing.
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  /// Creates a [LeaderboardBloc].
  LeaderboardBloc() : super(const LeaderboardInitial()) {
    on<LeaderboardUpdated>(_onLeaderboardUpdated);
  }

  void _onLeaderboardUpdated(
    LeaderboardUpdated event,
    Emitter<LeaderboardState> emit,
  ) {
    final current = state;
    final List<LeaderboardEntry> previousEntries = switch (current) {
      LeaderboardActive(:final entries) => entries,
      _ => const [],
    };

    final shuffleOccurred = event.entries.any((e) => e.rankChanged);

    emit(LeaderboardActive(
      entries: event.entries,
      previousEntries: previousEntries,
      shooterHash: event.shooterHash,
      streakMilestone: event.streakMilestone,
      cascadeProfile: event.cascadeProfile,
      shuffleOccurred: shuffleOccurred,
    ));
  }
}
