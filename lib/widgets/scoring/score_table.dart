import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/widgets/scoring/quarter_score_row.dart';
import 'package:scorecard/widgets/scoring/score_table_header.dart';
import 'package:scorecard/widgets/scoring/team_score_header.dart';
import 'package:scorecard/widgets/scoring/score_counter.dart';

/// Simplified score table widget that displays team scores by quarter
/// Uses atomic components for better maintainability
class ScoreTable extends StatelessWidget {
  final List<GameEvent> events;
  final String homeTeam;
  final String awayTeam;
  final String displayTeam;
  final bool isHomeTeam;
  final bool enabled;
  final bool showHeader;
  final bool showCounters;
  final int? currentQuarter;
  final bool isCompletedGame;

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
    this.currentQuarter,
    this.isCompletedGame = false,
  });

  Map<String, List<GameEvent>> _eventsByQuarter(int quarter) {
    try {
      if (events.isEmpty) {
        return {'team': []};
      }
      final teamEvents =
          events
              .where(
                (e) =>
                    e.quarter == quarter &&
                    e.team == displayTeam &&
                    (e.type == 'goal' || e.type == 'behind'),
              )
              .toList();
      return {'team': teamEvents};
    } catch (e) {
      AppLogger.warning(
        'Error calculating quarter scores',
        component: 'ScoreTable',
        data: 'Quarter $quarter, Team: $displayTeam',
      );
      return {'team': []};
    }
  }

  /// Calculate running totals up to a specific quarter
  Map<String, int> _calculateRunningTotals(int upToQuarter) {
    int totalGoals = 0;
    int totalBehinds = 0;

    for (int q = 1; q <= upToQuarter; q++) {
      final quarterEvents = _eventsByQuarter(q)['team'] ?? [];
      totalGoals += quarterEvents.where((e) => e.type == 'goal').length;
      totalBehinds += quarterEvents.where((e) => e.type == 'behind').length;
    }

    return {
      'goals': totalGoals,
      'behinds': totalBehinds,
      'points': totalGoals * 6 + totalBehinds,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorePanelAdapter>(
      builder: (context, scorePanelAdapter, _) {
        final currentQ = currentQuarter ?? scorePanelAdapter.selectedQuarter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header with total score
            if (showHeader)
              TeamScoreHeader(teamName: displayTeam, isHomeTeam: isHomeTeam),

            // Score counters - Show above the table when enabled
            if (showCounters && !isCompletedGame) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ScoreCounter(
                      label: 'Goals',
                      isGoal: true,
                      isHomeTeam: isHomeTeam,
                      enabled: enabled, // Pass the enabled state to the counter
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScoreCounter(
                      label: 'Behinds',
                      isGoal: false,
                      isHomeTeam: isHomeTeam,
                      enabled: enabled, // Pass the enabled state to the counter
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Score table
            Card(
              elevation: 0,
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Table header
                    const ScoreTableHeader(),

                    const SizedBox(height: 4),

                    // Quarter rows - Always show all 4 quarters
                    ...List.generate(
                      4, // Always show all 4 quarters
                      (index) {
                        final quarter = index + 1;
                        final quarterEvents =
                            _eventsByQuarter(quarter)['team'] ?? [];
                        final runningTotals = _calculateRunningTotals(quarter);

                        return QuarterScoreRow(
                          quarter: index, // 0-based index
                          quarterEvents: quarterEvents,
                          isCurrentQuarter:
                              quarter == currentQ && !isCompletedGame,
                          isFutureQuarter:
                              quarter > currentQ && !isCompletedGame,
                          runningGoals: runningTotals['goals']!,
                          runningBehinds: runningTotals['behinds']!,
                          runningPoints: runningTotals['points']!,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
