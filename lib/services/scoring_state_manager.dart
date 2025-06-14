import 'package:flutter/foundation.dart';
import '../services/game_state_service.dart';
import '../providers/game_record.dart';

/// Scoring state manager that provides a widget-independent interface
/// This replaces the need for widgets to use findAncestorStateOfType
class ScoringStateManager {
  static ScoringStateManager? _instance;
  static ScoringStateManager get instance =>
      _instance ??= ScoringStateManager._();

  ScoringStateManager._();

  final GameStateService _gameState = GameStateService.instance;

  // Public interface for accessing game events
  List<GameEvent> get gameEvents => _gameState.gameEvents;

  // Public interface for updating scores with automatic event recording
  void updateScore(bool isHomeTeam, bool isGoal, int newCount) {
    _gameState.updateScore(isHomeTeam, isGoal, newCount);
  }

  // Public interface for recording quarter end events
  void recordQuarterEnd(int quarter) {
    _gameState.recordQuarterEnd(quarter);
  }

  // Public interface for game state updates
  void updateGameAfterEventChange() {
    // The GameStateService handles automatic saving, so this is just for compatibility
    // with existing code that expects this method to exist
  }

  // Force final save - used when game is complete to ensure data is saved before reset
  Future<void> forceFinalSave() async {
    await _gameState.forceFinalSave();
  }

  // Start a new game
  Future<void> startNewGame() async {
    await _gameState.startNewGame();
  }

  // Check if game is complete
  bool isGameComplete() {
    return _gameState.isGameComplete();
  }

  // Reset game state
  void resetGame() {
    _gameState.resetGame();
  }

  // Get current game ID
  String? get currentGameId => _gameState.currentGameId;

  // Add listeners for state changes
  void addGameEventListener(VoidCallback listener) {
    _gameState.addGameEventListener(listener);
  }

  void removeGameEventListener(VoidCallback listener) {
    _gameState.removeGameEventListener(listener);
  }

  void addTimerStateListener(VoidCallback listener) {
    _gameState.addTimerStateListener(listener);
  }

  void removeTimerStateListener(VoidCallback listener) {
    _gameState.removeTimerStateListener(listener);
  }

  void addScoreChangeListener(VoidCallback listener) {
    _gameState.addScoreChangeListener(listener);
  }

  void removeScoreChangeListener(VoidCallback listener) {
    _gameState.removeScoreChangeListener(listener);
  }
}
