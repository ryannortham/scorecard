// team list screen with selection mode support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/constants/hero_tags.dart';
import 'package:scorecard/mixins/selection_mixin.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/common/tab_root_app_bar.dart';
import 'package:scorecard/widgets/navigation/tab_root_wrapper.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({
    required this.title,
    this.excludeTeam,
    super.key,
  });

  final String title;
  final String? excludeTeam;

  /// Whether this screen is being used as a team selector
  /// (not the main Teams tab)
  bool get isSelectionScreen => title != 'Teams';

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen>
    with SelectionMixin<int, TeamListScreen> {
  bool _hasNavigatedToAddTeam = false;
  bool _hasInitiallyLoaded = false;

  @override
  void initState() {
    super.initState();
    // Check for empty teams list after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForEmptyTeamsList());
    });
  }

  Future<void> _checkForEmptyTeamsList() async {
    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);
    final filteredTeams =
        teamsProvider.teams
            .where((team) => team.name != widget.excludeTeam)
            .toList();

    // Only auto-navigate if:
    // 1. Teams are loaded
    // 2. Either the full teams list is empty (for Teams) OR the filtered
    //    teams list is empty (for team selection)
    // 3. We haven't already navigated
    // 4. This is the initial load (not after user deletions)
    final shouldAutoNavigate =
        teamsProvider.loaded &&
        !_hasNavigatedToAddTeam &&
        !_hasInitiallyLoaded &&
        ((!widget.isSelectionScreen && teamsProvider.teams.isEmpty) ||
            (widget.isSelectionScreen && filteredTeams.isEmpty));

    if (shouldAutoNavigate) {
      _hasNavigatedToAddTeam = true;

      final addedTeamName = await context.push<String>('/team-add');

      // If a team was added and this is a team selection screen, auto-select it
      if (addedTeamName != null && widget.isSelectionScreen) {
        if (mounted) {
          context.pop(addedTeamName);
        }
      }
    }

    // Mark that we've completed initial loading AFTER checking for auto-nav
    if (teamsProvider.loaded && !_hasInitiallyLoaded) {
      _hasInitiallyLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsProvider = Provider.of<TeamsViewModel>(context);
    final userPreferences = Provider.of<PreferencesViewModel>(context);
    final teams =
        teamsProvider.teams
            .where((team) => team.name != widget.excludeTeam)
            .toList();

    // Check again when the provider updates (in case teams are loaded later)
    if (teamsProvider.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkForEmptyTeamsList());
      });
    }

    final body = AppScaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main content with collapsible app bar
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                if (isSelectionMode)
                  StyledSliverAppBar.selectionMode(
                    selectedCount: selectedCount,
                    onClose: exitSelectionMode,
                    onDelete: hasSelection ? _deleteSelectedTeams : null,
                  )
                else if (!widget.isSelectionScreen)
                  // Tab root - automatic back button based on tab history
                  TabRootAppBar(
                    title: Text(widget.title),
                    actions: const [AppMenu(currentRoute: 'teams')],
                  )
                else
                  // Modal team selector - show back button
                  StyledSliverAppBar.withBackButton(
                    title: Text(widget.title),
                    onBackPressed: _handleBackPress,
                    actions: const [AppMenu(currentRoute: 'teams')],
                  ),
              ];
            },
            body: CustomScrollView(
              slivers: [
                // Main content
                if (teamsProvider.loaded)
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 4,
                      right: 4,
                      top: 4,
                      bottom: 4.0 + MediaQuery.of(context).padding.bottom,
                    ),
                    sliver: SliverList.builder(
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final realIndex = teamsProvider.teams.indexOf(team);
                        final itemSelected = isSelected(realIndex);

                        return _TeamListItem(
                          team: team,
                          realIndex: realIndex,
                          itemSelected: itemSelected,
                          isSelectionMode: isSelectionMode,
                          isTeamsScreen: !widget.isSelectionScreen,
                          isFavorite: userPreferences.isFavoriteTeam(
                            team.name,
                          ),
                          onTap: () {
                            if (isSelectionMode) {
                              toggleSelection(realIndex);
                            } else if (widget.isSelectionScreen) {
                              // Team selection mode - select team and return
                              context.pop(team.name);
                            } else {
                              // Teams mode - navigate to team detail
                              _navigateToTeamDetail(team.name);
                            }
                          },
                          onLongPress: () {
                            if (!isSelectionMode && !widget.isSelectionScreen) {
                              enterSelectionMode(realIndex);
                            }
                          },
                          onFavoriteToggle: () async {
                            final wasAdded =
                                !userPreferences.isFavoriteTeam(team.name);
                            await userPreferences.toggleFavoriteTeam(
                              team.name,
                            );

                            if (mounted && context.mounted) {
                              SnackBarService.showSuccess(
                                context,
                                wasAdded
                                    ? 'Added to favourites'
                                    : 'Removed from favourites',
                              );
                            }
                          },
                        );
                      },
                    ),
                  )
                else
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Fixed position FAB
          Positioned(
            right: 16,
            bottom: 140, // Fixed position well above nav bar
            child: FloatingActionButton.extended(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              elevation: 0,
              heroTag: primaryActionFabHeroTag,
              onPressed: () async {
                final router = GoRouter.of(context);
                final addedTeamName = await router.push<String>('/team-add');
                if (!mounted) return;

                // If a team was added and this is team selection, auto-select
                if (addedTeamName != null && widget.isSelectionScreen) {
                  router.pop(addedTeamName);
                }
              },
              tooltip: 'Add Team',
              icon: const Icon(Icons.add_outlined),
              label: const Text('Add Team'),
            ),
          ),
        ],
      ),
    );

    // For modal selection screens (team-select route), allow standard back
    // navigation via go_router. These screens are pushed above the shell
    // with parentNavigatorKey: _rootNavigatorKey.
    if (widget.isSelectionScreen) {
      return body;
    }

    // For tab root screens, wrap with TabRootWrapper to ensure Android's
    // predictive back gesture is properly intercepted and delegated to
    // the NavigationShell's tab history navigation.
    return TabRootWrapper(
      isInSelectionMode: isSelectionMode,
      onExitSelectionMode: exitSelectionMode,
      child: body,
    );
  }

  Future<void> _deleteSelectedTeams() async {
    if (!hasSelection) return;

    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);
    final userPreferences = Provider.of<PreferencesViewModel>(
      context,
      listen: false,
    );

    final count = selectedCount;
    final confirmText = count == 1 ? 'Delete Team?' : 'Delete $count Teams?';

    final confirmed = await DialogService.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: confirmText,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        // Sort indices in descending order to delete from end to beginning
        // This prevents index shifting issues
        final sortedIndices =
            selectedItems.toList()..sort((a, b) => b.compareTo(a));

        // Check if any selected teams are favourite teams
        var needToClearFavorites = false;
        final favoritesToClear = <String>[];
        for (final index in sortedIndices) {
          if (index < teamsProvider.teams.length) {
            final team = teamsProvider.teams[index];
            if (userPreferences.isFavoriteTeam(team.name)) {
              needToClearFavorites = true;
              favoritesToClear.add(team.name);
            }
          }
        }

        // Clear favourite teams that are being deleted
        if (needToClearFavorites) {
          for (final teamName in favoritesToClear) {
            await userPreferences.removeFavoriteTeam(teamName);
          }
        }

        // Delete teams in reverse order
        for (final index in sortedIndices) {
          if (index < teamsProvider.teams.length) {
            await teamsProvider.deleteTeam(index);
          }
        }

        exitSelectionMode();

        if (mounted && context.mounted) {
          final count = sortedIndices.length;
          SnackBarService.showSuccess(
            context,
            count == 1
                ? 'Team deleted successfully'
                : '$count teams deleted successfully',
          );
        }
      } on Exception catch (e) {
        if (mounted && context.mounted) {
          SnackBarService.showError(context, 'Error deleting teams: $e');
        }
      }
    }
  }

  void _navigateToTeamDetail(String teamName) {
    unawaited(context.push('/team/${Uri.encodeComponent(teamName)}'));
  }

  /// handles back button press
  void _handleBackPress() {
    context.pop();
  }
}

/// team list item widget for sliver list builder
class _TeamListItem extends StatelessWidget {
  const _TeamListItem({
    required this.team,
    required this.realIndex,
    required this.itemSelected,
    required this.isSelectionMode,
    required this.isTeamsScreen,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteToggle,
  });

  final Team team;
  final int realIndex;
  final bool itemSelected;
  final bool isSelectionMode;
  final bool isTeamsScreen;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color:
          itemSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading:
            isSelectionMode
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      itemSelected
                          ? Icons.check_circle_outlined
                          : Icons.radio_button_unchecked_outlined,
                      color:
                          itemSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Hero(
                      tag: teamLogoHeroTag(team.name),
                      child: TeamLogo(logoUrl: team.logoUrl, size: 48),
                    ),
                  ],
                )
                : Hero(
                  tag: teamLogoHeroTag(team.name),
                  child: TeamLogo(logoUrl: team.logoUrl, size: 48),
                ),
        title: Text(team.name, style: Theme.of(context).textTheme.bodyMedium),
        onTap: onTap,
        onLongPress: onLongPress,
        trailing:
            isSelectionMode
                ? null
                : IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite
                        ? Icons.star_outlined
                        : Icons.star_border_outlined,
                    color:
                        isFavorite
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                  ),
                  tooltip:
                      isFavorite ? 'Remove from favorites' : 'Mark as favorite',
                  onPressed: onFavoriteToggle,
                ),
      ),
    );
  }
}
