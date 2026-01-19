import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/services/results_service.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/widgets/team_logo.dart';
import 'package:scorecard/services/color_service.dart';

/// Optimized widget for displaying game summary in the results list
class ResultsSummaryCard extends StatelessWidget {
  final GameSummary gameSummary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const ResultsSummaryCard({
    super.key,
    required this.gameSummary,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  /// Determines if the trophy icon should be shown (favorite team won)
  bool _shouldShowTrophyIcon(
    GameSummary gameSummary,
    UserPreferencesProvider userPrefs,
  ) {
    // Must have a favorite team set
    if (userPrefs.favoriteTeam.isEmpty) return false;

    // Check if there's a winner (no ties)
    final homePoints = gameSummary.homePoints;
    final awayPoints = gameSummary.awayPoints;

    if (homePoints == awayPoints) return false; // No winner in a tie

    final favoriteIsHome = gameSummary.homeTeam == userPrefs.favoriteTeam;
    final favoriteIsAway = gameSummary.awayTeam == userPrefs.favoriteTeam;

    // Favorite team must be playing in this game
    if (!favoriteIsHome && !favoriteIsAway) return false;

    // Check if favorite team won
    if (favoriteIsHome && homePoints > awayPoints) return true;
    if (favoriteIsAway && awayPoints > homePoints) return true;

    return false;
  }

  /// Build team logo widget with 48x48 circular design
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
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 0,
        color:
            isSelected
                ? context.colors.primaryContainer
                : context.colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Selection checkbox on the left when in selection mode
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
              // Left column - Home team logo
              _buildTeamLogo(gameSummary.homeTeam),
              const SizedBox(width: 16),
              // Middle column - Existing text content
              Expanded(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Score: ${gameSummary.homeGoals}.${gameSummary.homeBehinds} (${gameSummary.homePoints}) - ${gameSummary.awayGoals}.${gameSummary.awayBehinds} (${gameSummary.awayPoints})',
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
                          '${dateFormat.format(gameSummary.date)} at ${timeFormat.format(gameSummary.date)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        if (shouldShowTrophy)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
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
              // Right column - Away team logo
              _buildTeamLogo(gameSummary.awayTeam),
            ],
          ),
        ),
      ),
    );
  }
}
