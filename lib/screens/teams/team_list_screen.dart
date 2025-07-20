import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/score_models.dart';
import '../../providers/teams_provider.dart';
import '../../services/color_service.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/navigation_service.dart';
import '../../services/dialog_service.dart';
import 'team_add_screen.dart';
import '../../widgets/menu/app_menu.dart';

import '../../services/asset_icon_service.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({
    super.key,
    required this.title,
    required this.onTeamSelected,
  });
  final String title;
  final void Function(String) onTeamSelected;

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  bool _hasNavigatedToAddTeam = false;
  bool _hasInitiallyLoaded = false; // Track if we've completed initial load

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<int> _selectedTeamIndices = {};

  @override
  void initState() {
    super.initState();
    // Check for empty teams list after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForEmptyTeamsList();
    });
  }

  void _checkForEmptyTeamsList() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final teamToExclude = ModalRoute.of(context)?.settings.arguments as String?;
    final filteredTeams =
        teamsProvider.teams
            .where((team) => team.name != teamToExclude)
            .toList();

    // Only auto-navigate if:
    // 1. Teams are loaded
    // 2. Either the full teams list is empty (for Teams) OR the filtered teams list is empty (for team selection)
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

    // Mark that we've completed initial loading AFTER checking for auto-navigation
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
        _checkForEmptyTeamsList();
      });
    }

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
            // Main content stack (background + NestedScrollView)
            Stack(
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
                                ? Text(
                                  '${_selectedTeamIndices.length} selected',
                                )
                                : Text(widget.title),
                        leading:
                            _isSelectionMode
                                ? IconButton(
                                  icon: const Icon(Icons.close_outlined),
                                  onPressed: _exitSelectionMode,
                                )
                                : IconButton(
                                  icon: const Icon(Icons.arrow_back_outlined),
                                  tooltip: 'Back',
                                  onPressed: _handleBackPress,
                                ),
                        actions: [
                          if (_isSelectionMode)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed:
                                  _selectedTeamIndices.isNotEmpty
                                      ? _deleteSelectedTeams
                                      : null,
                            )
                          else
                            const AppMenu(currentRoute: 'teams'),
                        ],
                      ),
                    ];
                  },
                  body: CustomScrollView(
                    slivers: [
                      // Main content
                      if (teamsProvider.loaded)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 4.0,
                              right: 4.0,
                              top: 4.0,
                              bottom:
                                  4.0 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Column(
                              children: List.generate(teams.length, (index) {
                                final team = teams[index];
                                final realIndex = teamsProvider.teams.indexOf(
                                  team,
                                );
                                final isSelected = _selectedTeamIndices
                                    .contains(realIndex);

                                return Card(
                                  elevation: 0,
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                          : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainer,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 4.0,
                                    ),
                                    leading:
                                        _isSelectionMode
                                            ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isSelected
                                                      ? Icons
                                                          .check_circle_outlined
                                                      : Icons
                                                          .radio_button_unchecked_outlined,
                                                  color:
                                                      isSelected
                                                          ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                          : Theme.of(
                                                            context,
                                                          ).colorScheme.outline,
                                                ),
                                                const SizedBox(width: 8.0),
                                                _buildTeamLogo(team),
                                              ],
                                            )
                                            : _buildTeamLogo(team),
                                    title: Text(
                                      team.name,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleTeamSelection(realIndex);
                                      } else if (widget.title != 'Teams') {
                                        // Only navigate if we're in team selection mode (not Teams)
                                        widget.onTeamSelected(team.name);
                                        Navigator.pop(context, team.name);
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode &&
                                          widget.title == 'Teams') {
                                        _enterSelectionMode(realIndex);
                                      }
                                    },
                                    trailing:
                                        _isSelectionMode
                                            ? null
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: Icon(
                                                    userPreferences
                                                                .favoriteTeam ==
                                                            team.name
                                                        ? Icons.star_outlined
                                                        : Icons
                                                            .star_border_outlined,
                                                    color:
                                                        userPreferences
                                                                    .favoriteTeam ==
                                                                team.name
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                  ),
                                                  tooltip:
                                                      userPreferences
                                                                  .favoriteTeam ==
                                                              team.name
                                                          ? 'Remove from favorites'
                                                          : 'Mark as favorite',
                                                  onPressed: () {
                                                    if (userPreferences
                                                            .favoriteTeam ==
                                                        team.name) {
                                                      userPreferences
                                                          .setFavoriteTeam('');
                                                    } else {
                                                      userPreferences
                                                          .setFavoriteTeam(
                                                            team.name,
                                                          );
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                  tooltip: 'Edit',
                                                  onPressed:
                                                      () => _showEditTeamDialog(
                                                        context,
                                                        teamsProvider,
                                                        realIndex,
                                                        team,
                                                      ),
                                                ),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  tooltip: 'Delete',
                                                  onPressed:
                                                      () =>
                                                          _showDeleteTeamConfirmation(
                                                            context,
                                                            teamsProvider,
                                                            realIndex,
                                                            team.name,
                                                          ),
                                                ),
                                              ],
                                            ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        )
                      else
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Fixed position FAB
            Positioned(
              right: 16.0,
              bottom: 140.0, // Fixed position well above nav bar
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final addedTeamName = await navigator.push<String>(
                    MaterialPageRoute(
                      builder: (context) => const TeamAddScreen(),
                    ),
                  );

                  // If a team was added and this is a team selection screen, auto-select it
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

  Widget _buildTeamLogo(Team team) {
    final logoUrl = team.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    return Builder(
      builder:
          (context) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: FootballIcon(
              size: 28,
              color: context.colors.onPrimaryContainer,
            ),
          ),
    );
  }

  Future<void> _showEditTeamDialog(
    BuildContext context,
    TeamsProvider teamsProvider,
    int index,
    Team currentTeam,
  ) async {
    final result = await DialogService.showTeamNameDialog(
      context: context,
      title: 'Edit Team Name',
      initialValue: currentTeam.name,
      hasTeamWithName: teamsProvider.hasTeamWithName,
      currentTeamName: currentTeam.name,
      confirmText: 'Save',
      cancelText: 'Cancel',
    );

    if (result != null && result != currentTeam.name) {
      await teamsProvider.editTeam(index, result, logoUrl: currentTeam.logoUrl);
    }
  }

  Future<void> _showDeleteTeamConfirmation(
    BuildContext context,
    TeamsProvider teamsProvider,
    int index,
    String teamName,
  ) async {
    final userPreferences = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );

    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: 'Delete Team?',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      // If deleting the favorite team, clear the favorite
      if (userPreferences.favoriteTeam == teamName) {
        await userPreferences.setFavoriteTeam('');
      }

      await teamsProvider.deleteTeam(index);
      // Stay on the team list after deletion - don't navigate back
    }
  }

  void _enterSelectionMode(int teamIndex) {
    setState(() {
      _isSelectionMode = true;
      _selectedTeamIndices.add(teamIndex);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTeamIndices.clear();
    });
  }

  void _toggleTeamSelection(int teamIndex) {
    setState(() {
      if (_selectedTeamIndices.contains(teamIndex)) {
        _selectedTeamIndices.remove(teamIndex);
        if (_selectedTeamIndices.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedTeamIndices.add(teamIndex);
      }
    });
  }

  Future<void> _deleteSelectedTeams() async {
    if (_selectedTeamIndices.isEmpty) return;

    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final userPreferences = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );

    final count = _selectedTeamIndices.length;
    final confirmText = count == 1 ? 'Delete Team?' : 'Delete $count Teams?';

    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: confirmText,
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        // Sort indices in descending order to delete from end to beginning
        // This prevents index shifting issues
        final sortedIndices =
            _selectedTeamIndices.toList()..sort((a, b) => b.compareTo(a));

        // Check if any selected teams are the favorite team
        bool needToClearFavorite = false;
        for (final index in sortedIndices) {
          if (index < teamsProvider.teams.length) {
            final team = teamsProvider.teams[index];
            if (userPreferences.favoriteTeam == team.name) {
              needToClearFavorite = true;
              break;
            }
          }
        }

        // Clear favorite team if it's being deleted
        if (needToClearFavorite) {
          await userPreferences.setFavoriteTeam('');
        }

        // Delete teams in reverse order
        for (final index in sortedIndices) {
          if (index < teamsProvider.teams.length) {
            await teamsProvider.deleteTeam(index);
          }
        }

        _exitSelectionMode();

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${sortedIndices.length} teams deleted successfully',
              ),
              backgroundColor: context.colors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting teams: $e'),
              backgroundColor: context.colors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Handles back button press by trying to pop or navigating to Scoring tab
  void _handleBackPress() {
    // Only try to pop if we can actually pop safely
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, we're in a NavigationShell tab context
      // Navigate to the Scoring tab (index 0) as the default "back" behavior
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}
