import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/navigation_service.dart';
import 'package:scorecard/services/color_service.dart';

/// A reusable widget for displaying a game card in the history list
class GameHistoryCard extends StatelessWidget {
  final GameRecord game;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GameHistoryCard({
    super.key,
    required this.game,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Column(
          children: [
            Text(
              game.homeTeam,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Text(
              'vs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              game.awayTeam,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(game.date)} at ${timeFormat.format(game.date)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Score: ${game.homeGoals}.${game.homeBehinds} (${game.homeGoals * 6 + game.homeBehinds}) - ${game.awayGoals}.${game.awayBehinds} (${game.awayGoals * 6 + game.awayBehinds})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
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
    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: 'Delete Game?',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      onDelete();
    }
  }
}
