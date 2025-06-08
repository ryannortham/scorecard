import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';

class GameDetailsPage extends StatelessWidget {
  final GameRecord game;

  const GameDetailsPage({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            children: [
              TextSpan(
                text: game.homeTeam,
                style: TextStyle(
                  color:
                      homeWins ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: homeWins ? FontWeight.w600 : null,
                ),
              ),
              const TextSpan(text: ' vs '),
              TextSpan(
                text: game.awayTeam,
                style: TextStyle(
                  color:
                      awayWins ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: awayWins ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add future menu options here if needed
            },
          ),
        ],
      ),
      body: GameDetailsWidget.fromStaticData(game: game),
    );
  }
}

class GameDetailsContent extends StatelessWidget {
  final GameRecord game;

  const GameDetailsContent({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GameDetailsWidget.fromStaticData(game: game);
  }
}
