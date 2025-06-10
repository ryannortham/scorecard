// filepath: /Users/ryan.northam/code/goalkeeper/lib/screens/game_container.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/screens/scoring.dart';
import 'settings.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  final GlobalKey<ScoringState> _scoringKey = GlobalKey<ScoringState>();

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit Game?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    // Always show exit confirmation when leaving an active game
    return await _showExitConfirmation();
  }

  @override
  Widget build(BuildContext context) {
    final gameSetupProvider = Provider.of<GameSetupAdapter>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Settings(title: 'Settings'),
                  ),
                );
                // No need to update game setup since quarter minutes and countdown timer
                // are no longer in settings - they're managed on the game setup screen
              },
            ),
          ],
        ),
        body: Scoring(key: _scoringKey, title: 'Scoring'),
      ),
    );
  }
}
