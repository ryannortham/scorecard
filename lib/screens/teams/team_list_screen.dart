// team list screen with selection mode support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/context_extensions.dart';
import 'package:scorecard/mixins/selection_controller.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/screens/teams/team_add_screen.dart';
import 'package:scorecard/screens/teams/team_detail_screen.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/dialog_service.dart';
import 'package:scorecard/widgets/common/sliver_app_bar.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({
    required this.title,
    required this.onTeamSelected,
    super.key,
  });
  final String title;
  final void Function(String) onTeamSelected;

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen>
    with SelectionController<int, TeamListScreen> {
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
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final teamToExclude = ModalRoute.of(context)?.settings.arguments as String?;
    final filteredTeams =
        teamsProvider.teams
            .where((team) => team.name != teamToExclude)
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
        ((widget.title == 'Teams' && teamsProvider.teams.isEmpty) ||
            (widget.title != 'Teams' && filteredTeams.isEmpty));

    if (shouldAutoNavigate) {
      _hasNavigatedToAddTeam = true;

      final addedTeamName = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const TeamAddScreen()),
      );

      // If a team was added and this is a team selection screen, auto-select it
      if (addedTeamName != null && widget.title != 'Teams') {
        widget.onTeamSelected(addedTeamName);
        if (mounted) {
          Navigator.of(context).pop(addedTeamName);
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
    final teamsProvider = Provider.of<TeamsProvider>(context);
    final userPreferences = Provider.of<UserPreferencesProvider>(context);
    final teamToExclude = ModalRoute.of(context)?.settings.arguments as String?;
    final teams =
        teamsProvider.teams
            .where((team) => team.name != teamToExclude)
            .toList();

    // Check again when the provider updates (in case teams are loaded later)
    if (teamsProvider.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkForEmptyTeamsList());
      });
    }

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
        body: Stack(
          children: [
            // Main content with collapsible app bar
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  if (isSelectionMode)
                    AppSliverAppBar.selectionMode(
                      selectedCount: selectedCount,
                      onClose: exitSelectionMode,
                      onDelete: hasSelection ? _deleteSelectedTeams : null,
                    )
                  else
                    AppSliverAppBar.withBackButton(
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
                            isTeamsScreen: widget.title == 'Teams',
                            isFavorite: userPreferences.isFavoriteTeam(
                              team.name,
                            ),
                            onTap: () {
                              if (isSelectionMode) {
                                toggleSelection(realIndex);
                              } else if (widget.title != 'Teams') {
                                // Team selection mode - select team and return
                                widget.onTeamSelected(team.name);
                                Navigator.pop(context, team.name);
                              } else {
                                // Teams mode - navigate to team detail
                                _navigateToTeamDetail(team.name);
                              }
                            },
                            onLongPress: () {
                              if (!isSelectionMode && widget.title == 'Teams') {
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
                heroTag: 'add_team_fab',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final addedTeamName = await navigator.push<String>(
                    MaterialPageRoute(
                      builder: (context) => const TeamAddScreen(),
                    ),
                  );

                  // If a team was added and this is team selection, auto-select
                  if (addedTeamName != null && widget.title != 'Teams') {
                    widget.onTeamSelected(addedTeamName);
                    if (mounted) {
                      navigator.pop(
                        addedTeamName,
                      ); // Return the team name when popping
                    }
                  }
                },
                tooltip: 'Add Team',
                icon: const Icon(Icons.add_outlined),
                label: const Text('Add Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelectedTeams() async {
    if (!hasSelection) return;

    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final userPreferences = Provider.of<UserPreferencesProvider>(
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
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => TeamDetailScreen(teamName: teamName),
        ),
      ),
    );
  }

  /// handles back button press
  void _handleBackPress() {
    context.handleBackPress();
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
      color: itemSelected ? colorScheme.primaryContainer : colorScheme.surface,
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
                    TeamLogo(logoUrl: team.logoUrl, size: 48),
                  ],
                )
                : TeamLogo(logoUrl: team.logoUrl, size: 48),
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
