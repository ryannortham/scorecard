// background timer management for game clock

import 'dart:async';

/// manages background timer state and stream updates
class TimerManager {
  Timer? _backgroundTimer;
  DateTime? _timerStartTime;
  int _timeWhenStarted = 0;
  bool isCountdownTimer = true;
  int _timerRawTime = 0;

  final StreamController<int> _timerStreamController =
      StreamController<int>.broadcast();

  Stream<int> get timerStream => _timerStreamController.stream;
  int get timerRawTime => _timerRawTime;

  void setTimerRawTime(int newTime) {
    _timerRawTime = newTime;
    _timerStreamController.add(_timerRawTime);
  }

  void start() {
    _timerStartTime = DateTime.now();
    _timeWhenStarted = _timerRawTime;

    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _tick();
    });
  }

  void stop() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _timerStartTime = null;
  }

  void reset(int quarterMSec) {
    stop();
    _timerRawTime = isCountdownTimer ? quarterMSec : 0;
    _timerStreamController.add(_timerRawTime);
  }

  void _tick() {
    if (_timerStartTime == null) return;

    final elapsed = DateTime.now().difference(_timerStartTime!).inMilliseconds;

    if (isCountdownTimer) {
      _timerRawTime = _timeWhenStarted - elapsed;
    } else {
      _timerRawTime = _timeWhenStarted + elapsed;
    }

    _timerStreamController.add(_timerRawTime);
  }

  /// elapsed time in milliseconds for current quarter
  int getElapsedTimeInQuarter(int quarterMSec) {
    if (isCountdownTimer) {
      return quarterMSec - _timerRawTime;
    } else {
      return _timerRawTime;
    }
  }

  /// remaining time in milliseconds (negative when in overtime)
  int getRemainingTimeInQuarter(int quarterMSec) {
    final elapsedMSec = getElapsedTimeInQuarter(quarterMSec);
    return quarterMSec - elapsedMSec;
  }

  void dispose() {
    _backgroundTimer?.cancel();
    unawaited(_timerStreamController.close());
  }
}
