import 'package:flutter/foundation.dart';
import '../services/game_state_service.dart';

/// Bridge between UI and GameStateService for active games
class ScorePanelAdapter extends ChangeNotifier {
  final GameStateService _gameState = GameStateService.instance;

  ScorePanelAdapter() {
    // Listen to game state changes and propagate them
    _gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    notifyListeners();
  }

  // Forward properties to GameStateService
  int get homeGoals => _gameState.homeGoals;
  int get homeBehinds => _gameState.homeBehinds;
  int get awayGoals => _gameState.awayGoals;
  int get awayBehinds => _gameState.awayBehinds;
  int get homePoints => _gameState.homePoints;
  int get awayPoints => _gameState.awayPoints;
  int get timerRawTime => _gameState.timerRawTime;
  int get selectedQuarter => _gameState.selectedQuarter;
  bool get isTimerRunning => _gameState.isTimerRunning;

  // Forward methods to GameStateService
  void setCount(bool isHomeTeam, bool isGoal, int count) =>
      _gameState.setScore(isHomeTeam, isGoal, count);

  void setTimerRawTime(int newTime) => _gameState.setTimerRawTime(newTime);

  void setSelectedQuarter(int newQuarter) =>
      _gameState.setSelectedQuarter(newQuarter);

  void setTimerRunning(bool isRunning) => _gameState.setTimerRunning(isRunning);

  void configureTimer({
    required bool isCountdownMode,
    required int quarterMaxTime,
  }) => _gameState.configureTimer(
    isCountdownMode: isCountdownMode,
    quarterMaxTime: quarterMaxTime,
  );

  int getCount(bool isHomeTeam, bool isGoal) =>
      _gameState.getScore(isHomeTeam, isGoal);

  /// Check if there are scoring events for a specific team and score type in the current quarter
  bool hasEventInCurrentQuarter(bool isHomeTeam, bool isGoal) =>
      _gameState.hasEventInCurrentQuarter(isHomeTeam, isGoal);

  void resetGame() => _gameState.resetGame();

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }
}
