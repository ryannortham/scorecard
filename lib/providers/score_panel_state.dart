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

  void setHomeGoals(int value) {
    _homeGoals = value;
    notifyListeners();
  }

  void setHomeBehinds(int value) {
    _homeBehinds = value;
    notifyListeners();
  }

  void setAwayGoals(int value) {
    _awayGoals = value;
    notifyListeners();
  }

  void setAwayBehinds(int value) {
    _awayBehinds = value;
    notifyListeners();
  }
}
