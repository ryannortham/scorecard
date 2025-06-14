import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/game_state_service.dart';
import 'package:goalkeeper/services/navigation_service.dart';

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

    // Check if this game is currently in progress
    final gameStateService = GameStateService.instance;
    final isGameInProgress = gameStateService.currentGameId == game.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          '${game.homeTeam} vs ${game.awayTeam}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${dateFormat.format(game.date)} at ${timeFormat.format(game.date)}'),
            const SizedBox(height: 4),
            Text(
              'Score: ${game.homeGoals}.${game.homeBehinds} (${game.homeGoals * 6 + game.homeBehinds}) - ${game.awayGoals}.${game.awayBehinds} (${game.awayGoals * 6 + game.awayBehinds})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            // Show "In Progress" indicator if this game is currently active
            if (isGameInProgress) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Game in progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: onTap,
        trailing: isGameInProgress
            ? Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context),
              ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Check if this game is currently in progress
    final gameStateService = GameStateService.instance;
    final isGameInProgress = gameStateService.currentGameId == game.id;

    if (isGameInProgress) {
      // Show message that game cannot be deleted while in progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot delete game while in progress'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: 'Delete Game?',
      content:
          '${game.homeTeam} vs ${game.awayTeam}\n${dateFormat.format(game.date)}',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      onDelete();
    }
  }
}
