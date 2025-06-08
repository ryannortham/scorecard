import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/widgets/score_table.dart';
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(game.date),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGameStatus(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
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
                    // Only show win message if game is complete
                    if (isComplete) ...[
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                          enabled:
                              false, // Disable interactions in details view
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
                          enabled:
                              false, // Disable interactions in details view
                          showHeader: false, // Hide team header
                          showCounters: false, // Hide score counters
                        ),
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

/// Content-only version of GameDetailsPage for use in tabs
/// This widget contains all the game details content without Scaffold/AppBar
class GameDetailsContent extends StatelessWidget {
  final GameRecord game;

  const GameDetailsContent({super.key, required this.game});

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

    if (hasCurrentQuarterPause && hasNextQuarterEvents) {
      return 'Q${currentQuarter + 1} starting';
    } else if (hasCurrentQuarterPause) {
      return 'Q$currentQuarter ended';
    } else {
      return 'Q$currentQuarter in progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;
    final bool isComplete = _isGameComplete();

    return SingleChildScrollView(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(game.date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(game.date),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
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

          // Game Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Game Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quarter Duration',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          Text(
                            '${game.quarterMinutes} minutes',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Timer Mode',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          Text(
                            game.isCountdownTimer ? 'Countdown' : 'Count Up',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    isComplete ? Icons.flag : Icons.play_circle,
                    color: isComplete
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Game Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGameStatus(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: isComplete
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Score Display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Teams and Final Scores Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Home Team Score
                      Column(
                        children: [
                          Text(
                            game.homeTeam,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: homeWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: homeWins ? FontWeight.w600 : null,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${game.homeGoals}.${game.homeBehinds}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: homeWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '(${game.homePoints})',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: homeWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: homeWins ? FontWeight.w600 : null,
                                ),
                          ),
                        ],
                      ),

                      // VS Separator
                      Column(
                        children: [
                          Text(
                            'vs',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),

                      // Away Team Score
                      Column(
                        children: [
                          Text(
                            game.awayTeam,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: awayWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: awayWins ? FontWeight.w600 : null,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${game.awayGoals}.${game.awayBehinds}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: awayWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '(${game.awayPoints})',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: awayWins
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: awayWins ? FontWeight.w600 : null,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Only show win message if game is complete
                  if (isComplete) ...[
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quarter by Quarter Details
          if (game.events.isNotEmpty) ...[
            Text(
              'Quarter by Quarter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, quarterIndex) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quarter header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        'Quarter ${quarterIndex + 1}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),

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
                        ..setSelectedQuarter(quarterIndex + 1),
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
                        ..setSelectedQuarter(quarterIndex + 1),
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

                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
