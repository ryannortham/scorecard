import 'package:flutter/foundation.dart';

import 'package:scorecard/services/game_state_service.dart';

/// Bridge between UI and GameStateService for game configuration
class GameSetupAdapter extends ChangeNotifier {
  final GameStateService _gameState = GameStateService.instance;

  GameSetupAdapter() {
    // Listen to game state changes and propagate them
    _gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    notifyListeners();
  }

  // Forward properties to GameStateService
  DateTime get gameDate => _gameState.gameDate;
  String get homeTeam => _gameState.homeTeam;
  String get awayTeam => _gameState.awayTeam;
  int get quarterMinutes => _gameState.quarterMinutes;
  int get quarterMSec => _gameState.quarterMSec;
  bool get isCountdownTimer => _gameState.isCountdownTimer;

  // Simplified setters that update individual properties
  void setGameDate(DateTime date) => _updateConfig(gameDate: date);
  void setHomeTeam(String team) => _updateConfig(homeTeam: team);
  void setAwayTeam(String team) => _updateConfig(awayTeam: team);
  void setQuarterMinutes(int minutes) => _updateConfig(quarterMinutes: minutes);
  void setIsCountdownTimer(bool isCountdown) =>
      _updateConfig(isCountdownTimer: isCountdown);

  // Helper method to reduce repetitive code
  void _updateConfig({
    String? homeTeam,
    String? awayTeam,
    DateTime? gameDate,
    int? quarterMinutes,
    bool? isCountdownTimer,
  }) {
    _gameState.configureGame(
      homeTeam: homeTeam ?? _gameState.homeTeam,
      awayTeam: awayTeam ?? _gameState.awayTeam,
      gameDate: gameDate ?? _gameState.gameDate,
      quarterMinutes: quarterMinutes ?? _gameState.quarterMinutes,
      isCountdownTimer: isCountdownTimer ?? _gameState.isCountdownTimer,
    );
  }

  void initializeWithDefaults({
    int? defaultQuarterMinutes,
    bool? defaultIsCountdownTimer,
  }) {
    _updateConfig(
      quarterMinutes: defaultQuarterMinutes ?? 15,
      isCountdownTimer: defaultIsCountdownTimer ?? true,
    );
  }

  void reset({
    int? defaultQuarterMinutes,
    bool? defaultIsCountdownTimer,
    String? favoriteTeam,
  }) {
    _gameState.configureGame(
      homeTeam: favoriteTeam ?? '',
      awayTeam: '',
      gameDate: DateTime.now(),
      quarterMinutes: defaultQuarterMinutes ?? 15,
      isCountdownTimer: defaultIsCountdownTimer ?? true,
    );
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }
}
