import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/score_models.dart';
import '../../models/playhq_models.dart';
import '../../providers/teams_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/color_service.dart';
import '../../services/navigation_service.dart';
import '../../services/dialog_service.dart';
import '../../services/asset_icon_service.dart';
import '../../services/playhq_graphql_service.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.teamName});

  final String teamName;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    // Try to fetch address after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryFetchAddressIfNeeded();
    });
  }

  Future<void> _tryFetchAddressIfNeeded() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final teamIndex = teamsProvider.teams.indexWhere(
      (team) => team.name == widget.teamName,
    );

    if (teamIndex == -1) return;

    final team = teamsProvider.teams[teamIndex];

    // Only fetch if team has PlayHQ info but no address
    if ((team.routingCode != null && team.routingCode!.isNotEmpty) &&
        team.address == null &&
        !_isFetchingAddress) {
      await _fetchAddressFromPlayHQ(teamIndex, team);
    } else if (team.playHQId != null &&
        team.playHQId!.isNotEmpty &&
        team.routingCode == null &&
        team.address == null &&
        !_isFetchingAddress) {
      // Fallback: try to find routingCode by searching
      await _fetchAddressFromPlayHQ(teamIndex, team);
    }
  }

  Future<void> _fetchAddressFromPlayHQ(int teamIndex, Team team) async {
    setState(() {
      _isFetchingAddress = true;
    });

    try {
      // Show a subtle loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Fetching team address...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      String? routingCode = team.routingCode;

      // If no routingCode stored, try to find it by searching
      if (routingCode == null || routingCode.isEmpty) {
        final searchResponse = await PlayHQGraphQLService.searchAFLClubs(
          team.name,
        );

        if (searchResponse.results.isNotEmpty) {
          // Look for exact match by PlayHQ ID if available
          Organisation? matchingOrg;
          if (team.playHQId != null && team.playHQId!.isNotEmpty) {
            try {
              matchingOrg = searchResponse.results.firstWhere(
                (org) => org.id == team.playHQId,
              );
            } catch (e) {
              // No exact match found, use first result
              matchingOrg = searchResponse.results.first;
            }
          } else {
            matchingOrg = searchResponse.results.first;
          }
          routingCode = matchingOrg.routingCode;
        }
      }

      if (routingCode != null && routingCode.isNotEmpty) {
        // Fetch detailed organization information
        final orgResponse = await PlayHQGraphQLService.getOrganisationDetails(
          routingCode,
        );

        final address = orgResponse.organisation?.address;

        if (address != null && mounted) {
          // Update the team with address information
          final teamsProvider = Provider.of<TeamsProvider>(
            context,
            listen: false,
          );
          await teamsProvider.editTeam(
            teamIndex,
            team.name,
            logoUrl: team.logoUrl,
            logoUrl32: team.logoUrl32,
            logoUrl48: team.logoUrl48,
            logoUrlLarge: team.logoUrlLarge,
            address: address,
            playHQId: team.playHQId,
            routingCode: routingCode, // Store the routingCode for future use
          );

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address information updated successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No address information found for this team'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find team in PlayHQ database'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching address: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsProvider = Provider.of<TeamsProvider>(context);
    final userPreferences = Provider.of<UserPreferencesProvider>(context);

    // Find the team by name
    final teamIndex = teamsProvider.teams.indexWhere(
      (team) => team.name == widget.teamName,
    );

    // If team not found, show error
    if (teamIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Not Found')),
        body: const Center(child: Text('Team not found')),
      );
    }

    final team = teamsProvider.teams[teamIndex];
    final isFavorite = userPreferences.favoriteTeam == team.name;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
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
                    title: Text(team.name),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_outlined),
                      tooltip: 'Back',
                      onPressed: _handleBackPress,
                    ),
                  ),
                ];
              },
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 32.0,
                        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Team Logo
                          _buildTeamLogo(team, size: 120),

                          const SizedBox(height: 32.0),

                          // Team Name
                          Text(
                            team.name,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),

                          // Address Section
                          if (team.address != null) ...[
                            const SizedBox(height: 32.0),
                            _buildAddressSection(team.address!),
                          ] else ...[
                            const SizedBox(height: 32.0),
                            _buildNoAddressSection(teamIndex, team),
                          ],

                          const SizedBox(height: 48.0),

                          // Action Buttons
                          _buildActionButtons(context, isFavorite),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Address address) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              address.displayAddress,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            // Embedded Google Maps Static Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    // Google Maps Static Image
                    Image.network(
                      _buildGoogleMapsStaticUrl(address),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Map unavailable',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Tap overlay to open full map
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => _openGoogleMaps(address),
                          child: Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Maps Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMaps(address),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Map'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openDirections(address),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddressSection(int teamIndex, Team team) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: context.colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              'No address information available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (team.playHQId != null && team.playHQId!.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _isFetchingAddress
                          ? null
                          : () => _fetchAddressFromPlayHQ(teamIndex, team),
                  icon:
                      _isFetchingAddress
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.location_searching),
                  label: Text(
                    _isFetchingAddress
                        ? 'Fetching Address...'
                        : 'Fetch Address from PlayHQ',
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16.0),
              Text(
                'This team was added manually. Address information is only available for teams imported from PlayHQ.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isFavorite) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Favorite Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.star_outlined
                        : Icons.star_border_outlined,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isFavorite
                            ? context.colors.primary
                            : context.colors.surfaceContainerHighest,
                    foregroundColor:
                        isFavorite
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                    minimumSize: const Size(56, 56),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Favorite',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),

            // Edit Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  onPressed: _editTeamName,
                  icon: const Icon(Icons.edit_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.surfaceContainerHighest,
                    foregroundColor: context.colors.onSurface,
                    minimumSize: const Size(56, 56),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text('Edit', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),

            // Delete Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  onPressed: _deleteTeam,
                  icon: const Icon(Icons.delete_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.error,
                    foregroundColor: context.colors.onError,
                    minimumSize: const Size(56, 56),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text('Delete', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(Address address) async {
    final query = Uri.encodeComponent(address.googleMapsAddress);
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Google Maps: $e')),
        );
      }
    }
  }

  Future<void> _openDirections(Address address) async {
    final query = Uri.encodeComponent(address.googleMapsAddress);
    final directionsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$query';

    try {
      final uri = Uri.parse(directionsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps for directions'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening directions: $e')));
      }
    }
  }

  Widget _buildTeamLogo(Team team, {double size = 48}) {
    final logoUrl = team.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo(size: size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
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

    return _buildDefaultLogo(size: size);
  }

  Widget _buildDefaultLogo({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(
        size: size * 0.6,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }

  void _toggleFavorite() {
    final userPreferences = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final teamIndex = teamsProvider.teams.indexWhere(
      (team) => team.name == widget.teamName,
    );

    if (teamIndex == -1) return;

    final team = teamsProvider.teams[teamIndex];

    if (userPreferences.favoriteTeam == team.name) {
      userPreferences.setFavoriteTeam('');
    } else {
      userPreferences.setFavoriteTeam(team.name);
    }
  }

  Future<void> _editTeamName() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final teamIndex = teamsProvider.teams.indexWhere(
      (team) => team.name == widget.teamName,
    );

    if (teamIndex == -1) return;

    final currentTeam = teamsProvider.teams[teamIndex];

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
      await teamsProvider.editTeam(
        teamIndex,
        result,
        logoUrl: currentTeam.logoUrl,
      );

      // Navigate back and forward to refresh with new team name
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(teamName: result),
          ),
        );
      }
    }
  }

  Future<void> _deleteTeam() async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final userPreferences = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );

    final teamIndex = teamsProvider.teams.indexWhere(
      (team) => team.name == widget.teamName,
    );

    if (teamIndex == -1) return;

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
      if (userPreferences.favoriteTeam == widget.teamName) {
        await userPreferences.setFavoriteTeam('');
      }

      await teamsProvider.deleteTeam(teamIndex);

      // Navigate back to team list
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleBackPress() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Builds a Google Maps Static API URL for the given address
  String _buildGoogleMapsStaticUrl(Address address) {
    const apiKey =
        'YOUR_API_KEY'; // Note: Replace with actual API key or use env variable
    const baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';

    // Encode the address for URL
    final encodedAddress = Uri.encodeComponent(address.displayAddress);

    // Build the URL with appropriate parameters
    final url =
        '$baseUrl?'
        'center=$encodedAddress'
        '&zoom=15'
        '&size=600x300'
        '&maptype=roadmap'
        '&markers=color:red%7C$encodedAddress'
        '&style=feature:poi%7Cvisibility:off'
        '&style=feature:transit%7Cvisibility:off'
        '&key=$apiKey';

    return url;
  }
}
