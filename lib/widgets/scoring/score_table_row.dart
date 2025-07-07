import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/widgets/scoring/tally_display.dart';

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
      height: 32.0, // Fixed height to prevent jumping
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      decoration: BoxDecoration(
        color:
            isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Quarter label
            _buildQuarterColumn(context),
            // Goals column
            _buildScoreColumn(context, teamGoals, runningGoals, useTally: true),
            // Behinds column
            _buildScoreColumn(
              context,
              teamBehinds,
              runningBehinds,
              useTally: true,
            ),
            // Points column
            _buildScoreColumn(
              context,
              teamPoints,
              runningPoints,
              useTally: false,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the quarter column
  Widget _buildQuarterColumn(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          'Q${quarter + 1}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  /// Builds a score column with quarter score and running total
  Widget _buildScoreColumn(
    BuildContext context,
    int quarterScore,
    int runningTotal, {
    required bool useTally,
  }) {
    return Expanded(
      child: SizedBox(
        height: double.infinity, // Take full available height
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Center(
                child:
                    isFutureQuarter
                        ? const SizedBox.shrink()
                        : TallyDisplay(
                          value: quarterScore,
                          textStyle: Theme.of(context).textTheme.labelMedium,
                          useTally: useTally,
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
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Center(
                  child: Text(
                    isFutureQuarter ? '' : runningTotal.toString(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
