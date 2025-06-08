import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/game_record.dart';
import 'game_history_service.dart';

/// Centralized, widget-independent game state management service
/// This service maintains all game state without depending on the widget tree
class GameStateService extends ChangeNotifier {
  static GameStateService? _instance;
  static GameStateService get instance => _instance ??= GameStateService._();

  GameStateService._();

  // Game state
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;
  int _timerRawTime = 0;
  int _selectedQuarter = 1;
  bool _isTimerRunning = false;
  final List<GameEvent> _gameEvents = [];

  // Game configuration
  String _homeTeam = '';
  String _awayTeam = '';
  DateTime _gameDate = DateTime.now();
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  // Timer management
  Timer? _backgroundTimer;
  DateTime? _timerStartTime;
  int _timeWhenStarted = 0;

  // Stream controller for real-time timer updates
  final StreamController<int> _timerStreamController =
      StreamController<int>.broadcast();

  // Game persistence
  String? _currentGameId;
  Timer? _saveTimer;

  // Event listeners
  final List<VoidCallback> _gameEventListeners = [];
  final List<VoidCallback> _timerStateListeners = [];
  final List<VoidCallback> _scoreChangeListeners = [];

  // Getters - Score State
  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints => _homeGoals * 6 + _homeBehinds;
  int get awayPoints => _awayGoals * 6 + _awayBehinds;

  // Getters - Timer State
  int get timerRawTime => _timerRawTime;
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => _isTimerRunning;

  // Stream for real-time timer updates (millisecond precision)
  Stream<int> get timerStream => _timerStreamController.stream;

  // Getters - Game Configuration
  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;
  DateTime get gameDate => _gameDate;
  int get quarterMinutes => _quarterMinutes;
  int get quarterMSec => _quarterMinutes * 60 * 1000;
  bool get isCountdownTimer => _isCountdownTimer;

  // Getters - Game Events
  List<GameEvent> get gameEvents => List.unmodifiable(_gameEvents);
  String? get currentGameId => _currentGameId;

  // Score Management
  void setScore(bool isHomeTeam, bool isGoal, int count) {
    if (isGoal) {
      isHomeTeam ? _homeGoals = count : _awayGoals = count;
    } else {
      isHomeTeam ? _homeBehinds = count : _awayBehinds = count;
    }
    _notifyScoreChangeListeners();
    _scheduleGameSave();
    notifyListeners();
  }

  int getScore(bool isHomeTeam, bool isGoal) {
    return isHomeTeam
        ? (isGoal ? _homeGoals : _homeBehinds)
        : (isGoal ? _awayGoals : _awayBehinds);
  }

  // Timer Management
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

  /// Calculate the actual elapsed time in the current quarter
  /// This should be used for business logic, not display purposes
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

  /// Get the remaining time in the current quarter
  /// Returns negative values when in overtime
  int getRemainingTimeInQuarter() {
    final quarterMSec = this.quarterMSec;
    final elapsedMSec = getElapsedTimeInQuarter();
    return quarterMSec - elapsedMSec;
  }

  // Game Configuration
  void configureGame({
    required String homeTeam,
    required String awayTeam,
    required DateTime gameDate,
    required int quarterMinutes,
    required bool isCountdownTimer,
  }) {
    _homeTeam = homeTeam;
    _awayTeam = awayTeam;
    _gameDate = gameDate;
    _quarterMinutes = quarterMinutes;
    _isCountdownTimer = isCountdownTimer;
    notifyListeners();
  }

  // Game Event Management
  void addGameEvent(GameEvent event) {
    _gameEvents.add(event);
    _notifyGameEventListeners();
    _scheduleGameSave();
    notifyListeners();
  }

  void removeLastGameEvent(String team, String type, int quarter) {
    final idx = _gameEvents.lastIndexWhere(
        (e) => e.quarter == quarter && e.team == team && e.type == type);
    if (idx != -1) {
      _gameEvents.removeAt(idx);
      _notifyGameEventListeners();
      _scheduleGameSave();
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

  // Score change with automatic event recording
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

  // Quarter Management
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

  // Game Lifecycle Management
  Future<void> startNewGame() async {
    await _createInitialGameRecord();
  }

  Future<void> _createInitialGameRecord() async {
    if (_currentGameId != null) return;

    try {
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

      await GameHistoryService.saveGame(gameRecord);
      _currentGameId = gameRecord.id;
      debugPrint('Created initial game record: $_homeTeam vs $_awayTeam');
    } catch (e) {
      debugPrint('Error creating initial game record: $e');
    }
  }

  void _scheduleGameSave() {
    if (_currentGameId == null) return;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _updateGameRecord();
    });
  }

  Future<void> _updateGameRecord() async {
    if (_currentGameId == null) return;

    try {
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

      await GameHistoryService.deleteGame(_currentGameId!);
      await GameHistoryService.saveGame(gameRecord);
      _currentGameId = gameRecord.id;
      debugPrint(
          'Updated game record: $_homeTeam $_homeGoals.$_homeBehinds - $_awayTeam $_awayGoals.$_awayBehinds');
    } catch (e) {
      debugPrint('Error updating game record: $e');
    }
  }

  void resetGame() {
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
    _saveTimer?.cancel();
    _timerStreamController.add(_timerRawTime);

    _notifyAllListeners();
    notifyListeners();
  }

  // Event Listener Management
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
    _saveTimer?.cancel();
    _timerStreamController.close();
    _gameEventListeners.clear();
    _timerStateListeners.clear();
    _scoreChangeListeners.clear();
    super.dispose();
  }
}
