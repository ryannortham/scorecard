// manages preloaded game results for fast tab navigation

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/repositories/game_repository.dart';
import 'package:scorecard/repositories/shared_prefs_game_repository.dart';
import 'package:scorecard/services/logger_service.dart';

/// Manages preloaded game summaries for the Results tab.
///
/// Preloads the initial page of game summaries during app startup to
/// eliminate loading delays when navigating to the Results tab.
class ResultsViewModel extends ChangeNotifier {
  /// Creates a ResultsViewModel with an optional [GameRepository].
  ///
  /// If no repository is provided, defaults to [SharedPrefsGameRepository].
  /// Pass a mock repository for testing.
  ResultsViewModel({GameRepository? repository})
    : _repository = repository ?? SharedPrefsGameRepository() {
    unawaited(_preloadSummaries());
  }

  final GameRepository _repository;
  List<GameSummary> _summaries = [];
  bool _loaded = false;
  bool _isLoadingMore = false;
  bool _hasMoreGames = true;
  String? _excludeGameId;

  static const int _pageSize = 20;

  /// The preloaded game summaries.
  List<GameSummary> get summaries => _summaries;

  /// Whether the initial data has finished loading.
  bool get loaded => _loaded;

  /// Whether more data is currently being loaded.
  bool get isLoadingMore => _isLoadingMore;

  /// Whether there are more games to load.
  bool get hasMoreGames => _hasMoreGames;

  /// The game ID to exclude from results (e.g. current active game).
  String? get excludeGameId => _excludeGameId;

  /// Sets the game ID to exclude from results (e.g. current active game).
  set excludeGameId(String? gameId) {
    if (_excludeGameId != gameId) {
      _excludeGameId = gameId;
      // Reload if the excluded game changed
      unawaited(refresh());
    }
  }

  Future<void> _preloadSummaries() async {
    try {
      AppLogger.debug(
        'ResultsViewModel: Preloading game summaries',
        component: 'Results',
      );

      _summaries = await _repository.loadGameSummaries(
        excludeGameId: _excludeGameId,
      );

      _hasMoreGames = _summaries.length == _pageSize;
      _loaded = true;

      AppLogger.debug(
        'ResultsViewModel: Preloaded ${_summaries.length} summaries',
        component: 'Results',
      );

      notifyListeners();
    } on Exception catch (e) {
      AppLogger.error(
        'ResultsViewModel: Failed to preload summaries',
        component: 'Results',
        error: e,
      );
      _loaded = true; // Mark as loaded even on error to unblock splash
      notifyListeners();
    }
  }

  /// Refreshes the game summaries from scratch.
  Future<void> refresh() async {
    _loaded = false;
    _summaries.clear();
    _hasMoreGames = true;
    notifyListeners();

    await _preloadSummaries();
  }

  /// Loads the next page of game summaries.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMoreGames) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newSummaries = await _repository.loadGameSummaries(
        offset: _summaries.length,
        excludeGameId: _excludeGameId,
      );

      _summaries.addAll(newSummaries);
      _hasMoreGames = newSummaries.length == _pageSize;
    } on Exception catch (e) {
      AppLogger.error(
        'ResultsViewModel: Failed to load more summaries',
        component: 'Results',
        error: e,
      );
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Removes a game from the cached summaries list.
  ///
  /// Call this after deleting a game to avoid a full refresh.
  void removeGame(String gameId) {
    _summaries.removeWhere((s) => s.id == gameId);
    notifyListeners();
  }

  /// Removes multiple games from the cached summaries list.
  void removeGames(List<String> gameIds) {
    final idsSet = gameIds.toSet();
    _summaries.removeWhere((s) => idsSet.contains(s.id));
    notifyListeners();
  }
}
