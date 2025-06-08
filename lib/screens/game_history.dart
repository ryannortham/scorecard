import 'package:flutter/material.dart';
import '../providers/game_record.dart';
import '../services/game_history_service.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/game_history/game_history_card.dart';
import 'game_details.dart';
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
      appBar: CustomAppBar(
        title: 'Game History',
        onSettingsPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const Settings(title: 'Settings'),
          ),
        ),
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
                      return GameHistoryCard(
                        game: game,
                        onTap: () => _showGameDetails(game),
                        onDelete: () => _deleteGame(game),
                      );
                    },
                  ),
                ),
    );
  }
}
