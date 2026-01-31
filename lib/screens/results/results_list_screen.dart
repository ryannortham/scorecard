// results list screen with selection mode support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/mixins/selection_mixin.dart';
import 'package:scorecard/repositories/game_repository.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/viewmodels/results_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/common/tab_root_app_bar.dart';
import 'package:scorecard/widgets/navigation/tab_root_wrapper.dart';
import 'package:scorecard/widgets/results/results_summary_card.dart';

class ResultsListScreen extends StatefulWidget {
  const ResultsListScreen({super.key});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen>
    with SelectionMixin<String, ResultsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Sync exclude game ID with the ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncExcludeGameId();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncExcludeGameId() {
    final gameVm = context.read<GameViewModel>();
    context.read<ResultsViewModel>().excludeGameId = gameVm.currentGameId;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(context.read<ResultsViewModel>().loadMore());
    }
  }

  Future<void> _refreshGames() async {
    _syncExcludeGameId();
    await context.read<ResultsViewModel>().refresh();
  }

  Future<void> _deleteSelectedGames() async {
    if (!hasSelection) return;

    final count = selectedCount;
    final confirmText = count == 1 ? 'Delete Game?' : 'Delete $count Games?';
    final gameRepository = context.read<GameRepository>();

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
          await gameRepository.deleteGame(gameId);
        }

        // Remove games from cache and exit selection mode
        if (mounted) {
          context.read<ResultsViewModel>().removeGames(gameIdsToDelete);
        }
        exitSelectionMode();

        if (mounted) {
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
    final gameRepository = context.read<GameRepository>();
    final game = await gameRepository.loadGameById(gameId);
    if (game != null && mounted) {
      final result = await context.push<bool>('/results/$gameId', extra: game);

      // If the game was deleted (result is true), remove from cache
      if ((result ?? false) && mounted) {
        context.read<ResultsViewModel>().removeGame(gameId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AppScaffold(
      extendBody: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            if (isSelectionMode)
              StyledSliverAppBar.selectionMode(
                selectedCount: selectedCount,
                onClose: exitSelectionMode,
                onDelete: hasSelection ? _deleteSelectedGames : null,
              )
            else
              // Tab root - automatic back button based on tab history
              const TabRootAppBar(
                title: Text('Results'),
                actions: [AppMenu(currentRoute: 'results')],
              ),
          ];
        },
        body: Consumer<ResultsViewModel>(
          builder: (context, resultsVm, child) {
            return RefreshIndicator(
              onRefresh: _refreshGames,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Main content
                  if (!resultsVm.loaded)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (resultsVm.summaries.isEmpty)
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
                    // Use Consumer2 once at the list level to pre-fetch team
                    // and preference data, avoiding individual Consumer calls
                    // in each ResultsSummaryCard which would cause all cards
                    // to rebuild when any team or preference changes.
                    Consumer2<TeamsViewModel, PreferencesViewModel>(
                      builder: (context, teamsProvider, prefsProvider, child) {
                        // Pre-compute a lookup map for team logos (O(1) lookup)
                        final teamLogoMap = <String, String>{
                          for (final team in teamsProvider.teams)
                            team.name: team.logoUrl ?? '',
                        };
                        final favoriteTeams = prefsProvider.favoriteTeams;
                        final summaries = resultsVm.summaries;

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final gameSummary = summaries[index];

                              // Pre-fetch team logos and trophy visibility
                              final homeLogoUrl =
                                  teamLogoMap[gameSummary.homeTeam] ?? '';
                              final awayLogoUrl =
                                  teamLogoMap[gameSummary.awayTeam] ?? '';
                              final shouldShowTrophy =
                                  ResultsSummaryCard.computeShouldShowTrophy(
                                    gameSummary,
                                    favoriteTeams,
                                  );

                              return ResultsSummaryCard(
                                gameSummary: gameSummary,
                                isSelectionMode: isSelectionMode,
                                isSelected: isSelected(gameSummary.id),
                                homeTeamLogoUrl: homeLogoUrl,
                                awayTeamLogoUrl: awayLogoUrl,
                                shouldShowTrophy: shouldShowTrophy,
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
                            childCount: summaries.length,
                          ),
                        );
                      },
                    ),

                  // Loading indicator at the bottom (separate sliver)
                  if (resultsVm.hasMoreGames || resultsVm.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
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
            );
          },
        ),
      ),
    );

    // Wrap with TabRootWrapper to ensure Android's predictive back gesture
    // is properly intercepted and delegated to the NavigationShell's tab
    // history navigation.
    return TabRootWrapper(
      isInSelectionMode: isSelectionMode,
      onExitSelectionMode: exitSelectionMode,
      child: body,
    );
  }
}
