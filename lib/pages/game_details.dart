import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_record.dart';
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
                      for (int i = 1; i <= 4; i++) ...[
                        Builder(
                          builder: (context) {
                            final quarterEvents =
                                game.events.where((e) => e.quarter == i);
                            final homeGoals = quarterEvents
                                .where((e) =>
                                    e.team == game.homeTeam && e.type == 'goal')
                                .length;
                            final homeBehinds = quarterEvents
                                .where((e) =>
                                    e.team == game.homeTeam &&
                                    e.type == 'behind')
                                .length;
                            final awayGoals = quarterEvents
                                .where((e) =>
                                    e.team == game.awayTeam && e.type == 'goal')
                                .length;
                            final awayBehinds = quarterEvents
                                .where((e) =>
                                    e.team == game.awayTeam &&
                                    e.type == 'behind')
                                .length;

                            final homeQuarterPoints =
                                (homeGoals * 6) + homeBehinds;
                            final awayQuarterPoints =
                                (awayGoals * 6) + awayBehinds;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Q$i',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${game.homeTeam}: $homeGoals.$homeBehinds ($homeQuarterPoints)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${game.awayTeam}: $awayGoals.$awayBehinds ($awayQuarterPoints)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
