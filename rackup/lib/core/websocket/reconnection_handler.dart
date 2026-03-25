import 'dart:async';
import 'dart:math';

/// Handles WebSocket reconnection with exponential backoff.
///
/// Backoff schedule: 1s, 2s, 4s, 8s, max 16s.
/// Total reconnection window: 60 seconds.
class ReconnectionHandler {
  /// Creates a [ReconnectionHandler].
  ReconnectionHandler();

  static const int _maxBackoffSeconds = 16;
  static const int _maxTotalSeconds = 60;

  int _attempt = 0;
  DateTime? _firstAttemptTime;
  Timer? _timer;

  /// The current attempt number.
  int get attempt => _attempt;

  /// Total seconds elapsed since first reconnection attempt.
  int get elapsedSeconds {
    if (_firstAttemptTime == null) return 0;
    return DateTime.now().difference(_firstAttemptTime!).inSeconds;
  }

  /// Whether the reconnection window has been exhausted.
  bool get isExhausted => elapsedSeconds >= _maxTotalSeconds;

  /// Schedules the next reconnection attempt.
  ///
  /// Calls [onReconnect] after the backoff delay.
  /// Returns `false` if the 60-second window is exhausted.
  bool scheduleReconnect(void Function() onReconnect) {
    if (isExhausted) return false;

    _firstAttemptTime ??= DateTime.now();
    _attempt++;

    final backoffSeconds = min(
      pow(2, _attempt - 1).toInt(),
      _maxBackoffSeconds,
    );

    // Check if the backoff would exceed the remaining window.
    final remainingSeconds = _maxTotalSeconds - elapsedSeconds;
    if (backoffSeconds > remainingSeconds && remainingSeconds <= 0) {
      return false;
    }

    _timer?.cancel();
    _timer = Timer(Duration(seconds: backoffSeconds), () {
      if (!isExhausted) {
        onReconnect();
      }
    });

    return true;
  }

  /// Resets the reconnection state (e.g., after successful reconnection).
  void reset() {
    _attempt = 0;
    _firstAttemptTime = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels any pending reconnection timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
