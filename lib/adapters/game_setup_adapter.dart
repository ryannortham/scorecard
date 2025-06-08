import 'package:flutter/foundation.dart';
import '../services/game_state_service.dart';

/// Adapter that provides GameSetupProvider-like interface using GameStateService
/// This allows existing widgets to work with the new decoupled state system
class GameSetupAdapter extends ChangeNotifier {
  final GameStateService _gameState = GameStateService.instance;

  GameSetupAdapter() {
    // Listen to game state changes and propagate them
    _gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    notifyListeners();
  }

  // Mirror the GameSetupProvider interface
  DateTime get gameDate => _gameState.gameDate;
  String get homeTeam => _gameState.homeTeam;
  String get awayTeam => _gameState.awayTeam;
  int get quarterMinutes => _gameState.quarterMinutes;
  int get quarterMSec => _gameState.quarterMSec;
  bool get isCountdownTimer => _gameState.isCountdownTimer;

  void setGameDate(DateTime date) {
    _gameState.configureGame(
      homeTeam: _gameState.homeTeam,
      awayTeam: _gameState.awayTeam,
      gameDate: date,
      quarterMinutes: _gameState.quarterMinutes,
      isCountdownTimer: _gameState.isCountdownTimer,
    );
  }

  void setHomeTeam(String team) {
    _gameState.configureGame(
      homeTeam: team,
      awayTeam: _gameState.awayTeam,
      gameDate: _gameState.gameDate,
      quarterMinutes: _gameState.quarterMinutes,
      isCountdownTimer: _gameState.isCountdownTimer,
    );
  }

  void setAwayTeam(String team) {
    _gameState.configureGame(
      homeTeam: _gameState.homeTeam,
      awayTeam: team,
      gameDate: _gameState.gameDate,
      quarterMinutes: _gameState.quarterMinutes,
      isCountdownTimer: _gameState.isCountdownTimer,
    );
  }

  void setQuarterMinutes(int minutes) {
    _gameState.configureGame(
      homeTeam: _gameState.homeTeam,
      awayTeam: _gameState.awayTeam,
      gameDate: _gameState.gameDate,
      quarterMinutes: minutes,
      isCountdownTimer: _gameState.isCountdownTimer,
    );
  }

  void setIsCountdownTimer(bool isCountdown) {
    _gameState.configureGame(
      homeTeam: _gameState.homeTeam,
      awayTeam: _gameState.awayTeam,
      gameDate: _gameState.gameDate,
      quarterMinutes: _gameState.quarterMinutes,
      isCountdownTimer: isCountdown,
    );
  }

  void initializeWithDefaults(
      {int? defaultQuarterMinutes, bool? defaultIsCountdownTimer}) {
    _gameState.configureGame(
      homeTeam: _gameState.homeTeam,
      awayTeam: _gameState.awayTeam,
      gameDate: _gameState.gameDate,
      quarterMinutes: defaultQuarterMinutes ?? 15,
      isCountdownTimer: defaultIsCountdownTimer ?? true,
    );
  }

  void reset(
      {int? defaultQuarterMinutes,
      bool? defaultIsCountdownTimer,
      String? favoriteTeam}) {
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
