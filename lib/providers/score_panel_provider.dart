import 'package:flutter/foundation.dart';

class ScorePanelProvider extends ChangeNotifier {
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _timerRawTime = 0;
  int _selectedQuarter = 1;

  // Maps to store goals and behinds per quarter
  final Map<int, int> _homeGoalsPerQuarter = {};
  final Map<int, int> _homeBehindsPerQuarter = {};
  final Map<int, int> _awayGoalsPerQuarter = {};
  final Map<int, int> _awayBehindsPerQuarter = {};

  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;
  int get timerRawTime => _timerRawTime;
  int get selectedQuarter => _selectedQuarter;

  void setCount(bool isHomeTeam, bool isGoal, int count) {
    if (isGoal) {
      isHomeTeam ? _homeGoals = count : _awayGoals = count;
      _updateQuarterScore(isHomeTeam, isGoal, count);
    } else {
      isHomeTeam ? _homeBehinds = count : _awayBehinds = count;
      _updateQuarterScore(isHomeTeam, isGoal, count);
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
    return isHomeTeam ? (isGoal ? _homeGoals : _homeBehinds) : (isGoal ? _awayGoals : _awayBehinds);
  }

  void _updateQuarterScore(bool isHomeTeam, bool isGoal, int count) {
    if (isHomeTeam) {
      if (isGoal) {
        _homeGoalsPerQuarter[_selectedQuarter] = count;
      } else {
        _homeBehindsPerQuarter[_selectedQuarter] = count;
      }
    } else {
      if (isGoal) {
        _awayGoalsPerQuarter[_selectedQuarter] = count;
      } else {
        _awayBehindsPerQuarter[_selectedQuarter] = count;
      }
    }
  }

  int getQuarterCount(bool isHomeTeam, bool isGoal, int quarter) {
    if (isHomeTeam) {
      return isGoal ? (_homeGoalsPerQuarter[quarter] ?? 0) : (_homeBehindsPerQuarter[quarter] ?? 0);
    } else {
      return isGoal ? (_awayGoalsPerQuarter[quarter] ?? 0) : (_awayBehindsPerQuarter[quarter] ?? 0);
    }
  }

  List<String> generateQuarterList(bool isHomeTeam, int quarter) {
    int goals = getQuarterCount(isHomeTeam, true, quarter);
    int behinds = getQuarterCount(isHomeTeam, false, quarter);
    int points = goals * 6 + behinds;

    return [
      _getOrdinal(quarter),
      goals.toString(),
      "0",
      behinds.toString(),
      "0",
      points.toString(),
      "0",
    ];
  }

// Helper function to get the ordinal representation of a number
  String _getOrdinal(int number) {
    if (number == 1) {
      return '1st';
    } else if (number == 2) {
      return '2nd';
    } else if (number == 3) {
      return '3rd';
    } else {
      return '${number}th';
    }
  }
}
