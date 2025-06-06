import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:intl/intl.dart';

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
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
            onPressed: () {
              // Add future menu options here if needed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(game.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Final Score Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_score,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Final Score',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                game.homeTeam,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: homeWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight:
                                          homeWins ? FontWeight.w600 : null,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${game.homePoints}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: homeWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${game.homeGoals}.${game.homeBehinds}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: homeWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight:
                                          homeWins ? FontWeight.w600 : null,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                game.awayTeam,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: awayWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight:
                                          awayWins ? FontWeight.w600 : null,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${game.awayPoints}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: awayWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${game.awayGoals}.${game.awayBehinds}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: awayWins
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                      fontWeight:
                                          awayWins ? FontWeight.w600 : null,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: game.homePoints != game.awayPoints
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          game.homePoints != game.awayPoints
                              ? homeWins
                                  ? '${game.homeTeam} Won By ${game.homePoints - game.awayPoints}'
                                  : '${game.awayTeam} Won By ${game.awayPoints - game.homePoints}'
                              : 'Draw',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: game.homePoints != game.awayPoints
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quarter Breakdown Card
            if (game.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quarter Breakdown',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Home Team Label
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          game.homeTeam,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: homeWins
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                      ),

                      // Home Team Score Table
                      ScoreTable(
                        events: game.events,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        displayTeam: game.homeTeam,
                        isHomeTeam: true,
                        enabled: false, // Disable interactions in details view
                        showHeader: false, // Hide team header
                        showCounters: false, // Hide score counters
                      ),

                      const SizedBox(height: 16),

                      // Away Team Label
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          game.awayTeam,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: awayWins
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                      ),

                      // Away Team Score Table
                      ScoreTable(
                        events: game.events,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        displayTeam: game.awayTeam,
                        isHomeTeam: false,
                        enabled: false, // Disable interactions in details view
                        showHeader: false, // Hide team header
                        showCounters: false, // Hide score counters
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
