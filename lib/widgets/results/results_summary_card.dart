// results summary card for game list display

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/results_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

/// displays game summary in the results list
class ResultsSummaryCard extends StatelessWidget {
  const ResultsSummaryCard({
    required this.gameSummary,
    required this.onTap,
    super.key,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });
  final GameSummary gameSummary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  /// determines if trophy icon should show for favourite team win
  bool _shouldShowTrophyIcon(
    GameSummary gameSummary,
    UserPreferencesProvider userPrefs,
  ) {
    if (userPrefs.favoriteTeams.isEmpty) return false;

    final homePoints = gameSummary.homePoints;
    final awayPoints = gameSummary.awayPoints;

    if (homePoints == awayPoints) return false;

    final favoriteIsHome = userPrefs.favoriteTeams.contains(
      gameSummary.homeTeam,
    );
    final favoriteIsAway = userPrefs.favoriteTeams.contains(
      gameSummary.awayTeam,
    );

    if (!favoriteIsHome && !favoriteIsAway) return false;

    if (favoriteIsHome && homePoints > awayPoints) return true;
    if (favoriteIsAway && awayPoints > homePoints) return true;

    return false;
  }

  /// builds team logo widget
  Widget _buildTeamLogo(String teamName) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        final team = teamsProvider.findTeamByName(teamName);
        return TeamLogo(logoUrl: team?.logoUrl, size: 48);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final shouldShowTrophy = _shouldShowTrophyIcon(gameSummary, userPrefs);

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 0,
        color:
            isSelected
                ? context.colors.primaryContainer
                : context.colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Icon(
                  isSelected
                      ? Icons.check_circle_outlined
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected
                          ? context.colors.primary
                          : context.colors.outline,
                ),
                const SizedBox(width: 12),
              ],
              _buildTeamLogo(gameSummary.homeTeam),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          gameSummary.homeTeam,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'vs',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          gameSummary.awayTeam,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Score: ${gameSummary.homeGoals}.'
                          '${gameSummary.homeBehinds} '
                          '(${gameSummary.homePoints}) - '
                          '${gameSummary.awayGoals}.'
                          '${gameSummary.awayBehinds} '
                          '(${gameSummary.awayPoints})',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(gameSummary.date)} at '
                          '${timeFormat.format(gameSummary.date)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        if (shouldShowTrophy)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: context.colors.secondary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildTeamLogo(gameSummary.awayTeam),
            ],
          ),
        ),
      ),
    );
  }
}
