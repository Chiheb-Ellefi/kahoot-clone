import 'package:audioplayers/audioplayers.dart';

/// Asset-based SFX service for game feedback.
class AudioFeedbackService {
  AudioFeedbackService._();
  static final AudioFeedbackService instance = AudioFeedbackService._();
  AudioPlayer? _timerTickPlayer;
  DateTime? _lastTimerTickAt;

  Future<void> _playAsset(
    String fileName, {
    double volume = 0.7,
  }) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(volume);
    await player.play(AssetSource('sounds/$fileName'));
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });
  }

  Future<void> playTimerTick() async {
    // Reuse one player for reliable short SFX playback on web.
    final now = DateTime.now();
    if (_lastTimerTickAt != null &&
        now.difference(_lastTimerTickAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastTimerTickAt = now;
    _timerTickPlayer ??= AudioPlayer();
    try {
      await _timerTickPlayer!.setReleaseMode(ReleaseMode.stop);
      await _timerTickPlayer!.setVolume(0.45);
      await _timerTickPlayer!.stop();
      await _timerTickPlayer!.play(AssetSource('sounds/timer_tick.mp3'));
    } catch (_) {
      // Keep game flow resilient even if browser blocks playback.
    }
  }

  Future<void> playOvertake() => _playAsset('leaderboard.mp3', volume: 0.4);

  Future<void> playWin() => _playAsset('win.mp3', volume: 0.8);

  Future<void> playLose() => _playAsset('lose.mp3', volume: 0.75);

  Future<void> playCorrectAnswer() =>
      _playAsset('correct_answer.mp3', volume: 0.7);

  Future<void> playWrongAnswer() => _playAsset('wrong_answer.mp3', volume: 0.7);

  Future<void> playLeaderboardOpen() =>
      _playAsset('leaderboard.mp3', volume: 0.55);
}
