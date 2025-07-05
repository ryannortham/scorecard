import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/services/game_history_service.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';

/// Optimized widget for displaying game summary in the history list
class GameSummaryCard extends StatelessWidget {
  final GameSummary gameSummary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const GameSummaryCard({
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

  @override
  Widget build(BuildContext context) {
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final shouldShowTrophy = _shouldShowTrophyIcon(gameSummary, userPrefs);

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 0,
      color:
          isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading:
            isSelectionMode
                ? Icon(
                  isSelected
                      ? Icons.check_circle_outlined
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                )
                : null,
        title: Text(
          '${gameSummary.homeTeam} vs ${gameSummary.awayTeam}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(gameSummary.date)} at ${timeFormat.format(gameSummary.date)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Score: ${gameSummary.homeGoals}.${gameSummary.homeBehinds} (${gameSummary.homePoints}) - ${gameSummary.awayGoals}.${gameSummary.awayBehinds} (${gameSummary.awayPoints})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing:
            shouldShowTrophy
                ? Icon(
                  Icons.emoji_events_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                )
                : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
