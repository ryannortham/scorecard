import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/widgets/scoring/score_table_row.dart';

/// Score table widget that displays quarter-by-quarter scores
class ScoreTable extends StatelessWidget {
  final List<GameEvent> events;
  final String displayTeam;
  final int currentQuarter;
  final bool isCompletedGame;
  final Map<String, List<GameEvent>> Function(int quarter) eventsByQuarter;
  final Map<String, int> Function(int upToQuarter) calculateRunningTotals;

  const ScoreTable({
    super.key,
    required this.events,
    required this.displayTeam,
    required this.currentQuarter,
    required this.isCompletedGame,
    required this.eventsByQuarter,
    required this.calculateRunningTotals,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          // Table header
          Container(
            // Top border and padding
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),

            // Table header row
            child: Row(
              children: [
                const SizedBox(width: 18), // Quarter column
                Expanded(
                  child: Text(
                    'Goals',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Behinds',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Points',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),

          // Table rows for each quarter
          ...List.generate(4, (index) {
            final quarter = index + 1;
            final quarterEvents = eventsByQuarter(quarter)['team'] ?? [];
            final runningTotals = calculateRunningTotals(quarter);

            return ScoreTableRow(
              quarter: index, // 0-based index
              quarterEvents: quarterEvents,
              isCurrentQuarter: quarter == currentQuarter && !isCompletedGame,
              isFutureQuarter: quarter > currentQuarter && !isCompletedGame,
              runningGoals: runningTotals['goals'] ?? 0,
              runningBehinds: runningTotals['behinds'] ?? 0,
              runningPoints: runningTotals['points'] ?? 0,
            );
          }),

          // Bottom border
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
