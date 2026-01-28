// widget for selecting home and away teams

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/router/app_router.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/football_icon.dart';

/// widget for selecting home and away teams
class TeamSelector extends StatefulWidget {
  const TeamSelector({
    required this.homeTeam,
    required this.awayTeam,
    required this.onHomeTeamChanged,
    required this.onAwayTeamChanged,
    super.key,
  });
  final String? homeTeam;
  final String? awayTeam;
  final ValueChanged<String?> onHomeTeamChanged;
  final ValueChanged<String?> onAwayTeamChanged;

  @override
  State<TeamSelector> createState() => _TeamSelectorState();
}

class _TeamSelectorState extends State<TeamSelector> {
  Future<String?> _selectTeam({
    required String title,
    required String? excludeTeam,
  }) async {
    final result = await context.push<String>(
      '/team-select',
      extra: TeamSelectionExtra(
        title: title,
        excludeTeam: excludeTeam,
      ),
    );
    return result;
  }

  Widget _buildTeamCard({
    required String label,
    required String? teamName,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teamsProvider = Provider.of<TeamsViewModel>(context);

    final team =
        teamName != null && teamsProvider.loaded
            ? teamsProvider.teams.where((t) => t.name == teamName).firstOrNull
            : null;

    return Card(
      elevation: 0,
      color:
          teamName == null
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerHigh,
      child:
          teamName == null
              ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: _buildEmptyState(label, colorScheme),
              )
              : _buildSelectedStateWithClear(
                team,
                teamName,
                onTap,
                onClear,
                colorScheme,
              ),
    );
  }

  Widget _buildSelectedStateWithClear(
    Team? team,
    String teamName,
    VoidCallback onTap,
    VoidCallback? onClear,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildTeamLogo(team),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              teamName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.close_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_outlined,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team? team) {
    if (team?.logoUrl != null && team!.logoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: team.logoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildDefaultLogo(),
        ),
      );
    }

    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(color: colorScheme.onPrimaryContainer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Team cards column (takes most of the space)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Home Team Card
              _buildTeamCard(
                label: 'Home Team',
                teamName: widget.homeTeam,
                onTap: () async {
                  final selectedTeam = await _selectTeam(
                    title: 'Select Home Team',
                    excludeTeam: widget.awayTeam,
                  );
                  if (selectedTeam != null) {
                    widget.onHomeTeamChanged(selectedTeam);
                  }
                },
                onClear:
                    widget.homeTeam != null
                        ? () => widget.onHomeTeamChanged(null)
                        : null,
              ),

              const SizedBox(height: 8),

              // Away Team Card
              _buildTeamCard(
                label: 'Away Team',
                teamName: widget.awayTeam,
                onTap: () async {
                  final selectedTeam = await _selectTeam(
                    title: 'Select Away Team',
                    excludeTeam: widget.homeTeam,
                  );
                  if (selectedTeam != null) {
                    widget.onAwayTeamChanged(selectedTeam);
                  }
                },
                onClear:
                    widget.awayTeam != null
                        ? () => widget.onAwayTeamChanged(null)
                        : null,
              ),
            ],
          ),
        ),

        // Swap button on the right
        SizedBox(
          child: Center(
            child: IconButton(
              onPressed:
                  (widget.homeTeam != null || widget.awayTeam != null)
                      ? () {
                        // Swap home and away teams
                        final tempHome = widget.homeTeam;
                        final tempAway = widget.awayTeam;

                        // Call the callbacks to update parent state
                        widget.onHomeTeamChanged(tempAway);
                        widget.onAwayTeamChanged(tempHome);
                      }
                      : null, // Disabled when no teams are selected
              icon: const Icon(Icons.swap_vert),
              style: IconButton.styleFrom(
                backgroundColor: ColorService.transparent,
                elevation: 0,
                foregroundColor: colorScheme.onSurfaceVariant,
                disabledForegroundColor: colorScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
