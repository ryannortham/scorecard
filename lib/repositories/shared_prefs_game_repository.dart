// SharedPreferences implementation of GameRepository

import 'dart:convert';

import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/repositories/game_repository.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [GameRepository].
class SharedPrefsGameRepository implements GameRepository {
  static const String _gamesKey = 'saved_games';

  @override
  Future<void> saveGame(GameRecord game) async {
    final stopwatch = Stopwatch()..start();

    final prefs = await SharedPreferences.getInstance();

    // Efficient: remove by id match without parsing, insert at beginning
    final gamesJson =
        (prefs.getStringList(_gamesKey) ?? [])
          ..removeWhere((gameJson) => gameJson.contains('"id":"${game.id}"'))
          ..insert(0, jsonEncode(game.toJson()));

    await prefs.setStringList(_gamesKey, gamesJson);

    stopwatch.stop();
    AppLogger.performance(
      'Game save',
      stopwatch.elapsed,
      component: 'GameRepository',
    );
  }

  @override
  Future<GameRecord?> loadGameById(String gameId) async {
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

  @override
  Future<List<GameRecord>> loadAllGames() async {
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
                  component: 'GameRepository',
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
      component: 'GameRepository',
    );
    AppLogger.info('Loaded ${games.length} games', component: 'GameRepository');

    return games;
  }

  @override
  Future<List<GameSummary>> loadGameSummaries({
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
          component: 'GameRepository',
          data: e.toString(),
        );
        continue;
      }
    }

    return summaries;
  }

  @override
  Future<int> getGameCount() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList(_gamesKey) ?? [];
    return gamesJson.length;
  }

  @override
  Future<int> getValidGameCount({String? excludeGameId}) async {
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

  @override
  Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();

    final gamesJson =
        (prefs.getStringList(_gamesKey) ?? [])
          ..removeWhere((gameJson) => gameJson.contains('"id":"$gameId"'));

    await prefs.setStringList(_gamesKey, gamesJson);
  }

  @override
  Future<void> clearAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesKey);
  }
}
