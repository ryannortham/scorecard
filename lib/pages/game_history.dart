import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/game_history_service.dart';
import 'package:intl/intl.dart';
import 'settings.dart';
import 'game_details.dart';

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
      // Clean up duplicate games on load
      int removedCount = await GameHistoryService.deduplicateGames();
      if (removedCount > 0) {
        debugPrint('Removed $removedCount duplicate games');
      }

      // Load the deduplicated games
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

  /// Check if a game is in progress or completed
  bool _isGameComplete(GameRecord game) {
    // If no events, it's definitely not complete
    if (game.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_pause event in quarter 4
    bool hasQ4ClockPause =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_pause');
    if (hasQ4ClockPause) return true;

    return false;
  }

  /// Gets the current quarter based on the latest events
  int _getCurrentQuarter(GameRecord game) {
    if (game.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
  }

  /// Get simplified game progress text
  /// Returns either "Full Time" or "Q[N]: [elapsed time]"
  String _getGameProgressText(GameRecord game) {
    // Check if game is complete
    if (_isGameComplete(game)) {
      return 'Full Time';
    }

    // For games in progress, show quarter and time
    final currentQuarter = _getCurrentQuarter(game);

    // If no events, just show the quarter number with 00:00 time
    if (game.events.isEmpty) {
      return 'Q$currentQuarter: 00:00';
    }

    // Get all events for the current quarter
    final currentQuarterEvents =
        game.events.where((e) => e.quarter == currentQuarter).toList();
    if (currentQuarterEvents.isEmpty) {
      return 'Q$currentQuarter: 00:00';
    }

    // Get all scoring events (goals and behinds) for this quarter
    final scoringEvents = currentQuarterEvents
        .where((e) => e.type == 'goal' || e.type == 'behind')
        .toList();

    // If there are no scoring events, check for clock events
    if (scoringEvents.isEmpty) {
      final clockEvents = currentQuarterEvents
          .where((e) => e.type.startsWith('clock_'))
          .toList();

      // If there are clock events, use the latest one
      if (clockEvents.isNotEmpty) {
        final latestClockEvent = clockEvents.reduce(
            (a, b) => a.time.inMilliseconds > b.time.inMilliseconds ? a : b);

        final elapsedTimeMs = latestClockEvent.time.inMilliseconds;
        final minutes = (elapsedTimeMs / (1000 * 60)).floor();
        final seconds = ((elapsedTimeMs % (1000 * 60)) / 1000).floor();
        final formattedTime =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return 'Q$currentQuarter: $formattedTime';
      }

      return 'Q$currentQuarter: 00:00';
    }

    // Use the latest scoring event's time
    final latestScoringEvent = scoringEvents.reduce(
        (a, b) => a.time.inMilliseconds > b.time.inMilliseconds ? a : b);

    // Format the elapsed time
    final elapsedTimeMs = latestScoringEvent.time.inMilliseconds;
    final minutes = (elapsedTimeMs / (1000 * 60)).floor();
    final seconds = ((elapsedTimeMs % (1000 * 60)) / 1000).floor();
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return 'Q$currentQuarter: $formattedTime';
  }

  void _showGameDetails(GameRecord game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameDetailsPage(game: game),
      ),
    );
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No games yet',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Games are automatically saved when you start scoring',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
                          title: RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              children: [
                                TextSpan(
                                  text: game.homeTeam,
                                  style: TextStyle(
                                    color: game.homePoints > game.awayPoints
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight:
                                        game.homePoints > game.awayPoints
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                                TextSpan(
                                  text: ' vs ',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                TextSpan(
                                  text: game.awayTeam,
                                  style: TextStyle(
                                    color: game.awayPoints > game.homePoints
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight:
                                        game.awayPoints > game.homePoints
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(DateFormat('MMM d, yyyy')
                                      .format(game.date)),
                                  const SizedBox(width: 8),
                                  if (!_isGameComplete(game))
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiaryContainer
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getGameProgressText(game),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onTertiaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          '${game.homeGoals}.${game.homeBehinds} (${game.homePoints})',
                                      style: TextStyle(
                                        color: game.homePoints > game.awayPoints
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        fontWeight:
                                            game.homePoints > game.awayPoints
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - ',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${game.awayGoals}.${game.awayBehinds} (${game.awayPoints})',
                                      style: TextStyle(
                                        color: game.awayPoints > game.homePoints
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        fontWeight:
                                            game.awayPoints > game.homePoints
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteGame(game),
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
