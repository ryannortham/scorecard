// intelligent game persistence with batching and scheduled saves

import 'dart:async';

import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/results_service.dart';

/// manages game persistence with intelligent batching
class GamePersistenceManager {
  Timer? _saveTimer;
  bool _hasPendingSave = false;
  int _eventsSinceLastSave = 0;
  String? _currentGameId;

  // save every 30 seconds during active play, or after 10 events
  static const int _saveIntervalSeconds = 30;
  static const int _eventsPerSave = 10;

  String? get currentGameId => _currentGameId;

  bool shouldSaveGame({
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
    required List<GameEvent> events,
  }) {
    return homeGoals > 0 ||
        homeBehinds > 0 ||
        awayGoals > 0 ||
        awayBehinds > 0 ||
        events.isNotEmpty;
  }

  Future<String?> createInitialGameRecord({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) async {
    if (_currentGameId != null) return _currentGameId;

    try {
      final gameRecord = ResultsService.createGameRecord(
        date: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      );

      _currentGameId = gameRecord.id;
      _resetSaveState();

      AppLogger.debug(
        'Created game ID: ${gameRecord.id}',
        component: 'GamePersistence',
        data: {
          'homeTeam': homeTeam,
          'awayTeam': awayTeam,
          'gameDate': gameDate,
        },
      );

      return _currentGameId;
    } on Exception catch (e) {
      AppLogger.error(
        'Error creating initial game record',
        component: 'GamePersistence',
        error: e,
      );
      return null;
    }
  }

  void scheduleSave({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) {
    if (_currentGameId == null) return;
    if (!shouldSaveGame(
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
      events: events,
    )) {
      return;
    }

    _eventsSinceLastSave++;
    _hasPendingSave = true;

    _saveTimer?.cancel();

    // save immediately if accumulated enough events
    if (_eventsSinceLastSave >= _eventsPerSave) {
      performScheduledSave(
        gameDate: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      );
      return;
    }

    // schedule save after interval
    _saveTimer = Timer(const Duration(seconds: _saveIntervalSeconds), () {
      unawaited(
        _performScheduledSaveAsync(
          gameDate: gameDate,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
          isCountdownTimer: isCountdownTimer,
          events: events,
          homeGoals: homeGoals,
          homeBehinds: homeBehinds,
          awayGoals: awayGoals,
          awayBehinds: awayBehinds,
        ),
      );
    });
  }

  Future<void> _performScheduledSaveAsync({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) async {
    performScheduledSave(
      gameDate: gameDate,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      quarterMinutes: quarterMinutes,
      isCountdownTimer: isCountdownTimer,
      events: events,
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
    );
  }

  void performScheduledSave({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) {
    if (!_hasPendingSave || _currentGameId == null) return;

    _resetSaveState();

    unawaited(
      _updateGameRecord(
        gameDate: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      ).catchError((Object error) {
        AppLogger.error(
          'Error in scheduled game save',
          component: 'GamePersistence',
          error: error,
        );
      }),
    );
  }

  /// force immediate save when game is complete
  Future<void> forceFinalSave({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) async {
    if (_currentGameId == null) return;

    if (shouldSaveGame(
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
      events: events,
    )) {
      await _forceSaveGameRecord(
        gameDate: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      );
    } else {
      _currentGameId = null;
      AppLogger.info(
        'Game completed with no meaningful data, not saving to results',
        component: 'GamePersistence',
      );
    }
  }

  Future<void> _forceSaveGameRecord({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) async {
    if (_currentGameId == null) return;

    try {
      final gameRecord = GameRecord(
        id: _currentGameId!,
        date: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      );

      await ResultsService.saveGame(gameRecord);
      AppLogger.info(
        'Force saved final game record',
        component: 'GamePersistence',
        data: '$homeTeam vs $awayTeam',
      );
    } on Exception catch (e) {
      AppLogger.error(
        'Error force saving game record',
        component: 'GamePersistence',
        error: e,
      );
    }
  }

  Future<void> _updateGameRecord({
    required DateTime gameDate,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) async {
    if (_currentGameId == null) return;
    if (!shouldSaveGame(
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
      events: events,
    )) {
      return;
    }

    try {
      final gameRecord = GameRecord(
        id: _currentGameId!,
        date: gameDate,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        quarterMinutes: quarterMinutes,
        isCountdownTimer: isCountdownTimer,
        events: events,
        homeGoals: homeGoals,
        homeBehinds: homeBehinds,
        awayGoals: awayGoals,
        awayBehinds: awayBehinds,
      );

      await ResultsService.saveGame(gameRecord);
    } on Exception catch (e) {
      AppLogger.error(
        'Error updating game record',
        component: 'GamePersistence',
        error: e,
      );
    }
  }

  void reset() {
    _currentGameId = null;
    _resetSaveState();
  }

  void _resetSaveState() {
    _eventsSinceLastSave = 0;
    _hasPendingSave = false;
    _saveTimer?.cancel();
  }

  void dispose() {
    _saveTimer?.cancel();
  }
}
