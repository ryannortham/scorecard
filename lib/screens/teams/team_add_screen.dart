// team add screen with playhq search

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/string_extensions.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/playhq_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/teams/team_search_results.dart';

// search configuration constants
class _AddTeamConstants {
  static const int searchDelayMs = 1000;
  static const List<String> excludedWords = ['auskick', 'holiday', 'superkick'];
}

/// screen for adding teams from playhq search or custom entry
class TeamAddScreen extends StatefulWidget {
  const TeamAddScreen({super.key});

  @override
  State<TeamAddScreen> createState() => _TeamAddScreenState();
}

class _TeamAddScreenState extends State<TeamAddScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final SearchController _materialSearchController = SearchController();

  List<Organisation> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _materialSearchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final response = await PlayHQGraphQLService.searchAFLClubs(query.trim());

      setState(() {
        _isLoading = false;
        _searchResults = _filterSearchResults(response.results);
        _errorMessage = null;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
        _errorMessage = 'An error occurred while searching: $e';
      });
    }
  }

  /// filters search results to only include valid teams
  List<Organisation> _filterSearchResults(List<Organisation> results) {
    return results.where(_hasValidLogo).where(_isNotExcludedTeam).toList();
  }

  /// checks if team has a valid logo
  bool _hasValidLogo(Organisation team) {
    return (team.logoUrlLarge ?? team.logoUrl48)?.isNotEmpty ?? false;
  }

  /// checks if team is not in excluded list
  bool _isNotExcludedTeam(Organisation team) {
    final nameLower = team.name.toLowerCase();
    return !_AddTeamConstants.excludedWords.any(nameLower.contains);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            StyledSliverAppBar.withBackButton(
              title: const Text('Add Team'),
              onBackPressed: () {
                // Unfocus search bar before navigating back
                _searchFocusNode.unfocus();
                Navigator.of(context).pop();
              },
              actions: const [AppMenu(currentRoute: 'add_team')],
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(
                  TeamSearchConstants.paddingMedium,
                ),
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(
                        TeamSearchConstants.paddingMedium,
                      ),
                      child: SearchBarTheme(
                        data: const SearchBarThemeData(
                          elevation: WidgetStatePropertyAll(0),
                          side: WidgetStatePropertyAll(BorderSide.none),
                        ),
                        child: SearchBar(
                          controller: _materialSearchController,
                          focusNode: _searchFocusNode,
                          hintText: 'Enter team name',
                          leading: const Icon(Icons.search_outlined),
                          trailing:
                              _materialSearchController.text.isNotEmpty
                                  ? [
                                    IconButton(
                                      icon: const Icon(Icons.clear_outlined),
                                      onPressed: () {
                                        _materialSearchController.clear();
                                        unawaited(_performSearch(''));
                                      },
                                    ),
                                  ]
                                  : null,
                          onSubmitted: _performSearch,
                          onChanged: (value) {
                            setState(
                              () {},
                            ); // Rebuild to show/hide clear button

                            // Perform search after a short delay
                            Future.delayed(
                              const Duration(
                                milliseconds: _AddTeamConstants.searchDelayMs,
                              ),
                              () {
                                if (_materialSearchController.text == value) {
                                  unawaited(_performSearch(value));
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Button group for search and custom entry
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TeamSearchConstants.paddingMedium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              onPressed:
                                  _isLoading ||
                                          _materialSearchController.text
                                              .trim()
                                              .isEmpty
                                      ? null
                                      : () => _performSearch(
                                        _materialSearchController.text,
                                      ),
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        width:
                                            TeamSearchConstants.paddingMedium,
                                        height:
                                            TeamSearchConstants.paddingMedium,
                                        child: CircularProgressIndicator(
                                          strokeWidth:
                                              TeamSearchConstants
                                                  .circularProgressStrokeWidth,
                                        ),
                                      )
                                      : const Icon(Icons.search_outlined),
                              label: Text(
                                _isLoading ? 'Searching...' : 'Search',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: TeamSearchConstants.paddingMedium,
                          ),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed:
                                  _isLoading ? null : _showCustomEntryDialog,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text(
                                'Custom',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: TeamSearchConstants.paddingMedium),

                    // Results
                    TeamSearchResults(
                      hasSearched: _hasSearched,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      searchResults: _searchResults,
                      searchQuery: _materialSearchController.text,
                      onTeamTap: _addTeamToList,
                      onRetry:
                          () => _performSearch(_materialSearchController.text),
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

  /// gets the best available logo url from the team
  String? _getBestLogoUrl(Organisation team) {
    return team.logoUrlLarge ?? team.logoUrl48;
  }

  /// adds team to the list, handling duplicates with edit dialog
  Future<void> _addTeamToList(Organisation team) async {
    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);
    final processedName = team.name.toProcessedTeamName();

    // Check if team already exists
    final existingTeam = teamsProvider.findTeamByName(processedName);

    if (existingTeam != null) {
      // Show edit dialog for existing team, passing the logo info from search
      await _showEditTeamDialog(existingTeam.name, team);
    } else {
      // Add new team directly, fetching address details
      await _addTeamWithAddressDetails(processedName, team);
    }
  }

  /// fetches address details from playhq and adds team
  Future<void> _addTeamWithAddressDetails(
    String teamName,
    Organisation org,
  ) async {
    try {
      // Show loading indicator
      if (mounted) {
        SnackBarService.showLoading(context, 'Fetching team details...');
      }

      // Fetch detailed organization information including address
      final orgResponse = await PlayHQGraphQLService.getOrganisationDetails(
        org.routingCode,
      );

      final address = orgResponse.organisation?.address;

      // Add team with address information
      await _addTeamAndFinish(
        teamName,
        logoUrl: _getBestLogoUrl(org),
        logoUrl32: org.logoUrl32,
        logoUrl48: org.logoUrl48,
        logoUrlLarge: org.logoUrlLarge,
        address: address,
        playHQId: org.id,
        routingCode: org.routingCode,
      );
    } on Exception catch (e) {
      // If address fetch fails, still add the team without address
      if (mounted) {
        SnackBarService.showInfo(
          context,
          'Could not fetch address details, but team was added: $e',
          duration: const Duration(seconds: 3),
        );
      }

      await _addTeamAndFinish(
        teamName,
        logoUrl: _getBestLogoUrl(org),
        logoUrl32: org.logoUrl32,
        logoUrl48: org.logoUrl48,
        logoUrlLarge: org.logoUrlLarge,
        playHQId: org.id,
        routingCode: org.routingCode,
      );
    }
  }

  /// adds team and handles success flow
  Future<void> _addTeamAndFinish(
    String teamName, {
    String? logoUrl,
    String? logoUrl32,
    String? logoUrl48,
    String? logoUrlLarge,
    Address? address,
    String? playHQId,
    String? routingCode,
  }) async {
    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);
    final navigator = Navigator.of(context);

    await teamsProvider.addTeam(
      teamName,
      logoUrl: logoUrl,
      logoUrl32: logoUrl32,
      logoUrl48: logoUrl48,
      logoUrlLarge: logoUrlLarge,
      address: address,
      playHQId: playHQId,
      routingCode: routingCode,
    );

    if (mounted) {
      SnackBarService.showSuccess(context, 'Added "$teamName" to your teams');

      // Return the team name so it can be auto-selected
      navigator.pop(teamName);
    }
  }

  /// shows dialog for creating a new team with custom name
  Future<void> _showEditTeamDialog(
    String currentName,
    Organisation originalTeam,
  ) async {
    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);

    final result = await DialogService.showTeamNameDialog(
      context: context,
      title: 'Add Team',
      initialValue: currentName,
      hasTeamWithName: teamsProvider.hasTeamWithName,
      confirmText: 'Add Team',
    );

    if (result != null) {
      // Always create a new team (never modify existing) with logo from search
      await _addTeamAndFinish(
        result,
        logoUrl: _getBestLogoUrl(originalTeam),
        logoUrl32: originalTeam.logoUrl32,
        logoUrl48: originalTeam.logoUrl48,
        logoUrlLarge: originalTeam.logoUrlLarge,
      );
    }
  }

  /// shows dialog for custom team entry
  Future<void> _showCustomEntryDialog() async {
    final teamsProvider = Provider.of<TeamsViewModel>(context, listen: false);

    final result = await DialogService.showTeamNameDialog(
      context: context,
      title: 'Add Custom Team',
      initialValue: null,
      hasTeamWithName: teamsProvider.hasTeamWithName,
      confirmText: 'Add Team',
      description: 'Enter a custom team name:',
    );

    if (result != null) {
      // Add the custom team (no logo for custom teams)
      await _addTeamAndFinish(result);
    }
  }
}
