// results list screen with selection mode support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/context_extensions.dart';
import 'package:scorecard/mixins/selection_controller.dart';
import 'package:scorecard/screens/results/results_screen.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/results_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/dialog_service.dart';
import 'package:scorecard/widgets/common/sliver_app_bar.dart';
import 'package:scorecard/widgets/results/results_summary_card.dart';

class ResultsListScreen extends StatefulWidget {
  const ResultsListScreen({super.key});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen>
    with SelectionController<String, ResultsListScreen> {
  List<GameSummary> _gameSummaries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreGames = true;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadGames());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// handles back button press
  void _handleBackPress() {
    context.handleBackPress();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMoreGames());
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
      final gameStateService = context.read<GameStateService>();

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
    } on Exception catch (e) {
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
          SnackBarService.showError(context, 'Error loading games: $e');
        }
      }
    }
  }

  Future<void> _deleteSelectedGames() async {
    if (!hasSelection) return;

    final count = selectedCount;
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
        final gameIdsToDelete = List<String>.from(selectedItems);
        for (final gameId in gameIdsToDelete) {
          await ResultsService.deleteGame(gameId);
        }

        exitSelectionMode();
        await _loadGames(); // Refresh the list

        if (mounted && context.mounted) {
          final count = gameIdsToDelete.length;
          SnackBarService.showSuccess(
            context,
            count == 1
                ? 'Game deleted successfully'
                : '$count games deleted successfully',
          );
        }
      } on Exception catch (e) {
        AppLogger.error(
          'Failed to delete games from results',
          error: e,
          component: 'GameResults',
        );

        if (mounted && context.mounted) {
          SnackBarService.showError(context, 'Error deleting games: $e');
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
      if ((result ?? false) && mounted) {
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

        if (isSelectionMode) {
          exitSelectionMode();
        } else {
          _handleBackPress(); // Use the same logic as UI back button
        }
      },
      child: AppScaffold(
        extendBody: true,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              if (isSelectionMode)
                AppSliverAppBar.selectionMode(
                  selectedCount: selectedCount,
                  onClose: exitSelectionMode,
                  onDelete: hasSelection ? _deleteSelectedGames : null,
                )
              else
                AppSliverAppBar.withBackButton(
                  title: const Text('Results'),
                  onBackPressed: _handleBackPress,
                  actions: const [AppMenu(currentRoute: 'results')],
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Games are automatically saved when you '
                            'start scoring',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final gameSummary = _gameSummaries[index];
                        return ResultsSummaryCard(
                          gameSummary: gameSummary,
                          isSelectionMode: isSelectionMode,
                          isSelected: isSelected(gameSummary.id),
                          onTap: () {
                            if (isSelectionMode) {
                              toggleSelection(gameSummary.id);
                            } else {
                              unawaited(_showGameDetails(gameSummary.id));
                            }
                          },
                          onLongPress: () {
                            if (!isSelectionMode) {
                              enterSelectionMode(gameSummary.id);
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
      ),
    );
  }
}
