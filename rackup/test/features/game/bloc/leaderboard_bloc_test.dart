import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

void main() {
  group('LeaderboardBloc', () {
    const entry1 = LeaderboardEntry(
      deviceIdHash: 'hash-a',
      displayName: 'Alice',
      score: 10,
      streak: 2,
      streakLabel: 'warming_up',
      rank: 1,
    );
    const entry2 = LeaderboardEntry(
      deviceIdHash: 'hash-b',
      displayName: 'Bob',
      score: 5,
      streak: 0,
      streakLabel: '',
      rank: 2,
    );
    const entry3 = LeaderboardEntry(
      deviceIdHash: 'hash-a',
      displayName: 'Alice',
      score: 13,
      streak: 3,
      streakLabel: 'on_fire',
      rank: 1,
    );
    const entry4 = LeaderboardEntry(
      deviceIdHash: 'hash-b',
      displayName: 'Bob',
      score: 5,
      streak: 0,
      streakLabel: '',
      rank: 2,
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'initial state is LeaderboardInitial',
      build: LeaderboardBloc.new,
      verify: (bloc) {
        expect(bloc.state, isA<LeaderboardInitial>());
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits LeaderboardActive on first update with empty previous entries',
      build: LeaderboardBloc.new,
      act: (bloc) => bloc.add(
        const LeaderboardUpdated(
          entries: [entry1, entry2],
          shooterHash: 'hash-a',
          streakMilestone: true,
          cascadeProfile: 'streak_milestone',
        ),
      ),
      expect: () => [
        const LeaderboardActive(
          entries: [entry1, entry2],
          previousEntries: [],
          shooterHash: 'hash-a',
          streakMilestone: true,
          cascadeProfile: 'streak_milestone',
        ),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'preserves previous entries for animation diffing',
      build: LeaderboardBloc.new,
      act: (bloc) {
        bloc
          ..add(const LeaderboardUpdated(
            entries: [entry1, entry2],
            shooterHash: 'hash-a',
          ))
          ..add(const LeaderboardUpdated(
            entries: [entry3, entry4],
            shooterHash: 'hash-a',
            streakMilestone: true,
            cascadeProfile: 'streak_milestone',
          ));
      },
      expect: () => [
        const LeaderboardActive(
          entries: [entry1, entry2],
          previousEntries: [],
          shooterHash: 'hash-a',
        ),
        const LeaderboardActive(
          entries: [entry3, entry4],
          previousEntries: [entry1, entry2],
          shooterHash: 'hash-a',
          streakMilestone: true,
          cascadeProfile: 'streak_milestone',
        ),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'handles empty leaderboard update',
      build: LeaderboardBloc.new,
      act: (bloc) =>
          bloc.add(const LeaderboardUpdated(entries: [])),
      expect: () => [
        const LeaderboardActive(
          entries: [],
          previousEntries: [],
        ),
      ],
    );
  });
}
