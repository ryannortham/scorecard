import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:uuid/uuid.dart';

class GameHistoryService {
  static const String _gamesKey = 'saved_games';
  static const Uuid _uuid = Uuid();

  /// Save a game to local storage
  static Future<void> saveGame(GameRecord game) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    // Add the new game to the beginning of the list (most recent first)
    gamesJson.insert(0, jsonEncode(game.toJson()));

    await prefs.setStringList(_gamesKey, gamesJson);
  }

  /// Load all saved games from local storage
  static Future<List<GameRecord>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    return gamesJson
        .map((gameJson) => GameRecord.fromJson(jsonDecode(gameJson)))
        .toList();
  }

  /// Delete a specific game by ID
  static Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    gamesJson.removeWhere((gameJson) {
      final game = GameRecord.fromJson(jsonDecode(gameJson));
      return game.id == gameId;
    });

    await prefs.setStringList(_gamesKey, gamesJson);
  }

  /// Create a GameRecord from current game state
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

  /// Get the total number of saved games
  static Future<int> getGameCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];
    return gamesJson.length;
  }

  /// Clear all saved games (for debugging or user request)
  static Future<void> clearAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesKey);
  }
}
