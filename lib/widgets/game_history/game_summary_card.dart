import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:goalkeeper/services/game_history_service.dart';
import 'package:goalkeeper/services/navigation_service.dart';

/// Optimized widget for displaying game summary in the history list
class GameSummaryCard extends StatelessWidget {
  final GameSummary gameSummary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GameSummaryCard({
    super.key,
    required this.gameSummary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          '${gameSummary.homeTeam} vs ${gameSummary.awayTeam}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${dateFormat.format(gameSummary.date)} at ${timeFormat.format(gameSummary.date)}'),
            const SizedBox(height: 4),
            Text(
              'Score: ${gameSummary.homeGoals}.${gameSummary.homeBehinds} (${gameSummary.homePoints}) - ${gameSummary.awayGoals}.${gameSummary.awayBehinds} (${gameSummary.awayPoints})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: 'Delete Game?',
      content:
          '${gameSummary.homeTeam} vs ${gameSummary.awayTeam}\n${dateFormat.format(gameSummary.date)}',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      onDelete();
    }
  }
}
