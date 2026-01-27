// score table widget displaying quarter-by-quarter scores

import 'package:flutter/material.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/scoring/score_table_row.dart';

/// score table widget that displays quarter-by-quarter scores
class ScoreTable extends StatelessWidget {
  const ScoreTable({
    required this.events,
    required this.displayTeam,
    required this.currentQuarter,
    required this.isCompletedGame,
    required this.eventsByQuarter,
    required this.calculateRunningTotals,
    super.key,
  });
  final List<GameEvent> events;
  final String displayTeam;
  final int currentQuarter;
  final bool isCompletedGame;
  final Map<String, List<GameEvent>> Function(int quarter) eventsByQuarter;
  final Map<String, int> Function(int upToQuarter) calculateRunningTotals;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Stack(
        children: [
          // Main table content
          Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: _buildHeaderRow(context),
              ),

              // Table rows for each quarter
              ...List.generate(4, (index) {
                final quarter = index + 1;
                final quarterEvents = eventsByQuarter(quarter)['team'] ?? [];
                final runningTotals = calculateRunningTotals(quarter);
                final previousTotals =
                    quarter > 1
                        ? calculateRunningTotals(quarter - 1)
                        : {'goals': 0, 'behinds': 0, 'points': 0};

                return ScoreTableRow(
                  quarter: index, // 0-based index
                  quarterEvents: quarterEvents,
                  isCurrentQuarter:
                      quarter == currentQuarter && !isCompletedGame,
                  isFutureQuarter: quarter > currentQuarter && !isCompletedGame,
                  previousRunningGoals: previousTotals['goals'] ?? 0,
                  previousRunningBehinds: previousTotals['behinds'] ?? 0,
                  runningGoals: runningTotals['goals'] ?? 0,
                  runningBehinds: runningTotals['behinds'] ?? 0,
                  runningPoints: runningTotals['points'] ?? 0,
                );
              }),

              // Bottom border
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          // Continuous vertical dividers overlay
          _buildVerticalDividers(context),
        ],
      ),
    );
  }

  /// builds the header row with proper column alignment
  Widget _buildHeaderRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Quarter column - match data row structure exactly
          const SizedBox(width: 28, child: Center(child: SizedBox())),
          // Goals column
          Expanded(
            child: Center(
              child: Text(
                'Goals',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          // Behinds column
          Expanded(
            child: Center(
              child: Text(
                'Behinds',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          // Points column
          Expanded(
            child: Center(
              child: Text(
                'Points',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// builds continuous vertical dividers that span the entire table height
  Widget _buildVerticalDividers(BuildContext context) {
    final dividerColor = context.colors.outline.withValues(alpha: 0.15);

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            // Quarter column (28px width)
            const SizedBox(width: 28),
            // First divider (after quarter column)
            Container(width: 1, color: dividerColor),
            // Goals column - flexible space
            const Expanded(child: SizedBox()),
            // Second divider (after goals column)
            Container(width: 1, color: dividerColor),
            // Behinds column - flexible space
            const Expanded(child: SizedBox()),
            // Third divider (after behinds column)
            Container(width: 1, color: dividerColor),
            // Points column - flexible space
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
