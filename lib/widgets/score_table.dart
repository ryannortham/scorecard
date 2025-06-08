// Score table widget for displaying team scores by quarter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/score_counter.dart';

class ScoreTable extends StatelessWidget {
  final List<GameEvent> events;
  final String homeTeam;
  final String awayTeam;
  final String displayTeam; // The team whose data this table should display
  final bool isHomeTeam; // Whether this is the home team
  final bool enabled; // Whether the counters should be enabled
  final bool showHeader; // Whether to show the team header
  final bool showCounters; // Whether to show the score counters
  // Removed isGameDetailsView parameter as we want consistent behavior

  const ScoreTable({
    super.key,
    required this.events,
    required this.homeTeam,
    required this.awayTeam,
    required this.displayTeam,
    required this.isHomeTeam,
    this.enabled = true,
    this.showHeader = true,
    this.showCounters = true,
  });

  Map<String, List<GameEvent>> _eventsByQuarter(int quarter) {
    try {
      if (events.isEmpty) {
        return {'team': []};
      }
      final teamEvents = events
          .where((e) =>
              e.quarter == quarter &&
              e.team == displayTeam &&
              (e.type == 'goal' || e.type == 'behind'))
          .toList();
      return {'team': teamEvents};
    } catch (e) {
      // Return empty list as fallback if any error occurs
      return {'team': []};
    }
  }

  static const List<String> _quarterLabels = ['1st', '2nd', '3rd', '4th'];

  TableRow createRow(BuildContext context, int quarter) {
    final currentQuarter =
        Provider.of<ScorePanelProvider>(context, listen: true).selectedQuarter;
    final isCurrentQuarter = quarter + 1 == currentQuarter;

    // Determine if this is a future quarter - consistent behavior in all views
    final isFutureQuarter = quarter + 1 > currentQuarter;

    // For future quarters, show blank cells
    if (isFutureQuarter) {
      return TableRow(
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        children: [
          // Quarter label
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Text(_quarterLabels[quarter]),
          ),
          // Goals column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
          ),
          // Behinds column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
          ),
          // Points column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final byQuarter = _eventsByQuarter(quarter + 1);
    final teamEvents = byQuarter['team'] ?? [];
    final teamGoals = teamEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = teamEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    // Calculate running totals up to this quarter
    int runningGoals = 0;
    int runningBehinds = 0;
    try {
      for (int q = 1; q <= quarter + 1; q++) {
        final qEvents = _eventsByQuarter(q);
        final qTeamEvents = qEvents['team'] ?? [];
        runningGoals += qTeamEvents.where((e) => e.type == 'goal').length;
        runningBehinds += qTeamEvents.where((e) => e.type == 'behind').length;
      }
    } catch (e) {
      // Fallback to just this quarter's values if running total calculation fails
      runningGoals = teamGoals;
      runningBehinds = teamBehinds;
    }
    final runningPoints = runningGoals * 6 + runningBehinds;

    return TableRow(
      decoration: BoxDecoration(
        color: isCurrentQuarter
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
      ),
      children: [
        // Quarter label
        Container(
          height: 24,
          alignment: Alignment.center,
          child: Text(_quarterLabels[quarter]),
        ),
        // Goals column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Center(
                  child: Text(teamGoals.toString()),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh
                            .withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      runningGoals.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Behinds column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Center(
                  child: Text(teamBehinds.toString()),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh
                            .withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      runningBehinds.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Points column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Center(
                  child: Text(
                    teamPoints.toString(),
                    style: boldStyle,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.18)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh
                            .withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Text(
                      runningPoints.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.w600);

  Widget createCell(BuildContext context, String text,
      {bool isBold = false, bool isSmall = false}) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          text,
          style: isSmall
              ? Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  )
              : Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  ),
        ),
      ),
    );
  }

  // This method is no longer used as we're creating a custom header row
  TableRow createSpecialRow(BuildContext context, List<String> values) {
    return TableRow(
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[0], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[1], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[2], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[3], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condensed Team Header (conditionally shown)
          if (showHeader) ...[
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayTeam,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Consumer<ScorePanelProvider>(
                    builder: (context, scorePanelProvider, _) {
                      final goals =
                          scorePanelProvider.getCount(isHomeTeam, true);
                      final behinds =
                          scorePanelProvider.getCount(isHomeTeam, false);
                      final points = goals * 6 + behinds;

                      return Text(
                        points.toString(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Condensed Counter Controls (conditionally shown)
          if (showCounters) ...[
            Consumer<ScorePanelProvider>(
              builder: (context, scorePanelProvider, _) {
                return Row(
                  children: [
                    Expanded(
                      child: ScoreCounter(
                        label: 'Goals',
                        isHomeTeam: isHomeTeam,
                        isGoal: true,
                        scorePanelProvider: scorePanelProvider,
                        enabled: enabled,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ScoreCounter(
                        label: 'Behinds',
                        isHomeTeam: isHomeTeam,
                        isGoal: false,
                        scorePanelProvider: scorePanelProvider,
                        enabled: enabled,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],

          // Quarter Breakdown with Running Totals
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                // Main Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHigh
                        .withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32), // Quarter column
                      Expanded(
                        child: Center(
                          child: Text(
                            'Goals',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Behinds',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Points',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quarter rows
                for (int i = 0; i < 4; i++) _buildQuarterRow(context, i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterRow(BuildContext context, int quarter) {
    final currentQuarter =
        Provider.of<ScorePanelProvider>(context, listen: true).selectedQuarter;
    final isCurrentQuarter = quarter + 1 == currentQuarter;

    // Determine if this is a future quarter - consistent behavior in all views
    final isFutureQuarter = quarter + 1 > currentQuarter;

    final byQuarter = _eventsByQuarter(quarter + 1);
    final teamEvents = byQuarter['team'] ?? [];
    final teamGoals = teamEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = teamEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    // Calculate running totals up to this quarter
    int runningGoals = 0;
    int runningBehinds = 0;
    if (!isFutureQuarter) {
      try {
        for (int q = 1; q <= quarter + 1; q++) {
          final qEvents = _eventsByQuarter(q);
          final qTeamEvents = qEvents['team'] ?? [];
          runningGoals += qTeamEvents.where((e) => e.type == 'goal').length;
          runningBehinds += qTeamEvents.where((e) => e.type == 'behind').length;
        }
      } catch (e) {
        runningGoals = teamGoals;
        runningBehinds = teamBehinds;
      }
    }
    final runningPoints = runningGoals * 6 + runningBehinds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isCurrentQuarter
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3)
            : null,
        border: Border(
          bottom: quarter < 3
              ? BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Quarter label
          SizedBox(
            width: 32,
            child: Text(
              'Q${quarter + 1}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isCurrentQuarter ? FontWeight.w700 : FontWeight.w600,
                    color: isCurrentQuarter
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            ),
          ),

          // Goals (Quarter + Total)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      isFutureQuarter ? '-' : teamGoals.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isFutureQuarter
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)
                                : null,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentQuarter
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningGoals.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Behinds (Quarter + Total)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      isFutureQuarter ? '-' : teamBehinds.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isFutureQuarter
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)
                                : null,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentQuarter
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningBehinds.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Points (Quarter + Total)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      isFutureQuarter ? '-' : teamPoints.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isFutureQuarter
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)
                                : null,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentQuarter
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningPoints.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
