// mock implementation of GameRepository for testing

import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/repositories/game_repository.dart';

/// In-memory mock implementation of [GameRepository] for testing.
class MockGameRepository implements GameRepository {
  MockGameRepository({List<GameRecord>? initialGames})
    : _games =
          initialGames != null
              ? Map.fromEntries(
                initialGames.map((g) => MapEntry(g.id, g)),
              )
              : {};

  final Map<String, GameRecord> _games;

  /// Tracks all save operations for verification in tests.
  final List<GameRecord> saveHistory = [];

  /// Number of times loadAllGames was called.
  int loadAllGamesCallCount = 0;

  /// Number of times loadGameById was called.
  int loadGameByIdCallCount = 0;

  @override
  Future<void> saveGame(GameRecord game) async {
    _games[game.id] = game;
    saveHistory.add(game);
  }

  @override
  Future<GameRecord?> loadGameById(String gameId) async {
    loadGameByIdCallCount++;
    return _games[gameId];
  }

  @override
  Future<List<GameRecord>> loadAllGames() async {
    loadAllGamesCallCount++;
    final games =
        _games.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return games;
  }

  @override
  Future<List<GameSummary>> loadGameSummaries({
    int limit = 20,
    int offset = 0,
    String? excludeGameId,
  }) async {
    var games =
        _games.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    if (excludeGameId != null) {
      games = games.where((g) => g.id != excludeGameId).toList();
    }

    final paginated = games.skip(offset).take(limit).toList();

    return paginated
        .map(
          (game) => GameSummary(
            id: game.id,
            date: game.date,
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            homeGoals: game.homeGoals,
            homeBehinds: game.homeBehinds,
            awayGoals: game.awayGoals,
            awayBehinds: game.awayBehinds,
          ),
        )
        .toList();
  }

  @override
  Future<int> getGameCount() async {
    return _games.length;
  }

  @override
  Future<int> getValidGameCount({String? excludeGameId}) async {
    var count =
        _games.values
            .where((g) => g.homeTeam.isNotEmpty && g.awayTeam.isNotEmpty)
            .length;
    if (excludeGameId != null && _games.containsKey(excludeGameId)) {
      final excluded = _games[excludeGameId]!;
      if (excluded.homeTeam.isNotEmpty && excluded.awayTeam.isNotEmpty) {
        count--;
      }
    }
    return count;
  }

  @override
  Future<void> deleteGame(String gameId) async {
    _games.remove(gameId);
  }

  @override
  Future<void> clearAllGames() async {
    _games.clear();
  }

  /// Returns the current games (for test verification).
  List<GameRecord> get currentGames => _games.values.toList();
}
