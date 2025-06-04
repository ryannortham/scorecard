import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/game_history_service.dart';
import 'package:intl/intl.dart';
import 'settings.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  List<GameRecord> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await GameHistoryService.loadGames();
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading games: $e')),
        );
      }
    }
  }

  Future<void> _deleteGame(GameRecord game) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text(
            'Are you sure you want to delete the game between ${game.homeTeam} and ${game.awayTeam}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await GameHistoryService.deleteGame(game.id);
        await _loadGames(); // Refresh the list
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting game: $e')),
          );
        }
      }
    }
  }

  void _showGameDetails(GameRecord game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${game.homeTeam} vs ${game.awayTeam}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Date: ${DateFormat('EEEE, MMM d, yyyy').format(game.date)}'),
                const SizedBox(height: 8),
                Text('Quarter Length: ${game.quarterMinutes} minutes'),
                Text(
                    'Timer Mode: ${game.isCountdownTimer ? 'Countdown' : 'Count Up'}'),
                const SizedBox(height: 12),
                const Text('Final Score:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    '${game.homeTeam}: ${game.homeGoals}.${game.homeBehinds} (${game.homePoints})'),
                Text(
                    '${game.awayTeam}: ${game.awayGoals}.${game.awayBehinds} (${game.awayPoints})'),
                const SizedBox(height: 12),
                Text('Total Events: ${game.events.length}'),
                if (game.events.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Quarter Breakdown:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (int i = 1; i <= 4; i++) ...[
                    () {
                      final quarterEvents =
                          game.events.where((e) => e.quarter == i);
                      final homeGoals = quarterEvents
                          .where((e) =>
                              e.team == game.homeTeam && e.type == 'goal')
                          .length;
                      final homeBehinds = quarterEvents
                          .where((e) =>
                              e.team == game.homeTeam && e.type == 'behind')
                          .length;
                      final awayGoals = quarterEvents
                          .where((e) =>
                              e.team == game.awayTeam && e.type == 'goal')
                          .length;
                      final awayBehinds = quarterEvents
                          .where((e) =>
                              e.team == game.awayTeam && e.type == 'behind')
                          .length;

                      return Text(
                          'Q$i: ${game.homeTeam} $homeGoals.$homeBehinds - ${game.awayTeam} $awayGoals.$awayBehinds');
                    }(),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getGameResult(GameRecord game) {
    if (game.homePoints > game.awayPoints) {
      return '${game.homeTeam} won';
    } else if (game.awayPoints > game.homePoints) {
      return '${game.awayTeam} won';
    } else {
      return 'Draw';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Settings(title: 'Settings'),
              ),
            ),
          ),
          if (_games.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'clear_all') {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Clear All Games'),
                        content: const Text(
                          'Are you sure you want to delete all saved games? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    try {
                      await GameHistoryService.clearAllGames();
                      await _loadGames();
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All games cleared')),
                        );
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error clearing games: $e')),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Text('Clear All Games'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No saved games',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Games you save will appear here',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGames,
                  child: ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            '${game.homeTeam} vs ${game.awayTeam}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('MMM d, yyyy').format(game.date)),
                              Text(
                                '${game.homeGoals}.${game.homeBehinds} (${game.homePoints}) - ${game.awayGoals}.${game.awayBehinds} (${game.awayPoints})',
                              ),
                              Text(
                                _getGameResult(game),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'details') {
                                _showGameDetails(game);
                              } else if (value == 'delete') {
                                _deleteGame(game);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'details',
                                child: Text('View Details'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                          onTap: () => _showGameDetails(game),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
