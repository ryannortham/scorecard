import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/widgets/scoring/score_table.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GameDetailsTab extends StatelessWidget {
  final GameRecord? game;

  const GameDetailsTab({super.key, this.game});

  /// Determines if the game is complete based on timer events
  bool _isGameComplete(GameRecord gameRecord) {
    // If no events, it's definitely not complete
    if (gameRecord.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_pause event in quarter 4
    bool hasQ4ClockPause =
        gameRecord.events.any((e) => e.quarter == 4 && e.type == 'clock_pause');
    if (hasQ4ClockPause) return true;

    // Not enough evidence to consider the game complete
    return false;
  }

  /// Gets the current quarter based on the latest events
  int _getCurrentQuarter(GameRecord gameRecord) {
    if (gameRecord.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        gameRecord.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
  }

  /// Gets the game status string for display
  String _getGameStatus(GameRecord gameRecord) {
    // First check if game is complete
    if (_isGameComplete(gameRecord)) {
      return 'Full Time';
    }

    // For games not complete, show appropriate quarter status
    final currentQuarter = _getCurrentQuarter(gameRecord);

    // If no events, show game as just starting Q1
    if (gameRecord.events.isEmpty) {
      return 'Q1 starting';
    }

    // Check if the current quarter has a clock_pause (quarter ended)
    bool currentQuarterEnded = gameRecord.events
        .any((e) => e.quarter == currentQuarter && e.type == 'clock_pause');

    if (currentQuarterEnded) {
      // If it's quarter 4, should have been caught by _isGameComplete above
      if (currentQuarter < 4) {
        return 'Q${currentQuarter + 1} starting';
      } else {
        return 'Full Time'; // Fallback
      }
    } else {
      // Quarter is in progress
      return 'Q$currentQuarter in progress';
    }
  }

  GameRecord _buildCurrentGame(BuildContext context) {
    final gameSetupProvider = Provider.of<GameSetupProvider>(context);
    final scorePanelProvider = Provider.of<ScorePanelProvider>(context);

    return GameRecord(
      id: 'current',
      date: DateTime.now(),
      homeTeam: gameSetupProvider.homeTeam,
      awayTeam: gameSetupProvider.awayTeam,
      quarterMinutes: gameSetupProvider.quarterMinutes,
      isCountdownTimer: gameSetupProvider.isCountdownTimer,
      events: [], // Events would come from the scoring tab
      homeGoals: scorePanelProvider.homeGoals,
      homeBehinds: scorePanelProvider.homeBehinds,
      awayGoals: scorePanelProvider.awayGoals,
      awayBehinds: scorePanelProvider.awayBehinds,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use provided game or build current game from providers
    final gameRecord = game ?? _buildCurrentGame(context);

    final homeScore = (gameRecord.homeGoals * 6) + gameRecord.homeBehinds;
    final awayScore = (gameRecord.awayGoals * 6) + gameRecord.awayBehinds;
    final homeWins = homeScore > awayScore;
    final awayWins = awayScore > homeScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teams
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineSmall,
                      children: [
                        TextSpan(
                          text: gameRecord.homeTeam,
                          style: TextStyle(
                            color: homeWins
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: homeWins ? FontWeight.w600 : null,
                          ),
                        ),
                        const TextSpan(text: ' vs '),
                        TextSpan(
                          text: gameRecord.awayTeam,
                          style: TextStyle(
                            color: awayWins
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight: awayWins ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Game Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isGameComplete(gameRecord)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getGameStatus(gameRecord),
                      style: TextStyle(
                        color: _isGameComplete(gameRecord)
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy')
                              .format(gameRecord.date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat('h:mm a').format(gameRecord.date),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              gameRecord.homeTeam,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              homeScore.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: homeWins
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${gameRecord.homeGoals}.${gameRecord.homeBehinds}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              gameRecord.awayTeam,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              awayScore.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: awayWins
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${gameRecord.awayGoals}.${gameRecord.awayBehinds}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quarter by Quarter Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quarter by Quarter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ScoreTable(
                    events: gameRecord.events,
                    homeTeam: gameRecord.homeTeam,
                    awayTeam: gameRecord.awayTeam,
                    displayTeam: gameRecord.homeTeam,
                    isHomeTeam: true,
                    enabled: false,
                    showHeader: false,
                    showCounters: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Card
          if (gameRecord.events.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatistic(
                      context,
                      'Total Events',
                      gameRecord.events.length.toString(),
                      Icons.list_alt,
                    ),
                    const SizedBox(height: 8),
                    _buildStatistic(
                      context,
                      'Quarters Played',
                      _getCurrentQuarter(gameRecord).toString(),
                      Icons.access_time,
                    ),
                    if (_isGameComplete(gameRecord)) ...[
                      const SizedBox(height: 8),
                      _buildStatistic(
                        context,
                        'Game Status',
                        'Complete',
                        Icons.check_circle,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistic(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
