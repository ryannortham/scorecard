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

    // Check if we already have a similar game (same teams and close timestamp)
    bool hasSimilarGame = false;
    int similarGameIndex = -1;

    for (int i = 0; i < gamesJson.length; i++) {
      final existingGame = GameRecord.fromJson(jsonDecode(gamesJson[i]));

      // Check if teams match (in either order)
      bool teamsMatch = (existingGame.homeTeam == game.homeTeam &&
              existingGame.awayTeam == game.awayTeam) ||
          (existingGame.homeTeam == game.awayTeam &&
              existingGame.awayTeam == game.homeTeam);

      // Check if date is close (within 5 minutes)
      bool datesClose =
          (game.date.difference(existingGame.date).inMinutes.abs() < 5);

      if (teamsMatch && datesClose && existingGame.id != game.id) {
        hasSimilarGame = true;
        similarGameIndex = i;
        break;
      }
    }

    // If we have a similar game, remove it
    if (hasSimilarGame && similarGameIndex >= 0) {
      gamesJson.removeAt(similarGameIndex);
    }

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

    // Parse all games
    List<GameRecord> allGames = gamesJson
        .map((gameJson) => GameRecord.fromJson(jsonDecode(gameJson)))
        .where((game) =>
            // Show games with any team names or events
            (game.homeTeam.isNotEmpty && game.awayTeam.isNotEmpty) ||
            game.events.isNotEmpty)
        .toList();

    // If there are no games, return an empty list
    if (allGames.isEmpty) return [];

    // Deduplicate games based on same teams and date (within 1 minute)
    List<GameRecord> uniqueGames = [];
    var processedGameKeys = <String>{};

    for (var game in allGames) {
      // Create a key with teams (sorted alphabetically to handle same match different order)
      var teams = [game.homeTeam, game.awayTeam]..sort();
      // Round down to nearest minute to group games created close together
      var dateKey =
          "${game.date.year}-${game.date.month}-${game.date.day}-${game.date.hour}-${game.date.minute}";
      var gameKey = "${teams.join('-')}-$dateKey";

      // If this is the first time we're seeing this game key, add it
      if (!processedGameKeys.contains(gameKey)) {
        uniqueGames.add(game);
        processedGameKeys.add(gameKey);
      } else {
        // If we've seen this key before, merge events into the first game with this key
        int existingGameIndex = uniqueGames.indexWhere((existingGame) {
          var existingTeams = [existingGame.homeTeam, existingGame.awayTeam]
            ..sort();
          var existingDateKey =
              "${existingGame.date.year}-${existingGame.date.month}-${existingGame.date.day}-${existingGame.date.hour}-${existingGame.date.minute}";
          var existingGameKey = "${existingTeams.join('-')}-$existingDateKey";
          return existingGameKey == gameKey;
        });

        if (existingGameIndex >= 0) {
          // Take most recent game (the one with the most events)
          if (game.events.length >
              uniqueGames[existingGameIndex].events.length) {
            uniqueGames[existingGameIndex] = game;
          }
        }
      }
    }

    return uniqueGames;
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

  static Future<int> deduplicateGames() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gamesJson = prefs.getStringList(_gamesKey) ?? [];

    if (gamesJson.isEmpty) return 0;

    // Parse all games
    List<GameRecord> allGames = gamesJson
        .map((gameJson) => GameRecord.fromJson(jsonDecode(gameJson)))
        .toList();

    // Track processed games
    var processedGameKeys = <String>{};
    var uniqueGames = <GameRecord>[];
    var removedCount = 0;

    for (var game in allGames) {
      // Create a unique key for this game based on teams and date
      var teams = [game.homeTeam, game.awayTeam]..sort();
      var dateKey =
          "${game.date.year}-${game.date.month}-${game.date.day}-${game.date.hour}-${game.date.minute}";
      var gameKey = "${teams.join('-')}-$dateKey";

      if (!processedGameKeys.contains(gameKey)) {
        // This is a new game, keep it
        uniqueGames.add(game);
        processedGameKeys.add(gameKey);
      } else {
        // This is a duplicate, skip it
        removedCount++;
      }
    }

    // If we removed any duplicates, save the deduplicated list
    if (removedCount > 0) {
      final List<String> updatedGamesJson =
          uniqueGames.map((game) => jsonEncode(game.toJson())).toList();

      await prefs.setStringList(_gamesKey, updatedGamesJson);
    }

    return removedCount;
  }
}
