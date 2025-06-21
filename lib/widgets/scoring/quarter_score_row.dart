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
        color: isCurrentQuarter
            ? Theme.of(context)
                .colorScheme
                .secondaryContainer
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
                        ? Theme.of(context).colorScheme.secondary
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
                              .secondary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningGoals.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.secondary
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
                              .secondary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningBehinds.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.secondary
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
                              .secondary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '-' : runningPoints.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentQuarter
                                  ? Theme.of(context).colorScheme.secondary
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
