import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/playhq_models.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/playhq_graphql_service.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/widgets/drawer/app_drawer.dart';

import '../widgets/football_icon.dart';

/// Constants for the AddTeamScreen
class _AddTeamConstants {
  // Search configuration
  static const int searchLimit = 20;
  static const int searchDelayMs = 1000;

  // UI dimensions
  static const double logoSize = 48.0;
  static const double defaultLogoIconSize = 28.0;
  static const double largeIconSize = 64.0;
  static const double circularProgressStrokeWidth = 2.0;

  // Spacing
  static const double paddingSmall = 4.0;
  static const double paddingMedium = 8.0;

  // Team filtering
  static const List<String> excludedWords = ['auskick', 'holiday', 'superkick'];
}

/// Helper class for processing team names
class _TeamNameProcessor {
  // Single optimized regex pattern that captures all variations
  static final RegExp _teamNameRegex = RegExp(
    r'\([^)]*\)|' // Remove brackets and content
    r'(?:Junior\s+Football\s+Club|Junior\s+FC)\b|' // Junior variations
    r'Football\s+.*?Netball\s+Club\b|' // Football Netball variations
    r'Football\s+Club\b', // Football Club
    caseSensitive: false,
  );

  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Process a team name according to the specified rules
  static String processTeamName(String name) {
    // Single pass replacement with callback function
    String processed = name.replaceAllMapped(_teamNameRegex, (match) {
      final matchText = match.group(0)!.toLowerCase();

      // Remove bracketed content
      if (matchText.startsWith('(')) return '';

      // Convert Junior variations to JFC
      if (matchText.contains('junior')) return 'JFC';

      // Convert Football Netball variations to FNC
      if (matchText.contains('netball')) return 'FNC';

      // Convert Football Club to FC
      if (matchText.contains('football') && matchText.contains('club')) {
        return 'FC';
      }

      return match.group(0)!; // Fallback (shouldn't happen)
    });

    // Normalize whitespace and trim
    return processed.replaceAll(_whitespaceRegex, ' ').trim();
  }
}

/// Screen for adding teams from PlayHQ search or custom entry
class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
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
      final response = await PlayHQGraphQLService.searchAFLClubs(
        query: query.trim(),
        limit: _AddTeamConstants.searchLimit,
      );

      setState(() {
        _isLoading = false;
        if (response != null) {
          _searchResults = _filterSearchResults(response.results);
          _errorMessage = null;
        } else {
          _searchResults = [];
          _errorMessage = 'Failed to search teams. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
        _errorMessage = 'An error occurred while searching: $e';
      });
    }
  }

  /// Filter search results to only include valid teams
  List<Organisation> _filterSearchResults(List<Organisation> results) {
    return results.where(_hasValidLogo).where(_isNotExcludedTeam).toList();
  }

  /// Check if team has a valid logo
  bool _hasValidLogo(Organisation team) {
    return (team.logoUrlLarge ?? team.logoUrl48)?.isNotEmpty ?? false;
  }

  /// Check if team is not in excluded list
  bool _isNotExcludedTeam(Organisation team) {
    final nameLower = team.name.toLowerCase();
    return !_AddTeamConstants.excludedWords.any(
      (word) => nameLower.contains(word),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      endDrawer: const AppDrawer(currentRoute: 'add_team'),
      endDrawerEnableOpenDragGesture: false,
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
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer,
                    ColorService.withAlpha(colorScheme.primaryContainer, 0.9),
                    colorScheme.surface,
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
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  floating: true,
                  snap: true,
                  pinned: false,
                  elevation: 0,
                  shadowColor: ColorService.transparent,
                  surfaceTintColor: ColorService.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_outlined),
                    tooltip: 'Back',
                    onPressed: () {
                      // Unfocus search bar before navigating back
                      _searchFocusNode.unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                  title: const Text('Add Team'),
                  actions: [
                    Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(Icons.menu_outlined),
                            tooltip: 'Menu',
                            onPressed: () {
                              // Unfocus search bar before opening drawer to prevent potential conflicts
                              _searchFocusNode.unfocus();
                              Scaffold.of(context).openEndDrawer();
                            },
                          ),
                    ),
                  ],
                ),
              ];
            },
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      _AddTeamConstants.paddingMedium,
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(
                            _AddTeamConstants.paddingMedium,
                          ),
                          child: SearchBarTheme(
                            data: SearchBarThemeData(
                              elevation: const WidgetStatePropertyAll(0),
                              side: const WidgetStatePropertyAll(
                                BorderSide.none,
                              ),
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
                                          icon: const Icon(
                                            Icons.clear_outlined,
                                          ),
                                          onPressed: () {
                                            _materialSearchController.clear();
                                            _performSearch('');
                                          },
                                        ),
                                      ]
                                      : null,
                              onSubmitted: _performSearch,
                              onChanged: (value) {
                                setState(
                                  () {},
                                ); // Rebuild to show/hide clear button

                                // Perform search after a short delay to avoid too many requests
                                Future.delayed(
                                  const Duration(
                                    milliseconds:
                                        _AddTeamConstants.searchDelayMs,
                                  ),
                                  () {
                                    if (_materialSearchController.text ==
                                        value) {
                                      _performSearch(value);
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
                            horizontal: _AddTeamConstants.paddingMedium,
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
                                                _AddTeamConstants.paddingMedium,
                                            height:
                                                _AddTeamConstants.paddingMedium,
                                            child: CircularProgressIndicator(
                                              strokeWidth:
                                                  _AddTeamConstants
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
                                width: _AddTeamConstants.paddingMedium,
                              ),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : _showCustomEntryDialog,
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

                        const SizedBox(height: _AddTeamConstants.paddingMedium),

                        // Results
                        _buildResultsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: _AddTeamConstants.largeIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: _AddTeamConstants.paddingMedium),
            Text('Searching teams...', style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: _AddTeamConstants.largeIconSize,
              color: colorScheme.error,
            ),
            const SizedBox(height: _AddTeamConstants.paddingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _AddTeamConstants.paddingMedium,
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
            ),
            const SizedBox(height: _AddTeamConstants.paddingMedium),
            ElevatedButton(
              onPressed: () => _performSearch(_materialSearchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FootballIcon(
              size: _AddTeamConstants.largeIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: _AddTeamConstants.paddingMedium),
            Text(
              'No teams found for "${_materialSearchController.text}"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: _AddTeamConstants.paddingSmall),
            Text(
              'Try a different search term',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(_AddTeamConstants.paddingMedium),
      itemCount: _searchResults.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final team = _searchResults[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(Organisation team) {
    final theme = Theme.of(context);
    final processedName = _TeamNameProcessor.processTeamName(team.name);

    return Card(
      margin: const EdgeInsets.only(bottom: _AddTeamConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(_AddTeamConstants.paddingMedium),
        leading: _buildTeamLogo(team),
        title: Text(
          processedName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => _addTeamToList(team),
      ),
    );
  }

  Widget _buildTeamLogo(Organisation team) {
    final logoUrl = _getBestLogoUrl(team);

    if (logoUrl != null) {
      return ClipOval(
        child: Image.network(
          logoUrl,
          width: _AddTeamConstants.logoSize,
          height: _AddTeamConstants.logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: _AddTeamConstants.logoSize,
              height: _AddTeamConstants.logoSize,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: _AddTeamConstants.circularProgressStrokeWidth,
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

  /// Get the best available logo URL from the team
  String? _getBestLogoUrl(Organisation team) {
    return team.logoUrlLarge ?? team.logoUrl48;
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: _AddTeamConstants.logoSize,
      height: _AddTeamConstants.logoSize,
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(
        size: _AddTeamConstants.defaultLogoIconSize,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }

  /// Add team to the list, handling duplicates with edit dialog
  Future<void> _addTeamToList(Organisation team) async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final processedName = _TeamNameProcessor.processTeamName(team.name);

    // Check if team already exists
    final existingTeam = teamsProvider.findTeamByName(processedName);

    if (existingTeam != null) {
      // Show edit dialog for existing team, passing the logo info from search result
      await _showEditTeamDialog(existingTeam.name, team);
    } else {
      // Add new team directly
      await _addTeamAndFinish(processedName, logoUrl: _getBestLogoUrl(team));
    }
  }

  /// Helper method to add team and handle success flow
  Future<void> _addTeamAndFinish(
    String teamName, {
    String? logoUrl,
    String? logoUrl32,
    String? logoUrl48,
    String? logoUrlLarge,
  }) async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await teamsProvider.addTeam(
      teamName,
      logoUrl: logoUrl,
      logoUrl32: logoUrl32,
      logoUrl48: logoUrl48,
      logoUrlLarge: logoUrlLarge,
    );

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added "$teamName" to your teams'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return the team name so it can be auto-selected
      navigator.pop(teamName);
    }
  }

  /// Show dialog for creating a new team with custom name (from search results)
  Future<void> _showEditTeamDialog(
    String currentName,
    Organisation originalTeam,
  ) async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);

    final result = await DialogService.showTeamNameDialog(
      context: context,
      title: 'Add Team',
      initialValue: currentName,
      hasTeamWithName: teamsProvider.hasTeamWithName,
      currentTeamName: null, // Don't allow any existing team names
      confirmText: 'Add Team',
      cancelText: 'Cancel',
    );

    if (result != null) {
      // Always create a new team (never modify existing) with logo from search result
      await _addTeamAndFinish(
        result,
        logoUrl: _getBestLogoUrl(originalTeam),
        logoUrl32: originalTeam.logoUrl32,
        logoUrl48: originalTeam.logoUrl48,
        logoUrlLarge: originalTeam.logoUrlLarge,
      );
    }
  }

  /// Show dialog for custom team entry
  Future<void> _showCustomEntryDialog() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);

    final result = await DialogService.showTeamNameDialog(
      context: context,
      title: 'Add Custom Team',
      initialValue: null,
      hasTeamWithName: teamsProvider.hasTeamWithName,
      confirmText: 'Add Team',
      cancelText: 'Cancel',
      description: 'Enter a custom team name:',
    );

    if (result != null) {
      // Add the custom team (no logo for custom teams)
      await _addTeamAndFinish(result);
    }
  }
}
