import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:goalkeeper/providers/game_record.dart';

class GameHistoryService {
  static const String _gamesKey = 'saved_games';
  static const Uuid _uuid = Uuid();

  static Future<void> saveGame(GameRecord game) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // Remove any game with the same ID
    gamesJson.removeWhere((gameJson) {
      final existingGame = GameRecord.fromJson(jsonDecode(gameJson));
      return existingGame.id == game.id;
    });

    // Add the new game to the beginning of the list (most recent first)
    gamesJson.insert(0, jsonEncode(game.toJson()));

    await prefs.setStringList(_gamesKey, gamesJson);
  }

  static Future<List<GameRecord>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // Parse all games and filter out empty ones
    List<GameRecord> games = gamesJson
        .map((gameJson) => GameRecord.fromJson(jsonDecode(gameJson)))
        .where((game) =>
            // Show games with any team names or events
            (game.homeTeam.isNotEmpty && game.awayTeam.isNotEmpty) ||
            game.events.isNotEmpty)
        .toList();

    return games;
  }

  static Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    gamesJson.removeWhere((gameJson) {
      final game = GameRecord.fromJson(jsonDecode(gameJson));
      return game.id == gameId;
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
}
