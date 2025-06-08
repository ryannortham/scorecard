import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/game_record.dart';

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
          ],
        ),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text(
              'Are you sure you want to delete the game between ${game.homeTeam} and ${game.awayTeam}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onDelete();
    }
  }
}
