// game results persistence and retrieval

import 'dart:convert';

import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// lightweight game summary for efficient list display
class GameSummary {
  GameSummary({
    required this.id,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.homeBehinds,
    required this.awayGoals,
    required this.awayBehinds,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      homeGoals: json['homeGoals'] as int,
      homeBehinds: json['homeBehinds'] as int,
      awayGoals: json['awayGoals'] as int,
      awayBehinds: json['awayBehinds'] as int,
    );
  }
  final String id;
  final DateTime date;
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int homeBehinds;
  final int awayGoals;
  final int awayBehinds;

  int get homePoints => homeGoals * 6 + homeBehinds;
  int get awayPoints => awayGoals * 6 + awayBehinds;
}

class ResultsService {
  static const String _gamesKey = 'saved_games';
  static const Uuid _uuid = Uuid();

  static Future<void> saveGame(GameRecord game) async {
    final stopwatch = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();

    // efficient: remove by id match without parsing, insert at beginning
    final gamesJson =
        (prefs.getStringList(_gamesKey) ?? [])
          ..removeWhere((gameJson) => gameJson.contains('"id":"${game.id}"'))
          ..insert(0, jsonEncode(game.toJson()));

    await prefs.setStringList(_gamesKey, gamesJson);

    stopwatch.stop();
    AppLogger.performance(
      'Game save',
      stopwatch.elapsed,
      component: 'GameResults',
    );
  }

  /// load paginated game summaries for list display
  static Future<List<GameSummary>> loadGameSummaries({
    int limit = 20,
    int offset = 0,
    String? excludeGameId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];

    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, gamesJson.length);

    if (startIndex >= gamesJson.length) {
      return [];
    }

    final summaries = <GameSummary>[];
    for (var i = startIndex; i < endIndex; i++) {
      try {
        final gameJson = jsonDecode(gamesJson[i]) as Map<String, dynamic>;

        if (excludeGameId != null && gameJson['id'] == excludeGameId) {
          continue;
        }

        final homeTeam = gameJson['homeTeam'] as String? ?? '';
        final awayTeam = gameJson['awayTeam'] as String? ?? '';
        if (homeTeam.isEmpty || awayTeam.isEmpty) {
          continue;
        }

        final summary = GameSummary.fromJson(gameJson);
        summaries.add(summary);
      } on Exception catch (e) {
        AppLogger.warning(
          'Skipping corrupted game summary data',
          component: 'GameResults',
          data: e.toString(),
        );
        continue;
      }
    }

    return summaries;
  }

  /// total count of valid games, optionally excluding specified id
  static Future<int> getValidGameCount({String? excludeGameId}) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];

    var count = 0;
    for (final gameJsonStr in gamesJson) {
      try {
        final gameJson = jsonDecode(gameJsonStr) as Map<String, dynamic>;

        if (excludeGameId != null && gameJson['id'] == excludeGameId) {
          continue;
        }

        final homeTeam = gameJson['homeTeam'] as String? ?? '';
        final awayTeam = gameJson['awayTeam'] as String? ?? '';
        if (homeTeam.isEmpty || awayTeam.isEmpty) {
          continue;
        }

        count++;
      } on Exception {
        continue;
      }
    }

    return count;
  }

  /// load specific game by id with full data for details view
  static Future<GameRecord?> loadGameById(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];

    for (final gameJsonStr in gamesJson) {
      try {
        final gameJson = jsonDecode(gameJsonStr) as Map<String, dynamic>;
        if (gameJson['id'] == gameId) {
          return GameRecord.fromJson(gameJson);
        }
      } on Exception {
        continue;
      }
    }

    return null;
  }

  static Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();

    final gamesJson =
        (prefs.getStringList(_gamesKey) ?? [])
          ..removeWhere((gameJson) => gameJson.contains('"id":"$gameId"'));

    await prefs.setStringList(_gamesKey, gamesJson);
  }

  static GameRecord createGameRecord({
    required DateTime date,
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
    return GameRecord(
      id: _uuid.v4(),
      date: date,
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

  static Future<int> getGameCount() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];
    return gamesJson.length;
  }

  static Future<void> clearAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesKey);
  }

  /// loads all games at once (use loadGameSummaries for pagination)
  static Future<List<GameRecord>> loadGames() async {
    final stopwatch = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];

    final games =
        gamesJson
            .map((gameJson) {
              try {
                return GameRecord.fromJson(
                  jsonDecode(gameJson) as Map<String, dynamic>,
                );
              } on Exception catch (e) {
                AppLogger.warning(
                  'Skipping corrupted game data',
                  component: 'GameResults',
                  data: e.toString(),
                );
                return null;
              }
            })
            .where((game) => game != null)
            .cast<GameRecord>()
            .where(
              (game) =>
                  (game.homeTeam.isNotEmpty && game.awayTeam.isNotEmpty) ||
                  game.events.isNotEmpty,
            )
            .toList();

    stopwatch.stop();
    AppLogger.performance(
      'Load games',
      stopwatch.elapsed,
      component: 'GameResults',
    );
    AppLogger.info('Loaded ${games.length} games', component: 'GameResults');

    return games;
  }
}
