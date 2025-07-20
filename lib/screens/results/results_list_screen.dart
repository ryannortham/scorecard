import 'package:flutter/material.dart';
import '../../services/app_logger.dart';
import '../../services/dialog_service.dart';
import '../../services/results_service.dart';
import '../../services/game_state_service.dart';
import '../../widgets/results/results_summary_card.dart';
import '../../widgets/menu/app_menu.dart';

import 'results_screen.dart';
import '../../services/color_service.dart';

class ResultsListScreen extends StatefulWidget {
  const ResultsListScreen({super.key});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
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

  /// Handles back button press by trying to pop or navigating to Scoring tab
  void _handleBackPress() {
    // Try to pop first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, we're in a NavigationShell tab context
      // Navigate to the Scoring tab (index 0) as the default "back" behavior
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Determines if the back button should be shown.
  /// Returns true - we always want to show the back button, but handle it appropriately
  bool _shouldShowBackButton() {
    // Always show the back button - let _handleBackPress decide what to do
    return true;
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

      final newSummaries = await ResultsService.loadGameSummaries(
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
        component: 'GameResults',
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
              backgroundColor: context.colors.error,
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

    final count = _selectedGameIds.length;
    final confirmText = count == 1 ? 'Delete Game?' : 'Delete $count Games?';

    final shouldDelete = await DialogService.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: confirmText,
      isDestructive: true,
    );

    if (shouldDelete) {
      try {
        // Delete all selected games
        final gameIdsToDelete = List<String>.from(_selectedGameIds);
        for (final gameId in gameIdsToDelete) {
          await ResultsService.deleteGame(gameId);
        }

        _exitSelectionMode();
        await _loadGames(); // Refresh the list

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${gameIdsToDelete.length} games deleted successfully',
              ),
              backgroundColor: context.colors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        AppLogger.error(
          'Failed to delete games from results',
          error: e,
          component: 'GameResults',
        );

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting games: $e'),
              backgroundColor: context.colors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _showGameDetails(String gameId) async {
    // Load the full game data only when needed
    final game = await ResultsService.loadGameById(gameId);
    if (game != null && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => ResultsScreen(game: game)),
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
      canPop: false, // We'll handle all pop attempts manually
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Already handled

        if (_isSelectionMode) {
          _exitSelectionMode();
        } else {
          _handleBackPress(); // Use the same logic as UI back button
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.12, 0.25, 0.5],
                    colors: [
                      context.colors.primaryContainer,
                      context.colors.primaryContainer,
                      ColorService.withAlpha(
                        context.colors.primaryContainer,
                        0.9,
                      ),
                      context.colors.surface,
                    ],
                  ),
                ),
              ),
            ),

            // Main content with collapsible app bar
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: context.colors.primaryContainer,
                    foregroundColor: context.colors.onPrimaryContainer,
                    floating: true,
                    snap: true,
                    pinned: false,
                    elevation: 0,
                    shadowColor: ColorService.transparent,
                    surfaceTintColor: ColorService.transparent,
                    title:
                        _isSelectionMode
                            ? Text('${_selectedGameIds.length} selected')
                            : const Text('Results'),
                    leading:
                        _isSelectionMode
                            ? IconButton(
                              icon: const Icon(Icons.close_outlined),
                              onPressed: _exitSelectionMode,
                            )
                            : _shouldShowBackButton()
                            ? IconButton(
                              icon: const Icon(Icons.arrow_back_outlined),
                              tooltip: 'Back',
                              onPressed: _handleBackPress,
                            )
                            : null,
                    actions: [
                      if (_isSelectionMode)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              _selectedGameIds.isNotEmpty
                                  ? _deleteSelectedGames
                                  : null,
                        )
                      else
                        const AppMenu(currentRoute: 'results'),
                    ],
                  ),
                ];
              },
              body: RefreshIndicator(
                onRefresh: _loadGames,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Main content
                    if (_isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_gameSummaries.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag_outlined,
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
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Games are automatically saved when you start scoring',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Show loading indicator at the bottom
                            if (index == _gameSummaries.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final gameSummary = _gameSummaries[index];
                            return ResultsSummaryCard(
                              gameSummary: gameSummary,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedGameIds.contains(
                                gameSummary.id,
                              ),
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
                          childCount:
                              _gameSummaries.length +
                              (_hasMoreGames || _isLoadingMore ? 1 : 0),
                        ),
                      ),

                    // Add bottom padding for system navigation bar
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
