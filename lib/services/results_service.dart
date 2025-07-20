import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';

/// Lightweight game summary for list display
class GameSummary {
  final String id;
  final DateTime date;
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int homeBehinds;
  final int awayGoals;
  final int awayBehinds;

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

  int get homePoints => homeGoals * 6 + homeBehinds;
  int get awayPoints => awayGoals * 6 + awayBehinds;

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
}

class ResultsService {
  static const String _gamesKey = 'saved_games';
  static const Uuid _uuid = Uuid();

  static Future<void> saveGame(GameRecord game) async {
    final stopwatch = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // More efficient: Remove any game with the same ID without parsing
    gamesJson.removeWhere((gameJson) {
      return gameJson.contains('"id":"${game.id}"');
    });

    // Add the new game to the beginning of the list (most recent first)
    gamesJson.insert(0, jsonEncode(game.toJson()));

    await prefs.setStringList(_gamesKey, gamesJson);

    stopwatch.stop();
    AppLogger.performance(
      'Game save',
      stopwatch.elapsed,
      component: 'GameResults',
    );
  }

  /// Load game summaries with pagination for efficient list display
  static Future<List<GameSummary>> loadGameSummaries({
    int limit = 20,
    int offset = 0,
    String? excludeGameId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // Calculate pagination bounds
    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, gamesJson.length);

    if (startIndex >= gamesJson.length) {
      return [];
    }

    // Process only the required slice
    final summaries = <GameSummary>[];
    for (int i = startIndex; i < endIndex; i++) {
      try {
        final gameJson = jsonDecode(gamesJson[i]) as Map<String, dynamic>;

        // Skip excluded game (e.g., current game in progress)
        if (excludeGameId != null && gameJson['id'] == excludeGameId) {
          continue;
        }

        // Skip invalid games
        final homeTeam = gameJson['homeTeam'] as String? ?? '';
        final awayTeam = gameJson['awayTeam'] as String? ?? '';
        if (homeTeam.isEmpty || awayTeam.isEmpty) {
          continue;
        }

        final summary = GameSummary.fromJson(gameJson);
        summaries.add(summary);
      } catch (e) {
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

  /// Get total count of valid games (excluding specified game)
  static Future<int> getValidGameCount({String? excludeGameId}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    int count = 0;
    for (final gameJsonStr in gamesJson) {
      try {
        final gameJson = jsonDecode(gameJsonStr) as Map<String, dynamic>;

        // Skip excluded game
        if (excludeGameId != null && gameJson['id'] == excludeGameId) {
          continue;
        }

        // Skip invalid games
        final homeTeam = gameJson['homeTeam'] as String? ?? '';
        final awayTeam = gameJson['awayTeam'] as String? ?? '';
        if (homeTeam.isEmpty || awayTeam.isEmpty) {
          continue;
        }

        count++;
      } catch (e) {
        // Skip corrupted games
        continue;
      }
    }

    return count;
  }

  /// Load a specific game by ID with full data (for details view)
  static Future<GameRecord?> loadGameById(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    for (final gameJsonStr in gamesJson) {
      try {
        final gameJson = jsonDecode(gameJsonStr) as Map<String, dynamic>;
        if (gameJson['id'] == gameId) {
          return GameRecord.fromJson(gameJson);
        }
      } catch (e) {
        // Skip corrupted game data
        continue;
      }
    }

    return null;
  }

  static Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // More efficient deletion without parsing all games
    gamesJson.removeWhere((gameJson) {
      return gameJson.contains('"id":"$gameId"');
    });

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
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];
    return gamesJson.length;
  }

  static Future<void> clearAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesKey);
  }

  /// Legacy method for backwards compatibility - loads all games at once
  static Future<List<GameRecord>> loadGames() async {
    final stopwatch = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // Parse all games and filter out empty ones
    List<GameRecord> games =
        gamesJson
            .map((gameJson) {
              try {
                return GameRecord.fromJson(jsonDecode(gameJson));
              } catch (e) {
                AppLogger.warning(
                  'Skipping corrupted game data',
                  component: 'GameResults',
                  data: e.toString(),
                );
                return null; // Skip corrupted games
              }
            })
            .where((game) => game != null)
            .cast<GameRecord>()
            .where(
              (game) =>
                  // Show games with any team names or events
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
