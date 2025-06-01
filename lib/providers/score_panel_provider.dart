import 'package:flutter/foundation.dart';

class ScorePanelProvider extends ChangeNotifier {
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _timerRawTime = 0;
  int _selectedQuarter = 1;

  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;
  int get timerRawTime => _timerRawTime;
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => _timerRawTime > 0 && _timerRawTime < 3599999;

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

  int getCount(bool isHomeTeam, bool isGoal) {
    return isHomeTeam
        ? (isGoal ? _homeGoals : _homeBehinds)
        : (isGoal ? _awayGoals : _awayBehinds);
  }
}
