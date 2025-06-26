import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';

/// A single row displaying quarter score data
class ScoreTableRow extends StatelessWidget {
  final int quarter; // 0-based quarter index
  final List<GameEvent> quarterEvents;
  final bool isCurrentQuarter;
  final bool isFutureQuarter;
  final int runningGoals;
  final int runningBehinds;
  final int runningPoints;

  const ScoreTableRow({
    super.key,
    required this.quarter,
    required this.quarterEvents,
    required this.isCurrentQuarter,
    required this.isFutureQuarter,
    required this.runningGoals,
    required this.runningBehinds,
    required this.runningPoints,
  });

  @override
  Widget build(BuildContext context) {
    final teamGoals = quarterEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = quarterEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color:
            isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Row(
        children: [
          // Quarter label
          SizedBox(
            width: 32,
            child: Text(
              'Q${quarter + 1}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),

          // Goals (Quarter + Total)
          _buildScoreColumn(context, teamGoals, runningGoals),

          // Behinds (Quarter + Total)
          _buildScoreColumn(context, teamBehinds, runningBehinds),

          // Points (Quarter + Total)
          _buildScoreColumn(context, teamPoints, runningPoints),
        ],
      ),
    );
  }

  /// Builds a score column with quarter score and running total
  Widget _buildScoreColumn(
    BuildContext context,
    int quarterScore,
    int runningTotal,
  ) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Center(
              child: Text(
                isFutureQuarter ? '' : quarterScore.toString(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color:
                      isFutureQuarter
                          ? Colors.transparent
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Text(
                  isFutureQuarter ? '' : runningTotal.toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
