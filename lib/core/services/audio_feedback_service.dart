import 'package:audioplayers/audioplayers.dart';

/// Asset-based SFX service for game feedback.
class AudioFeedbackService {
  AudioFeedbackService._();
  static final AudioFeedbackService instance = AudioFeedbackService._();
  AudioPlayer? _timerTickPlayer;
  DateTime? _lastTimerTickAt;
  bool _pendingLeaderboardSound = false;

  Future<void> _playAsset(
    String fileName, {
    double volume = 0.7,
  }) async {
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$fileName'));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {
      // Keep gameplay resilient even if Linux audio backend fails
      // to decode/load an asset at runtime.
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> startTimerSound() async {
    _timerTickPlayer ??= AudioPlayer();
    try {
      await _timerTickPlayer!.setReleaseMode(ReleaseMode.loop);
      await _timerTickPlayer!.setVolume(0.45);
      await _timerTickPlayer!.play(AssetSource('sounds/timer_tick.mp3'));
    } catch (_) {
      // Keep game flow resilient even if browser blocks playback.
    }
  }

  Future<void> stopTimerSound() async {
    try {
      await _timerTickPlayer?.stop();
    } catch (_) {}
  }

  Future<void> playOvertake() => _playAsset('leaderboard.mp3', volume: 0.4);

  Future<void> playWin() => _playAsset('win.mp3', volume: 0.8);

  Future<void> playLose() => _playAsset('lose.mp3', volume: 0.75);

  Future<void> playCorrectAnswer() =>
      _playAsset('correct_answer.mp3', volume: 0.7);

  Future<void> playWrongAnswer() => _playAsset('wrong_answer.mp3', volume: 0.7);

  Future<void> playLeaderboardOpen() =>
      _playAsset('leaderboard.mp3', volume: 0.55);

  void scheduleLeaderboardSound() {
    _pendingLeaderboardSound = true;
  }

  Future<void> consumeLeaderboardSoundIfPending() async {
    if (!_pendingLeaderboardSound) return;
    _pendingLeaderboardSound = false;
    await playLeaderboardOpen();
  }
}
