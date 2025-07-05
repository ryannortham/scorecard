import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/playhq_models.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/playhq_graphql_service.dart';
import 'package:scorecard/widgets/game_setup/app_drawer.dart';
import '../widgets/football_icon.dart';

/// Constants for the AddTeamScreen
class _AddTeamConstants {
  static const int searchLimit = 20;
  static const int searchDelayMs = 1000;
  static const int maxTeamNameLength = 60;
  static const double logoSize = 48.0;
  static const double defaultLogoIconSize = 28.0;
  static const double circularProgressStrokeWidth = 2.0;
  static const double largeIconSize = 64.0;

  // Spacing constants
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingExtraLarge = 32.0;

  // Excluded words for team filtering (case insensitive)
  static const List<String> excludedWords = ['auskick', 'holiday', 'superkick'];
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
          final teamsProvider = Provider.of<TeamsProvider>(
            context,
            listen: false,
          );

          // Filter to only include teams with logos and exclude certain words/existing teams
          _searchResults =
              response.results
                  .where((team) => team.logoUrl48?.isNotEmpty ?? false)
                  .where((team) {
                    final nameLower = team.name.toLowerCase();
                    // Exclude teams with excluded words
                    final hasExcludedWord = _AddTeamConstants.excludedWords.any(
                      (word) => nameLower.contains(word),
                    );
                    // Exclude teams that already exist in our list
                    final alreadyExists = teamsProvider.hasTeamWithName(
                      team.name,
                    );

                    return !hasExcludedWord && !alreadyExists;
                  })
                  .toList();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Team'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu_outlined),
                onPressed: () {
                  // Unfocus search bar before opening drawer to prevent potential conflicts
                  _searchFocusNode.unfocus();
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'add_team'),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.25],
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(_AddTeamConstants.paddingLarge),
                child: SearchBar(
                  controller: _materialSearchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search for teams...',
                  leading: const Icon(Icons.search_outlined),
                  trailing:
                      _materialSearchController.text.isNotEmpty
                          ? [
                            IconButton(
                              icon: const Icon(Icons.clear_outlined),
                              onPressed: () {
                                _materialSearchController.clear();
                                _performSearch('');
                              },
                            ),
                          ]
                          : null,
                  onSubmitted: _performSearch,
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide clear button

                    // Perform search after a short delay to avoid too many requests
                    Future.delayed(
                      const Duration(
                        milliseconds: _AddTeamConstants.searchDelayMs,
                      ),
                      () {
                        if (_materialSearchController.text == value) {
                          _performSearch(value);
                        }
                      },
                    );
                  },
                ),
              ),

              // Button group for search and custom entry
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _AddTeamConstants.paddingLarge,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed:
                            _isLoading
                                ? null
                                : () => _performSearch(
                                  _materialSearchController.text,
                                ),
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: _AddTeamConstants.paddingLarge,
                                  height: _AddTeamConstants.paddingLarge,
                                  child: CircularProgressIndicator(
                                    strokeWidth:
                                        _AddTeamConstants
                                            .circularProgressStrokeWidth,
                                  ),
                                )
                                : const Icon(Icons.search_outlined),
                        label: Text(_isLoading ? 'Searching...' : 'Search'),
                      ),
                    ),
                    const SizedBox(width: _AddTeamConstants.paddingMedium),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isLoading ? null : _showCustomEntryDialog,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Custom'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _AddTeamConstants.paddingLarge),

              // Results
              Expanded(child: _buildResultsSection()),
            ],
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
            const SizedBox(height: _AddTeamConstants.paddingLarge),
            Text(
              'Enter a team name to search',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
            const SizedBox(height: _AddTeamConstants.paddingLarge),
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
            const SizedBox(height: _AddTeamConstants.paddingLarge),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _AddTeamConstants.paddingExtraLarge,
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
            ),
            const SizedBox(height: _AddTeamConstants.paddingLarge),
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
            const SizedBox(height: _AddTeamConstants.paddingLarge),
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
      padding: const EdgeInsets.all(_AddTeamConstants.paddingLarge),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final team = _searchResults[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(Organisation team) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: _AddTeamConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(_AddTeamConstants.paddingLarge),
        leading: _buildTeamLogo(team),
        title: Text(
          team.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => _addTeamToList(team),
      ),
    );
  }

  Widget _buildTeamLogo(Organisation team) {
    final logoUrl = team.logoUrl48;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl,
          width: _AddTeamConstants.logoSize,
          height: _AddTeamConstants.logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo();
          },
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

  Widget _buildDefaultLogo() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _AddTeamConstants.logoSize,
      height: _AddTeamConstants.logoSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(
        size: _AddTeamConstants.defaultLogoIconSize,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Add a team from search results to the local teams list
  Future<void> _addTeamToList(Organisation team) async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);

    // Check if team already exists
    if (teamsProvider.hasTeamWithName(team.name)) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "${team.name}" already exists'),
            backgroundColor: colorScheme.error,
          ),
        );
        // Still return the team name for potential selection
        Navigator.of(context).pop(team.name);
      }
      return;
    }

    // Add team with logo
    await teamsProvider.addTeam(team.name, logoUrl: team.logoUrl48);

    // Navigate back and return the team name for potential selection
    if (mounted) {
      Navigator.of(context).pop(team.name);
    }
  }

  /// Show custom team entry dialog
  Future<void> _showCustomEntryDialog() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Pre-populate with search text if available
    if (_materialSearchController.text.trim().isNotEmpty) {
      controller.text = _materialSearchController.text.trim();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Custom Team'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: _AddTeamConstants.maxTeamNameLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a team name';
                }
                final trimmedValue = value.trim();
                if (teamsProvider.hasTeamWithName(trimmedValue)) {
                  return 'Team name already exists';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final teamName = controller.text.trim();
                  await teamsProvider.addTeam(teamName);
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(
                      context,
                    ).pop(teamName); // Navigate back and return team name
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
