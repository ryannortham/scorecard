import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/game_history_service.dart';

class GameStateService extends ChangeNotifier {
  static GameStateService? _instance;
  static GameStateService get instance => _instance ??= GameStateService._();

  GameStateService._();

  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _timerRawTime = 0;
  int _selectedQuarter = 1;
  bool _isTimerRunning = false;
  final List<GameEvent> _gameEvents = [];

  String _homeTeam = '';
  String _awayTeam = '';
  DateTime _gameDate = DateTime.now();
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  Timer? _backgroundTimer;
  DateTime? _timerStartTime;
  int _timeWhenStarted = 0;

  final StreamController<int> _timerStreamController =
      StreamController<int>.broadcast();

  String? _currentGameId;
  final List<VoidCallback> _gameEventListeners = [];
  final List<VoidCallback> _timerStateListeners = [];
  final List<VoidCallback> _scoreChangeListeners = [];

  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;

  int get timerRawTime => _timerRawTime;
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => _isTimerRunning;
  Stream<int> get timerStream => _timerStreamController.stream;

  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;
  DateTime get gameDate => _gameDate;
  int get quarterMinutes => _quarterMinutes;
  int get quarterMSec => _quarterMinutes * 60 * 1000;
  bool get isCountdownTimer => _isCountdownTimer;

  List<GameEvent> get gameEvents => List.unmodifiable(_gameEvents);
  String? get currentGameId => _currentGameId;

  bool get hasActiveGame =>
      _currentGameId != null &&
      (_homeTeam.isNotEmpty ||
          _awayTeam.isNotEmpty ||
          _gameEvents.isNotEmpty ||
          _homeGoals > 0 ||
          _homeBehinds > 0 ||
          _awayGoals > 0 ||
          _awayBehinds > 0);

  void setScore(bool isHomeTeam, bool isGoal, int count) {
    if (isGoal) {
      isHomeTeam ? _homeGoals = count : _awayGoals = count;
    } else {
      isHomeTeam ? _homeBehinds = count : _awayBehinds = count;
    }
    _notifyScoreChangeListeners();
    _saveGameAsync();
    notifyListeners();
  }

  int getScore(bool isHomeTeam, bool isGoal) {
    return isHomeTeam
        ? (isGoal ? _homeGoals : _homeBehinds)
        : (isGoal ? _awayGoals : _awayBehinds);
  }

  void setTimerRawTime(int newTime) {
    _timerRawTime = newTime;
    _timerStreamController.add(_timerRawTime);
    notifyListeners();
  }

  void setSelectedQuarter(int newQuarter) {
    _selectedQuarter = newQuarter;
    notifyListeners();
  }

  void setTimerRunning(bool isRunning) {
    final wasRunning = _isTimerRunning;
    _isTimerRunning = isRunning;

    if (isRunning && !wasRunning) {
      _startBackgroundTimer();
      _recordClockEvent('clock_start');
    } else if (!isRunning && wasRunning) {
      _stopBackgroundTimer();
      _recordClockEvent('clock_pause');
    }

    _notifyTimerStateListeners();
    notifyListeners();
  }

  void configureTimer(
      {required bool isCountdownMode, required int quarterMaxTime}) {
    _isCountdownTimer = isCountdownMode;
    _quarterMinutes = quarterMaxTime ~/ (60 * 1000);

    // Important: Never create a game record just for timer configuration
    // This prevents configureTimer from inadvertently creating an "active game"
    if (_currentGameId == null) {
      debugPrint('Timer configured with no active game');
    }
  }

  void resetTimer() {
    final resetValue = _isCountdownTimer ? quarterMSec : 0;
    _timerRawTime = resetValue;
    _isTimerRunning = false;
    _stopBackgroundTimer();
    _timerStreamController.add(_timerRawTime);
    _notifyTimerStateListeners();
    notifyListeners();
  }

  void _startBackgroundTimer() {
    _timerStartTime = DateTime.now();
    _timeWhenStarted = _timerRawTime;

    _backgroundTimer?.cancel();
    _backgroundTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_timerStartTime != null) {
        final elapsed =
            DateTime.now().difference(_timerStartTime!).inMilliseconds;

        if (_isCountdownTimer) {
          _timerRawTime = _timeWhenStarted - elapsed;
        } else {
          _timerRawTime = _timeWhenStarted + elapsed;
        }

        // Emit to stream for real-time UI updates
        _timerStreamController.add(_timerRawTime);
        notifyListeners();
      }
    });
  }

  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _timerStartTime = null;
  }

  /// Returns elapsed time in milliseconds (can exceed quarter duration in overtime)
  int getElapsedTimeInQuarter() {
    final timerRawTime = _timerRawTime;
    final quarterMSec = this.quarterMSec;

    int elapsedMSec;
    if (_isCountdownTimer) {
      elapsedMSec = quarterMSec - timerRawTime;
    } else {
      elapsedMSec = timerRawTime;
    }

    // Don't clamp - allow overtime scenarios
    return elapsedMSec;
  }

  /// Returns negative values when in overtime
  int getRemainingTimeInQuarter() {
    final quarterMSec = this.quarterMSec;
    final elapsedMSec = getElapsedTimeInQuarter();
    return quarterMSec - elapsedMSec;
  }

  void configureGame({
    required String homeTeam,
    required String awayTeam,
    required DateTime gameDate,
    required int quarterMinutes,
    required bool isCountdownTimer,
  }) {
    final bool wasActive = hasActiveGame;

    _homeTeam = homeTeam;
    _awayTeam = awayTeam;
    _gameDate = gameDate;
    _quarterMinutes = quarterMinutes;
    _isCountdownTimer = isCountdownTimer;

    if (!wasActive) {
      _currentGameId = null;
    }

    notifyListeners();
  }

  void addGameEvent(GameEvent event) {
    _gameEvents.add(event);
    _notifyGameEventListeners();
    _saveGameAsync();
    notifyListeners();
  }

  void removeLastGameEvent(String team, String type, int quarter) {
    final idx = _gameEvents.lastIndexWhere(
        (e) => e.quarter == quarter && e.team == team && e.type == type);
    if (idx != -1) {
      _gameEvents.removeAt(idx);
      _notifyGameEventListeners();
      _saveGameAsync();
      notifyListeners();
    }
  }

  void _recordClockEvent(String eventType) {
    final currentTime = Duration(milliseconds: _timerRawTime);

    // Prevent duplicate sequential events
    if (_gameEvents.isNotEmpty) {
      final lastEvent = _gameEvents.last;
      if (lastEvent.type == eventType &&
          lastEvent.quarter == _selectedQuarter) {
        return;
      }
    }

    final event = GameEvent(
      quarter: _selectedQuarter,
      time: currentTime,
      team: "",
      type: eventType,
    );

    addGameEvent(event);
  }

  void recordQuarterEnd(int quarter) {
    final currentTime = Duration(milliseconds: _timerRawTime);
    final event = GameEvent(
      quarter: quarter,
      time: currentTime,
      team: "",
      type: 'clock_end',
    );

    addGameEvent(event);
    _isTimerRunning = false;
    _stopBackgroundTimer();
    _notifyTimerStateListeners();
    notifyListeners();
  }

  void updateScore(bool isHomeTeam, bool isGoal, int newCount) {
    final oldCount = getScore(isHomeTeam, isGoal);
    setScore(isHomeTeam, isGoal, newCount);

    final team = isHomeTeam ? _homeTeam : _awayTeam;
    final type = isGoal ? 'goal' : 'behind';

    // Calculate elapsed time for the event
    final timerRawTime = _timerRawTime;
    final quarterMSec = this.quarterMSec;

    int elapsedMSec;
    if (_isCountdownTimer) {
      elapsedMSec = quarterMSec - timerRawTime;
    } else {
      elapsedMSec = timerRawTime;
    }

    elapsedMSec = elapsedMSec.clamp(0, quarterMSec);
    final quarterElapsedTime = Duration(milliseconds: elapsedMSec);

    if (newCount < oldCount) {
      // Remove event
      removeLastGameEvent(team, type, _selectedQuarter);
    } else if (newCount > oldCount) {
      // Add event
      final event = GameEvent(
        quarter: _selectedQuarter,
        time: quarterElapsedTime,
        team: team,
        type: type,
      );
      addGameEvent(event);
    }
  }

  Future<void> advanceToNextQuarter() async {
    recordQuarterEnd(_selectedQuarter);

    if (_selectedQuarter < 4) {
      _selectedQuarter++;
      resetTimer();
      notifyListeners();
    }
  }

  bool isGameComplete() {
    return _gameEvents.any((e) => e.quarter == 4 && e.type == 'clock_end');
  }

  Future<void> startNewGame() async {
    await _createInitialGameRecord();
  }

  Future<void> _createInitialGameRecord() async {
    if (_currentGameId != null) return;

    try {
      // Update the game date to NOW when we actually create the game record
      // This ensures each game has the correct start time
      _gameDate = DateTime.now();

      // Create a game record to get a unique ID, but don't save it yet
      final gameRecord = GameHistoryService.createGameRecord(
        date: _gameDate,
        homeTeam: _homeTeam,
        awayTeam: _awayTeam,
        quarterMinutes: _quarterMinutes,
        isCountdownTimer: _isCountdownTimer,
        events: List<GameEvent>.from(_gameEvents),
        homeGoals: _homeGoals,
        homeBehinds: _homeBehinds,
        awayGoals: _awayGoals,
        awayBehinds: _awayBehinds,
      );

      // Only store the ID, don't save to history yet
      _currentGameId = gameRecord.id;
      debugPrint(
          'Created game ID for: $_homeTeam vs $_awayTeam at $_gameDate (not saved yet)');
    } catch (e) {
      debugPrint('Error creating initial game record: $e');
    }
  }

  /// Asynchronously save the game record without blocking the UI
  Future<void> _saveGameAsync() async {
    // Only save if we have meaningful game data
    if (_currentGameId == null || !_shouldSaveGame()) return;

    // Run the save operation without awaiting to avoid blocking the UI
    _updateGameRecord().catchError((error) {
      debugPrint('Error in async game save: $error');
    });
  }

  /// Check if the game has meaningful data worth saving
  bool _shouldSaveGame() {
    return _homeGoals > 0 ||
        _homeBehinds > 0 ||
        _awayGoals > 0 ||
        _awayBehinds > 0 ||
        _gameEvents.isNotEmpty;
  }

  /// Force immediate save of game record when game is complete
  Future<void> forceFinalSave() async {
    if (_currentGameId == null) return;

    // Only save if the game has meaningful data
    if (_shouldSaveGame()) {
      await _forceSaveGameRecord();
    } else {
      // Game has no meaningful data, just clear the current game ID
      _currentGameId = null;
      debugPrint(
          'Game completed with no meaningful data, not saving to history');
    }
  }

  Future<void> _forceSaveGameRecord() async {
    if (_currentGameId == null) return;

    try {
      final gameRecord = GameRecord(
        id: _currentGameId!,
        date: _gameDate,
        homeTeam: _homeTeam,
        awayTeam: _awayTeam,
        quarterMinutes: _quarterMinutes,
        isCountdownTimer: _isCountdownTimer,
        events: List<GameEvent>.from(_gameEvents),
        homeGoals: _homeGoals,
        homeBehinds: _homeBehinds,
        awayGoals: _awayGoals,
        awayBehinds: _awayBehinds,
      );

      await GameHistoryService.deleteGame(_currentGameId!);
      await GameHistoryService.saveGame(gameRecord);
      debugPrint('Force saved final game record: $_homeTeam vs $_awayTeam');
    } catch (e) {
      debugPrint('Error force saving game record: $e');
    }
  }

  Future<void> _updateGameRecord() async {
    if (_currentGameId == null || !_shouldSaveGame()) return;

    try {
      final gameRecord = GameRecord(
        id: _currentGameId!,
        date: _gameDate,
        homeTeam: _homeTeam,
        awayTeam: _awayTeam,
        quarterMinutes: _quarterMinutes,
        isCountdownTimer: _isCountdownTimer,
        events: List<GameEvent>.from(_gameEvents),
        homeGoals: _homeGoals,
        homeBehinds: _homeBehinds,
        awayGoals: _awayGoals,
        awayBehinds: _awayBehinds,
      );

      await GameHistoryService.deleteGame(_currentGameId!);
      await GameHistoryService.saveGame(gameRecord);
      debugPrint('Updated game record: $_homeTeam vs $_awayTeam');
    } catch (e) {
      debugPrint('Error updating game record: $e');
    }
  }

  void resetGame() {
    // Reset all game state variables
    _homeGoals = 0;
    _homeBehinds = 0;
    _awayGoals = 0;
    _awayBehinds = 0;
    _timerRawTime = _isCountdownTimer ? quarterMSec : 0;
    _selectedQuarter = 1;
    _isTimerRunning = false;
    _gameEvents.clear();

    _currentGameId = null;

    _stopBackgroundTimer();
    _timerStreamController.add(_timerRawTime);

    _notifyAllListeners();
    notifyListeners();
  }

  void addGameEventListener(VoidCallback listener) {
    _gameEventListeners.add(listener);
  }

  void removeGameEventListener(VoidCallback listener) {
    _gameEventListeners.remove(listener);
  }

  void addTimerStateListener(VoidCallback listener) {
    _timerStateListeners.add(listener);
  }

  void removeTimerStateListener(VoidCallback listener) {
    _timerStateListeners.remove(listener);
  }

  void addScoreChangeListener(VoidCallback listener) {
    _scoreChangeListeners.add(listener);
  }

  void removeScoreChangeListener(VoidCallback listener) {
    _scoreChangeListeners.remove(listener);
  }

  void _notifyGameEventListeners() {
    for (final listener in _gameEventListeners) {
      listener();
    }
  }

  void _notifyTimerStateListeners() {
    for (final listener in _timerStateListeners) {
      listener();
    }
  }

  void _notifyScoreChangeListeners() {
    for (final listener in _scoreChangeListeners) {
      listener();
    }
  }

  void _notifyAllListeners() {
    _notifyGameEventListeners();
    _notifyTimerStateListeners();
    _notifyScoreChangeListeners();
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _timerStreamController.close();
    _gameEventListeners.clear();
    _timerStateListeners.clear();
    _scoreChangeListeners.clear();
    super.dispose();
  }
}
