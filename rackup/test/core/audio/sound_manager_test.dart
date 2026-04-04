import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/audio/sound_manager.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  group('SoundManager', () {
    late Map<int, MockAudioPlayer> mockPlayers;
    late SoundManager soundManager;

    setUp(() {
      mockPlayers = {};
      var index = 0;
      soundManager = SoundManager(
        skipGlobalConfig: true,
        playerFactory: () {
          final player = MockAudioPlayer();
          when(() => player.setPlayerMode(any()))
              .thenAnswer((_) async {});
          when(() => player.setSource(any()))
              .thenAnswer((_) async {});
          when(() => player.seek(any()))
              .thenAnswer((_) async {});
          when(() => player.resume()).thenAnswer((_) async {});
          when(() => player.dispose()).thenAnswer((_) async {});
          mockPlayers[index] = player;
          index++;
          return player;
        },
      );
    });

    setUpAll(() {
      registerFallbackValue(PlayerMode.lowLatency);
      registerFallbackValue(AssetSource(''));
      registerFallbackValue(Duration.zero);
    });

    test('init creates players with lowLatency mode and preloads assets',
        () async {
      await soundManager.init();

      expect(mockPlayers, hasLength(GameSound.values.length));
      for (final player in mockPlayers.values) {
        verify(() => player.setPlayerMode(PlayerMode.lowLatency)).called(1);
        verify(() => player.setSource(any())).called(1);
      }
    });

    test('play triggers seek and resume on correct player', () async {
      await soundManager.init();

      await soundManager.play(GameSound.streakFire);

      // Look up by enum index to avoid hard-coded positional assumption.
      final streakPlayer = mockPlayers[GameSound.streakFire.index]!;
      verify(() => streakPlayer.seek(Duration.zero)).called(1);
      verify(() => streakPlayer.resume()).called(1);
    });

    test('play waits for init and works correctly', () async {
      // Start init but also immediately play — play should wait for init.
      final initFuture = soundManager.init();
      final playFuture = soundManager.play(GameSound.streakFire);
      await initFuture;
      await playFuture;

      final streakPlayer = mockPlayers[GameSound.streakFire.index]!;
      verify(() => streakPlayer.seek(Duration.zero)).called(1);
      verify(() => streakPlayer.resume()).called(1);
    });

    test('play does nothing after dispose', () async {
      await soundManager.init();
      await soundManager.dispose();

      await soundManager.play(GameSound.streakFire);
      // No exception thrown, no interactions after dispose
    });

    test('dispose cleans up all players', () async {
      await soundManager.init();

      await soundManager.dispose();

      for (final player in mockPlayers.values) {
        verify(() => player.dispose()).called(1);
      }
    });

    test('init handles per-sound failure gracefully', () async {
      // Reconfigure with a factory that fails on the 3rd sound
      var idx = 0;
      final manager = SoundManager(
        skipGlobalConfig: true,
        playerFactory: () {
          final player = MockAudioPlayer();
          when(() => player.setPlayerMode(any()))
              .thenAnswer((_) async {});
          when(() => player.dispose()).thenAnswer((_) async {});
          if (idx == 2) {
            when(() => player.setSource(any()))
                .thenThrow(Exception('asset missing'));
          } else {
            when(() => player.setSource(any()))
                .thenAnswer((_) async {});
          }
          when(() => player.seek(any())).thenAnswer((_) async {});
          when(() => player.resume()).thenAnswer((_) async {});
          idx++;
          return player;
        },
      );

      // Should not throw — failed sound is skipped
      await manager.init();
      await manager.dispose();
    });

    test('each GameSound maps to correct asset filename', () {
      expect(GameSound.blueShellImpact.filename, 'blue_shell_impact.mp3');
      expect(
        GameSound.leaderboardShuffle.filename,
        'leaderboard_shuffle.mp3',
      );
      expect(GameSound.punishmentReveal.filename, 'punishment_reveal.mp3');
      expect(GameSound.streakFire.filename, 'streak_fire.mp3');
      expect(GameSound.podiumFanfare.filename, 'podium_fanfare.mp3');
    });
  });
}
