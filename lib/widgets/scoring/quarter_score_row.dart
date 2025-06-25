import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';

/// A single row displaying quarter score data
class QuarterScoreRow extends StatelessWidget {
  final int quarter; // 0-based quarter index
  final List<GameEvent> quarterEvents;
  final bool isCurrentQuarter;
  final bool isFutureQuarter;
  final int runningGoals;
  final int runningBehinds;
  final int runningPoints;

  const QuarterScoreRow({
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
        borderRadius:
            quarter ==
                    3 // Only for fourth quarter (0-based index)
                ? const BorderRadius.only(
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                )
                : null,
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
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      isFutureQuarter ? '' : teamGoals.toString(),
                      // style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      //   fontWeight: FontWeight.w600,
                      // ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '' : runningGoals.toString(),
                        // style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        //   fontWeight: FontWeight.w700,
                        //   color:
                        //       isCurrentQuarter
                        //           ? Theme.of(
                        //             context,
                        //           ).colorScheme.onSecondaryContainer
                        //           : Theme.of(context).colorScheme.onSurface,
                        // ),
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
                      isFutureQuarter ? '' : teamBehinds.toString(),
                      // style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      //   fontWeight: FontWeight.w600,
                      //   color:
                      //       isFutureQuarter
                      //           ? Theme.of(
                      //             context,
                      //           ).colorScheme.onSurface.withValues(alpha: 0.4)
                      //           : null,
                      // ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isCurrentQuarter
                              ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '' : runningBehinds.toString(),
                        // style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        //   fontWeight: FontWeight.w700,
                        //   color:
                        //       isCurrentQuarter
                        //           ? Theme.of(
                        //             context,
                        //           ).colorScheme.onSecondaryContainer
                        //           : Theme.of(context).colorScheme.onSurface,
                        // ),
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
                      isFutureQuarter ? '' : teamPoints.toString(),
                      // style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      //   fontWeight: FontWeight.w700,
                      //   color:
                      //       isFutureQuarter
                      //           ? Theme.of(
                      //             context,
                      //           ).colorScheme.onSurface.withValues(alpha: 0.4)
                      //           : null,
                      // ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isCurrentQuarter
                              ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '' : runningPoints.toString(),
                        // style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        //   fontWeight: FontWeight.w700,
                        //   color:
                        //       isCurrentQuarter
                        //           ? Theme.of(
                        //             context,
                        //           ).colorScheme.onSecondaryContainer
                        //           : Theme.of(context).colorScheme.onSurface,
                        // ),
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
