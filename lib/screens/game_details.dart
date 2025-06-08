import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/widgets/scoring/score_table.dart';
import 'package:goalkeeper/widgets/game_details/game_info_card.dart';
import 'package:goalkeeper/widgets/game_details/team_score_display.dart';
import 'package:goalkeeper/widgets/game_details/game_result_badge.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GameDetailsPage extends StatelessWidget {
  final GameRecord game;

  const GameDetailsPage({super.key, required this.game});

  /// Determines if the game is complete based on timer events
  bool _isGameComplete() {
    // If no events, it's definitely not complete
    if (game.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_pause event in quarter 4
    bool hasQ4ClockPause =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_pause');
    if (hasQ4ClockPause) return true;

    // Not enough evidence to consider the game complete
    return false;
  }

  /// Gets the current quarter based on the latest events
  int _getCurrentQuarter() {
    if (game.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
  }

  /// Gets the game status string for display
  String _getGameStatus() {
    // First check if game is complete
    if (_isGameComplete()) {
      return 'Full Time';
    }

    // For games not complete, show appropriate quarter status
    final currentQuarter = _getCurrentQuarter();

    // If no events, show game as just starting Q1
    if (game.events.isEmpty) {
      return 'Q1 starting';
    }

    // Check if we're in between quarters (current quarter has a pause but we also have events in the next quarter)
    bool hasNextQuarterEvents =
        game.events.any((e) => e.quarter > currentQuarter);
    bool hasCurrentQuarterPause = game.events
        .any((e) => e.quarter == currentQuarter && e.type == 'clock_pause');

    if (hasCurrentQuarterPause && !hasNextQuarterEvents) {
      // This quarter is paused but next quarter hasn't started
      return 'Q$currentQuarter paused';
    } else {
      // Quarter is in progress - find the latest event in this quarter to determine elapsed time
      final quarterEvents =
          game.events.where((e) => e.quarter == currentQuarter).toList();
      if (quarterEvents.isEmpty) {
        return 'Q$currentQuarter in progress';
      }

      // Get the max time from the current quarter's events to show elapsed time
      final maxTimeMs = quarterEvents
          .map((e) => e.time.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);

      // Format the time nicely
      final minutes = (maxTimeMs / (1000 * 60)).floor();
      final seconds = ((maxTimeMs % (1000 * 60)) / 1000).floor();
      final formattedTime =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return 'Q$currentQuarter: $formattedTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;
    final bool isComplete = _isGameComplete();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Card
            GameInfoCard(
              icon: Icons.calendar_today,
              title: 'Game Date',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(game.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(game.date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGameStatus(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Final Score Card
            GameInfoCard(
              icon: Icons.sports_score,
              title: 'Final Score',
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TeamScoreDisplay(
                          teamName: game.homeTeam,
                          goals: game.homeGoals,
                          behinds: game.homeBehinds,
                          points: game.homePoints,
                          isWinner: homeWins,
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
                        child: TeamScoreDisplay(
                          teamName: game.awayTeam,
                          goals: game.awayGoals,
                          behinds: game.awayBehinds,
                          points: game.awayPoints,
                          isWinner: awayWins,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GameResultBadge(
                    homeTeam: game.homeTeam,
                    awayTeam: game.awayTeam,
                    homePoints: game.homePoints,
                    awayPoints: game.awayPoints,
                    isGameComplete: isComplete,
                  ),
                ],
              ),
            ),

            // Quarter Breakdown Card
            if (game.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              GameInfoCard(
                icon: Icons.timeline,
                title: 'Quarter Breakdown',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ChangeNotifierProvider<ScorePanelProvider>(
                      create: (_) => ScorePanelProvider()
                        ..setSelectedQuarter(
                            _getCurrentQuarter()), // Use current quarter
                      child: ScoreTable(
                        events: game.events,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        displayTeam: game.homeTeam,
                        isHomeTeam: true,
                        enabled: false, // Disable interactions in details view
                        showHeader: false, // Hide team header
                        showCounters: false, // Hide score counters
                      ),
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
                    ChangeNotifierProvider<ScorePanelProvider>(
                      create: (_) => ScorePanelProvider()
                        ..setSelectedQuarter(
                            _getCurrentQuarter()), // Use current quarter
                      child: ScoreTable(
                        events: game.events,
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        displayTeam: game.awayTeam,
                        isHomeTeam: false,
                        enabled: false, // Disable interactions in details view
                        showHeader: false, // Hide team header
                        showCounters: false, // Hide score counters
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GameDetailsContent extends StatelessWidget {
  final GameRecord game;

  const GameDetailsContent({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Create a GameDetailsPage instance and extract its body content
    final gameDetailsPage = GameDetailsPage(game: game);

    // Access the body content from the GameDetailsPage's build method
    final scaffold = gameDetailsPage.build(context) as Scaffold;

    // Return just the body content without the Scaffold/AppBar
    return scaffold.body!;
  }
}
