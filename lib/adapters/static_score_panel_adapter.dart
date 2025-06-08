import 'package:flutter/foundation.dart';

/// A static version of ScorePanelAdapter that doesn't listen to GameStateService
/// Used for game details view to avoid setState() during build issues
class StaticScorePanelAdapter extends ChangeNotifier {
  final int _selectedQuarter;

  StaticScorePanelAdapter({required int selectedQuarter})
      : _selectedQuarter = selectedQuarter;

  // Static values that don't change
  int get homeGoals => 0;
  int get homeBehinds => 0;
  int get awayGoals => 0;
  int get awayBehinds => 0;
  int get homePoints => 0;
  int get awayPoints => 0;
  int get timerRawTime => 0;
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => false;

  // No-op methods since this is for read-only contexts
  void setCount(bool isHomeTeam, bool isGoal, int count) {}
  void setTimerRawTime(int newTime) {}
  void setSelectedQuarter(int newQuarter) {}
  void setTimerRunning(bool isRunning) {}
  void configureTimer(
      {required bool isCountdownMode, required int quarterMaxTime}) {}
  int getCount(bool isHomeTeam, bool isGoal) => 0;
}
