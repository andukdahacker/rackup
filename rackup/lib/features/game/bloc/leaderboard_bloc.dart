import 'package:bloc/bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

/// Manages leaderboard state with previous entries for animation diffing.
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  /// Creates a [LeaderboardBloc].
  LeaderboardBloc() : super(const LeaderboardInitial()) {
    on<LeaderboardUpdated>(_onLeaderboardUpdated);
    on<LeaderboardRefreshed>(_onLeaderboardRefreshed);
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

  /// Pure data refresh: replace entries without triggering shooter highlight,
  /// streak milestone, shuffle animations, or cascade timing changes. Used
  /// by item deployment / fizzle which need current rankings but should not
  /// re-fire turn-completion side effects.
  void _onLeaderboardRefreshed(
    LeaderboardRefreshed event,
    Emitter<LeaderboardState> emit,
  ) {
    final current = state;
    final List<LeaderboardEntry> previousEntries = switch (current) {
      LeaderboardActive(:final entries) => entries,
      _ => const [],
    };

    emit(LeaderboardActive(
      entries: event.entries,
      previousEntries: previousEntries,
      shooterHash: '',
      streakMilestone: false,
      cascadeProfile: 'routine',
      shuffleOccurred: false,
    ));
  }
}
