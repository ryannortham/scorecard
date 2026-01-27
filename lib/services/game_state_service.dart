// orchestrates game state, timer, score tracking, and persistence

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/services/game_persistence_manager.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/timer_manager.dart';
import 'package:scorecard/theme/design_tokens.dart';

/// main game state orchestrator coordinating timer, score, and persistence
class GameStateService extends ChangeNotifier {
  GameStateService();

  // managers
  final TimerManager _timerManager = TimerManager();
  final GamePersistenceManager _persistenceManager = GamePersistenceManager();

  // score state
  int _homeGoals = 0;
  int _homeBehinds = 0;
  int _awayGoals = 0;
  int _awayBehinds = 0;

  // game state
  int _selectedQuarter = 1;
  bool _isTimerRunning = false;
  final List<GameEvent> _gameEvents = [];

  // game configuration
  String _homeTeam = '';
  String _awayTeam = '';
  DateTime _gameDate = DateTime.now();
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  // listeners
  final List<VoidCallback> _gameEventListeners = [];
  final List<VoidCallback> _timerStateListeners = [];
  final List<VoidCallback> _scoreChangeListeners = [];

  // score getters
  int get homeGoals => _homeGoals;
  int get homeBehinds => _homeBehinds;
  int get awayGoals => _awayGoals;
  int get awayBehinds => _awayBehinds;
  int get homePoints =>
      _homeGoals * AppGameConstants.pointsPerGoal +
      _homeBehinds * AppGameConstants.pointsPerBehind;
  int get awayPoints =>
      _awayGoals * AppGameConstants.pointsPerGoal +
      _awayBehinds * AppGameConstants.pointsPerBehind;

  // timer getters
  int get timerRawTime => _timerManager.timerRawTime;
  Stream<int> get timerStream => _timerManager.timerStream;

  // game state getters
  int get selectedQuarter => _selectedQuarter;
  bool get isTimerRunning => _isTimerRunning;
  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;
  DateTime get gameDate => _gameDate;
  int get quarterMinutes => _quarterMinutes;
  int get quarterMSec => _quarterMinutes * 60 * 1000;
  bool get isCountdownTimer => _isCountdownTimer;

  List<GameEvent> get gameEvents => List.unmodifiable(_gameEvents);
  String? get currentGameId => _persistenceManager.currentGameId;

  bool get hasActiveGame =>
      _persistenceManager.currentGameId != null &&
      (_homeTeam.isNotEmpty ||
          _awayTeam.isNotEmpty ||
          _gameEvents.isNotEmpty ||
          _homeGoals > 0 ||
          _homeBehinds > 0 ||
          _awayGoals > 0 ||
          _awayBehinds > 0);

  // score methods
  void setScore({
    required bool isHomeTeam,
    required bool isGoal,
    required int count,
  }) {
    final team = isHomeTeam ? _homeTeam : _awayTeam;
    final scoreType = isGoal ? 'goals' : 'behinds';

    if (isGoal) {
      isHomeTeam ? _homeGoals = count : _awayGoals = count;
    } else {
      isHomeTeam ? _homeBehinds = count : _awayBehinds = count;
    }

    AppLogger.gameEvent(
      'Score update: $team $scoreType set to $count',
      details: {
        'quarter': _selectedQuarter,
        'homeScore': '$_homeGoals.$_homeBehinds',
        'awayScore': '$_awayGoals.$_awayBehinds',
        'isGoal': isGoal,
        'isHome': isHomeTeam,
      },
    );

    _notifyScoreChangeListeners();
    _scheduleSave();
    notifyListeners();
  }

  int getScore({required bool isHomeTeam, required bool isGoal}) {
    return isHomeTeam
        ? (isGoal ? _homeGoals : _homeBehinds)
        : (isGoal ? _awayGoals : _awayBehinds);
  }

  bool hasEventInCurrentQuarter({
    required bool isHomeTeam,
    required bool isGoal,
  }) {
    final team = isHomeTeam ? _homeTeam : _awayTeam;
    final type = isGoal ? 'goal' : 'behind';
    return _gameEvents.any(
      (e) => e.quarter == _selectedQuarter && e.team == team && e.type == type,
    );
  }

  void updateScore({
    required bool isHomeTeam,
    required bool isGoal,
    required int newCount,
  }) {
    final oldCount = getScore(isHomeTeam: isHomeTeam, isGoal: isGoal);
    setScore(isHomeTeam: isHomeTeam, isGoal: isGoal, count: newCount);

    final team = isHomeTeam ? _homeTeam : _awayTeam;
    final type = isGoal ? 'goal' : 'behind';

    final elapsedMSec = getElapsedTimeInQuarter().clamp(0, quarterMSec);
    final quarterElapsedTime = Duration(milliseconds: elapsedMSec);

    if (newCount < oldCount) {
      removeLastGameEvent(team, type, _selectedQuarter);
    } else if (newCount > oldCount) {
      final event = GameEvent(
        quarter: _selectedQuarter,
        time: quarterElapsedTime,
        team: team,
        type: type,
      );
      addGameEvent(event);
    }
  }

  // timer methods
  void setTimerRawTime(int newTime) {
    _timerManager.setTimerRawTime(newTime);
    notifyListeners();
  }

  void setSelectedQuarter(int newQuarter) {
    if (_selectedQuarter != newQuarter) {
      AppLogger.info(
        'Quarter changed from $_selectedQuarter to $newQuarter',
        component: 'GameState',
      );
      _performScheduledSave();
    }
    _selectedQuarter = newQuarter;
    notifyListeners();
  }

  void setTimerRunning({required bool isRunning}) {
    final wasRunning = _isTimerRunning;
    _isTimerRunning = isRunning;

    if (isRunning && !wasRunning) {
      _timerManager.start();
      _recordClockEvent('clock_start');
    } else if (!isRunning && wasRunning) {
      _timerManager.stop();
      _recordClockEvent('clock_pause');
    }

    _notifyTimerStateListeners();
    notifyListeners();
  }

  void configureTimer({
    required bool isCountdownMode,
    required int quarterMaxTime,
  }) {
    _isCountdownTimer = isCountdownMode;
    _quarterMinutes = quarterMaxTime ~/ (60 * 1000);
    _timerManager.isCountdownTimer = isCountdownMode;
    resetTimer();

    if (_persistenceManager.currentGameId == null) {
      AppLogger.debug(
        'Timer configured with no active game',
        component: 'GameState',
      );
    }
  }

  void setCountdownMode({required bool isCountdownMode}) {
    if (_isCountdownTimer != isCountdownMode) {
      _isCountdownTimer = isCountdownMode;
      _timerManager.isCountdownTimer = isCountdownMode;

      AppLogger.debug(
        'Timer mode changed to ${isCountdownMode ? 'countdown' : 'count-up'}',
        component: 'GameState',
      );

      notifyListeners();
    }
  }

  void resetTimer() {
    _isTimerRunning = false;
    _timerManager.reset(quarterMSec);
    _notifyTimerStateListeners();
    notifyListeners();
  }

  int getElapsedTimeInQuarter() =>
      _timerManager.getElapsedTimeInQuarter(quarterMSec);
  int getRemainingTimeInQuarter() =>
      _timerManager.getRemainingTimeInQuarter(quarterMSec);

  // game configuration
  void configureGame({
    required String homeTeam,
    required String awayTeam,
    required DateTime gameDate,
    required int quarterMinutes,
    required bool isCountdownTimer,
  }) {
    final wasActive = hasActiveGame;

    _homeTeam = homeTeam;
    _awayTeam = awayTeam;
    _gameDate = gameDate;
    _quarterMinutes = quarterMinutes;
    _isCountdownTimer = isCountdownTimer;

    if (!wasActive) {
      _persistenceManager.reset();
    }

    notifyListeners();
  }

  // game events
  void addGameEvent(GameEvent event) {
    _gameEvents.add(event);
    _notifyGameEventListeners();
    _scheduleSave();
    notifyListeners();
  }

  void removeLastGameEvent(String team, String type, int quarter) {
    final idx = _gameEvents.lastIndexWhere(
      (e) => e.quarter == quarter && e.team == team && e.type == type,
    );
    if (idx != -1) {
      _gameEvents.removeAt(idx);
      _notifyGameEventListeners();
      _scheduleSave();
      notifyListeners();
    }
  }

  void _recordClockEvent(String eventType) {
    final elapsedTime = Duration(milliseconds: getElapsedTimeInQuarter());

    // skip duplicate consecutive clock events
    if (_gameEvents.isNotEmpty) {
      final lastEvent = _gameEvents.last;
      if (lastEvent.type == eventType &&
          lastEvent.quarter == _selectedQuarter) {
        return;
      }
    }

    final event = GameEvent(
      quarter: _selectedQuarter,
      time: elapsedTime,
      team: '',
      type: eventType,
    );

    addGameEvent(event);
  }

  void recordQuarterEnd(int quarter) {
    final elapsedTime = Duration(milliseconds: getElapsedTimeInQuarter());
    final event = GameEvent(
      quarter: quarter,
      time: elapsedTime,
      team: '',
      type: 'clock_end',
    );

    addGameEvent(event);
    _isTimerRunning = false;
    _timerManager.stop();
    _notifyTimerStateListeners();
    _performScheduledSave();
    notifyListeners();
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

  // persistence methods
  Future<void> startNewGame() async {
    if (_persistenceManager.currentGameId != null) return;

    _gameDate = DateTime.now();

    await _persistenceManager.createInitialGameRecord(
      gameDate: _gameDate,
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
  }

  void _scheduleSave() {
    _persistenceManager.scheduleSave(
      gameDate: _gameDate,
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
  }

  void _performScheduledSave() {
    _persistenceManager.performScheduledSave(
      gameDate: _gameDate,
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
  }

  Future<void> forceFinalSave() async {
    await _persistenceManager.forceFinalSave(
      gameDate: _gameDate,
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
  }

  void resetGame() {
    AppLogger.info('Resetting game state', component: 'GameState');

    _homeGoals = 0;
    _homeBehinds = 0;
    _awayGoals = 0;
    _awayBehinds = 0;
    _selectedQuarter = 1;
    _isTimerRunning = false;
    _gameEvents.clear();

    _timerManager
      ..isCountdownTimer = _isCountdownTimer
      ..reset(quarterMSec);
    _persistenceManager.reset();

    _notifyAllListeners();
    notifyListeners();
  }

  // listener management
  void addGameEventListener(VoidCallback listener) =>
      _gameEventListeners.add(listener);
  void removeGameEventListener(VoidCallback listener) =>
      _gameEventListeners.remove(listener);
  void addTimerStateListener(VoidCallback listener) =>
      _timerStateListeners.add(listener);
  void removeTimerStateListener(VoidCallback listener) =>
      _timerStateListeners.remove(listener);
  void addScoreChangeListener(VoidCallback listener) =>
      _scoreChangeListeners.add(listener);
  void removeScoreChangeListener(VoidCallback listener) =>
      _scoreChangeListeners.remove(listener);

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
    _timerManager.dispose();
    _persistenceManager.dispose();
    _gameEventListeners.clear();
    _timerStateListeners.clear();
    _scoreChangeListeners.clear();
    super.dispose();
  }
}
