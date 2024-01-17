import 'package:flutter/material.dart';

class ScorePanelState extends ChangeNotifier {
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;

  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;

  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;

  void setCount(bool isHomeTeam, bool isGoal, int count) {
    if (isHomeTeam) {
      if (isGoal) {
        _homeGoals = count;
      } else {
        _homeBehinds = count;
      }
    } else {
      if (isGoal) {
        _awayGoals = count;
      } else {
        _awayBehinds = count;
      }
    }
    notifyListeners();
  }

  int getCount(bool isHomeTeam, bool isGoal) {
    if (isHomeTeam) {
      if (isGoal) {
        return _homeGoals;
      } else {
        return _homeBehinds;
      }
    } else {
      if (isGoal) {
        return _awayGoals;
      } else {
        return _awayBehinds;
      }
    }
  }
}
