import 'package:flutter/foundation.dart';
import 'dart:async';

class ScorePanelProvider extends ChangeNotifier {
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _timerRawTime = 0;
  int _selectedQuarter = 1;
  bool _isTimerRunning = false;

  // Background timer management
  Timer? _backgroundTimer;
  bool _isCountdownMode = false;
  DateTime? _timerStartTime;
  int _timeWhenStarted = 0;

  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;
  int get timerRawTime => _timerRawTime;
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => _isTimerRunning;

  void setCount(bool isHomeTeam, bool isGoal, int count) {
    if (isGoal) {
      isHomeTeam ? _homeGoals = count : _awayGoals = count;
    } else {
      isHomeTeam ? _homeBehinds = count : _awayBehinds = count;
    }
    notifyListeners();
  }

  void setTimerRawTime(int newTime) {
    _timerRawTime = newTime;
    notifyListeners();
  }

  void setSelectedQuarter(int newQuarter) {
    _selectedQuarter = newQuarter;
    notifyListeners();
  }

  void setTimerRunning(bool isRunning) {
    _isTimerRunning = isRunning;

    if (isRunning) {
      _startBackgroundTimer();
    } else {
      _stopBackgroundTimer();
    }

    notifyListeners();
  }

  void configureTimer(
      {required bool isCountdownMode, required int quarterMaxTime}) {
    _isCountdownMode = isCountdownMode;
  }

  void _startBackgroundTimer() {
    // Record when we started and what time we started from
    _timerStartTime = DateTime.now();
    _timeWhenStarted = _timerRawTime;

    // Cancel any existing timer
    _backgroundTimer?.cancel();

    // Start a new timer that updates every 100ms
    _backgroundTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_timerStartTime != null) {
        final elapsed =
            DateTime.now().difference(_timerStartTime!).inMilliseconds;

        if (_isCountdownMode) {
          // For countdown mode, subtract elapsed time
          _timerRawTime = _timeWhenStarted - elapsed;
        } else {
          // For count-up mode, add elapsed time
          _timerRawTime = _timeWhenStarted + elapsed;
        }

        notifyListeners();
      }
    });
  }

  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _timerStartTime = null;
  }

  int getCount(bool isHomeTeam, bool isGoal) {
    return isHomeTeam
        ? (isGoal ? _homeGoals : _homeBehinds)
        : (isGoal ? _awayGoals : _awayBehinds);
  }

  void resetGame() {
    _homeGoals = 0;
    _homeBehinds = 0;
    _awayGoals = 0;
    _awayBehinds = 0;
    _timerRawTime = 0;
    _selectedQuarter = 1;
    _isTimerRunning = false;
    _stopBackgroundTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopBackgroundTimer();
    super.dispose();
  }
}
