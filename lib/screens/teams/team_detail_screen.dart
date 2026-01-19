import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/score_models.dart';
import '../../models/playhq_models.dart';
import '../../providers/teams_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../services/app_logger.dart';
import '../../services/color_service.dart';
import '../../services/navigation_service.dart';
import '../../services/dialog_service.dart';
import '../../services/playhq_graphql_service.dart';
import '../../services/google_maps_service.dart';
import '../../widgets/team_logo.dart';
import '../../widgets/app_scaffold.dart';

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
      child: AppScaffold(
        extendBody: true,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: ColorService.transparent,
                foregroundColor: context.colors.onPrimaryContainer,
                floating: true,
                snap: true,
                pinned: false,
                elevation: 0,
                shadowColor: ColorService.transparent,
                surfaceTintColor: ColorService.transparent,
                title: const Text('Team Details'),
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
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24.0),

                      // Team Logo
                      TeamLogo(logoUrl: team.logoUrl, size: 120),

                      const SizedBox(height: 32.0),

                      // Team Name
                      Text(
                        team.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24.0),

                      // Action Buttons (moved above address)
                      _buildActionButtons(context, isFavorite),

                      // Address Section - only show for PlayHQ teams with valid addresses
                      if (team.playHQId != null &&
                          team.playHQId!.isNotEmpty) ...[
                        if (team.address != null &&
                            team.address!.isValidForDirections) ...[
                          const SizedBox(height: 4.0),
                          _buildAddressSection(team.address!, team.name),
                        ] else if (team.address == null) ...[
                          const SizedBox(height: 4.0),
                          _buildNoAddressSection(teamIndex, team),
                        ],
                        // If address exists but is invalid (P.O. Box, etc.), don't show anything
                      ],

                      SizedBox(
                        height: 16.0 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection(Address address, String teamName) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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

            // Google Maps Static Image
            if (GoogleMapsService.isConfigured) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  GoogleMapsService.getStaticMapUrl(
                    address,
                    venueName: teamName,
                    width: 600,
                    height: 250,
                    zoom: 15,
                  ),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: context.colors.surfaceContainerHighest,
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
                    AppLogger.error(
                      'Map image failed to load: $error',
                      component: 'TeamDetailScreen',
                    );
                    AppLogger.error(
                      'Stack trace: $stackTrace',
                      component: 'TeamDetailScreen',
                    );
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Map preview unavailable',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            Center(
              child: FilledButton.icon(
                onPressed: () => _openDirections(address, teamName),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Directions'),
              ),
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
        padding: const EdgeInsets.all(8.0),
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
        padding: const EdgeInsets.all(8.0),
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
                Text(
                  'Edit Name',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
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

  Future<void> _openDirections(Address address, String teamName) async {
    try {
      Uri? uri;

      // Use enhanced query with venue name for better search accuracy
      final query = Uri.encodeComponent(
        address.getSearchQueryWithVenue(teamName),
      );

      if (Platform.isAndroid) {
        // Use geo: URI for Android - opens any maps app with preference for Google Maps
        uri = Uri.parse('geo:0,0?q=$query');
      } else if (Platform.isIOS) {
        // Try Google Maps app first, fallback to Apple Maps
        final googleMapsUri = Uri.parse('comgooglemaps://?q=$query');

        if (await canLaunchUrl(googleMapsUri)) {
          uri = googleMapsUri;
        } else {
          // Fallback to Apple Maps
          uri = Uri.parse('http://maps.apple.com/?q=$query');
        }
      } else {
        // Web and other platforms - use HTTPS URL
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$query',
        );
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps for directions')),
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
}
