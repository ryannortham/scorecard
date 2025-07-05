import 'package:flutter/material.dart';
import '../services/app_logger.dart';
import '../services/game_history_service.dart';
import '../services/game_state_service.dart';
import '../widgets/game_history/game_summary_card.dart';
import '../widgets/bottom_sheets/confirmation_bottom_sheet.dart';
import '../widgets/game_setup/app_drawer.dart';
import 'package:scorecard/screens/game_details.dart' as details;

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  List<GameSummary> _gameSummaries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreGames = true;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedGameIds = {};

  @override
  void initState() {
    super.initState();
    _loadGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGames();
    }
  }

  Future<void> _loadGames() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _gameSummaries.clear();
      _hasMoreGames = true;
    });

    await _loadGamePage(0);
  }

  Future<void> _loadMoreGames() async {
    if (_isLoadingMore || !_hasMoreGames) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadGamePage(_gameSummaries.length);

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _loadGamePage(int offset) async {
    try {
      final gameStateService = GameStateService.instance;

      final newSummaries = await GameHistoryService.loadGameSummaries(
        limit: _pageSize,
        offset: offset,
        excludeGameId: gameStateService.currentGameId,
      );

      if (mounted) {
        setState(() {
          if (offset == 0) {
            _gameSummaries = newSummaries;
            _isLoading = false;
          } else {
            _gameSummaries.addAll(newSummaries);
          }
          _hasMoreGames = newSummaries.length == _pageSize;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading game summaries',
        component: 'GameHistory',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading games: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _enterSelectionMode(String gameId) {
    setState(() {
      _isSelectionMode = true;
      _selectedGameIds.add(gameId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedGameIds.clear();
    });
  }

  void _toggleGameSelection(String gameId) {
    setState(() {
      if (_selectedGameIds.contains(gameId)) {
        _selectedGameIds.remove(gameId);
        if (_selectedGameIds.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedGameIds.add(gameId);
      }
    });
  }

  Future<void> _deleteSelectedGames() async {
    if (_selectedGameIds.isEmpty) return;

    await ConfirmationBottomSheet.show(
      context: context,
      actionText: 'Delete ${_selectedGameIds.length} games',
      actionIcon: Icons.delete_outline,
      isDestructive: true,
      onConfirm: () async {
        try {
          // Delete all selected games
          final gameIdsToDelete = List<String>.from(_selectedGameIds);
          for (final gameId in gameIdsToDelete) {
            await GameHistoryService.deleteGame(gameId);
          }

          _exitSelectionMode();
          await _loadGames(); // Refresh the list

          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${gameIdsToDelete.length} games deleted successfully',
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting games: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _showGameDetails(String gameId) async {
    // Load the full game data only when needed
    final game = await GameHistoryService.loadGameById(gameId);
    if (game != null && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => details.GameDetailsPage(game: game),
        ),
      );

      // If the game was deleted (result is true), refresh the list
      if (result == true && mounted) {
        await _loadGames();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          title:
              _isSelectionMode
                  ? Text('${_selectedGameIds.length} selected')
                  : const Text('Game History'),
          leading:
              _isSelectionMode
                  ? IconButton(
                    icon: const Icon(Icons.close_outlined),
                    onPressed: _exitSelectionMode,
                  )
                  : Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Menu',
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                  ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed:
                    _selectedGameIds.isNotEmpty ? _deleteSelectedGames : null,
              ),
          ],
        ),
        drawer: const AppDrawer(currentRoute: 'game_history'),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gameSummaries.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No games yet',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Games are automatically saved when you start scoring',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadGames,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        _gameSummaries.length +
                        (_hasMoreGames || _isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the bottom
                      if (index == _gameSummaries.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final gameSummary = _gameSummaries[index];
                      return GameSummaryCard(
                        gameSummary: gameSummary,
                        isSelectionMode: _isSelectionMode,
                        isSelected: _selectedGameIds.contains(gameSummary.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleGameSelection(gameSummary.id);
                          } else {
                            _showGameDetails(gameSummary.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(gameSummary.id);
                          }
                        },
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
