// team detail screen with playhq address fetching

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/context_extensions.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/playhq_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/dialog_service.dart';
import 'package:scorecard/widgets/common/sliver_app_bar.dart';
import 'package:scorecard/widgets/teams/team_action_buttons.dart';
import 'package:scorecard/widgets/teams/team_address_section.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';
import 'package:scorecard/widgets/teams/team_no_address_section.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({required this.teamName, super.key});

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
      unawaited(_tryFetchAddressIfNeeded());
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
        SnackBarService.showLoading(context, 'Fetching team address...');
      }

      var routingCode = team.routingCode;

      // If no routingCode stored, try to find it by searching
      if (routingCode == null || routingCode.isEmpty) {
        final searchResponse = await PlayHQGraphQLService.searchAFLClubs(
          team.name,
        );

        if (searchResponse.results.isNotEmpty) {
          // Look for exact match by PlayHQ ID if available
          Organisation matchingOrg;
          if (team.playHQId != null && team.playHQId!.isNotEmpty) {
            matchingOrg = searchResponse.results.firstWhere(
              (org) => org.id == team.playHQId,
              orElse: () => searchResponse.results.first,
            );
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
            SnackBarService.showSuccess(
              context,
              'Address information updated successfully!',
            );
          }
        } else if (mounted) {
          SnackBarService.showInfo(
            context,
            'No address information found for this team',
          );
        }
      } else if (mounted) {
        SnackBarService.showInfo(
          context,
          'Could not find team in PlayHQ database',
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Error fetching address: $e');
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
    final isFavorite = userPreferences.isFavoriteTeam(team.name);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.handleBackPress();
      },
      child: AppScaffold(
        extendBody: true,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              AppSliverAppBar.withBackButton(
                title: const Text('Team Details'),
                onBackPressed: () => context.handleBackPress(),
              ),
            ];
          },
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Team Logo
                      TeamLogo(logoUrl: team.logoUrl, size: 120),

                      const SizedBox(height: 32),

                      // Team Name
                      Text(
                        team.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      TeamActionButtons(
                        isFavorite: isFavorite,
                        onToggleFavorite: _toggleFavorite,
                        onEdit: _editTeamName,
                        onDelete: _deleteTeam,
                      ),

                      // Address Section - only show for PlayHQ teams
                      if (team.playHQId != null &&
                          team.playHQId!.isNotEmpty) ...[
                        if (team.address != null &&
                            team.address!.isValidForDirections) ...[
                          const SizedBox(height: 4),
                          TeamAddressSection(
                            address: team.address!,
                            teamName: team.name,
                          ),
                        ] else if (team.address == null) ...[
                          const SizedBox(height: 4),
                          TeamNoAddressSection(
                            hasPlayHQId: true,
                            isFetching: _isFetchingAddress,
                            onFetchAddress:
                                () => _fetchAddressFromPlayHQ(teamIndex, team),
                          ),
                        ],
                        // If address exists but is invalid (P.O. Box), skip
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

  Future<void> _toggleFavorite() async {
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

    final wasAdded = !userPreferences.isFavoriteTeam(team.name);
    await userPreferences.toggleFavoriteTeam(team.name);

    if (mounted && context.mounted) {
      SnackBarService.showSuccess(
        context,
        wasAdded ? 'Added to favourites' : 'Removed from favourites',
      );
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
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
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

    final confirmed = await DialogService.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: 'Delete Team?',
      isDestructive: true,
    );

    if (confirmed) {
      // If deleting a favourite team, remove it from favourites
      if (userPreferences.isFavoriteTeam(widget.teamName)) {
        await userPreferences.removeFavoriteTeam(widget.teamName);
      }

      await teamsProvider.deleteTeam(teamIndex);

      // Navigate back to team list
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
