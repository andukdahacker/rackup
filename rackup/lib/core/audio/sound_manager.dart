import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// Available game sound effects.
enum GameSound {
  blueShellImpact('blue_shell_impact.mp3'),
  itemDrop('item_drop.mp3'),
  leaderboardShuffle('leaderboard_shuffle.mp3'),
  punishmentReveal('punishment_reveal.mp3'),
  streakFire('streak_fire.mp3'),
  podiumFanfare('podium_fanfare.mp3');

  const GameSound(this.filename);

  /// Asset filename relative to `assets/sounds/`.
  final String filename;
}

/// Low-level audio service that owns [AudioPlayer] instances for game SFX.
///
/// Android SoundPool constraint: `PlayerMode.lowLatency` uses SoundPool under
/// the hood which has a 1MB per-file size limit. Keep all sound assets <100KB.
/// Current <2s MP3s at 32kbps are ~2-8KB each, well within bounds.
class SoundManager {
  /// Creates a [SoundManager].
  ///
  /// For testing, pass a custom [playerFactory] to inject mock players and
  /// set [skipGlobalConfig] to true to avoid platform channel calls.
  SoundManager({
    AudioPlayer Function()? playerFactory,
    this.skipGlobalConfig = false,
  }) : _playerFactory = playerFactory ?? AudioPlayer.new;

  final AudioPlayer Function() _playerFactory;

  /// When true, skips `AudioPlayer.global.setAudioContext()` (for tests).
  final bool skipGlobalConfig;
  final Map<GameSound, AudioPlayer> _players = {};
  final Completer<void> _initCompleter = Completer<void>();
  bool _disposed = false;

  /// Initializes audio players and preloads all sound assets.
  Future<void> init() async {
    try {
      if (!skipGlobalConfig) {
        final audioContext = AudioContext(
          android: const AudioContextAndroid(),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
        );
        await AudioPlayer.global.setAudioContext(audioContext);
      }

      for (final sound in GameSound.values) {
        if (_disposed) break;
        try {
          final player = _playerFactory();
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setSource(AssetSource('sounds/${sound.filename}'));
          _players[sound] = player;
        } on Exception catch (e) {
          log(
            'Failed to init ${sound.name}: $e',
            name: 'SoundManager',
          );
        }
      }
    } on Exception catch (e) {
      log('SoundManager.init() failed: $e', name: 'SoundManager');
    } finally {
      _initCompleter.complete();
    }
  }

  /// Plays the given [sound] effect.
  ///
  /// Waits for [init] to complete before attempting playback. Returns
  /// immediately if disposed. Uses `seek(Duration.zero)` + `resume()` to
  /// replay. Do NOT use `stop()` + `play()` — known audioplayers bug #1489
  /// where lowLatency + ReleaseMode.stop causes sound to play only once on
  /// Android.
  Future<void> play(GameSound sound) async {
    await _initCompleter.future;
    if (_disposed) return;
    final player = _players[sound];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } on Exception catch (e) {
      log('SoundManager.play(${sound.name}) failed: $e', name: 'SoundManager');
    }
  }

  /// Disposes all audio players and releases resources.
  Future<void> dispose() async {
    _disposed = true;
    await _initCompleter.future;
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
