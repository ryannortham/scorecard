// abstract interface for game persistence operations

import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/models/game_summary.dart';

/// Repository interface for game data persistence.
///
/// Abstracts storage implementation to enable testing and
/// potential future storage backends (e.g. SQLite, cloud sync).
abstract class GameRepository {
  /// Saves a game record, replacing any existing record with the same ID.
  Future<void> saveGame(GameRecord game);

  /// Loads a specific game by ID. Returns null if not found.
  Future<GameRecord?> loadGameById(String gameId);

  /// Loads all games. Use [loadGameSummaries] for paginated list display.
  Future<List<GameRecord>> loadAllGames();

  /// Loads paginated game summaries for efficient list display.
  ///
  /// [limit] - Maximum number of summaries to return.
  /// [offset] - Number of games to skip (for pagination).
  /// [excludeGameId] - Optional game ID to exclude (e.g. current active game).
  Future<List<GameSummary>> loadGameSummaries({
    int limit = 20,
    int offset = 0,
    String? excludeGameId,
  });

  /// Returns total count of stored games.
  Future<int> getGameCount();

  /// Returns count of valid games (with team data), optionally excluding one.
  Future<int> getValidGameCount({String? excludeGameId});

  /// Deletes a game by ID.
  Future<void> deleteGame(String gameId);

  /// Removes all stored games.
  Future<void> clearAllGames();
}
