import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/widgets/scoring/score_panel_header.dart';
import 'package:scorecard/widgets/scoring/score_counter.dart';
import 'score_table.dart';

/// Simplified score panel widget that displays team scores by quarter
/// Uses atomic components for better maintainability
class ScorePanel extends StatelessWidget {
  final List<GameEvent> events;
  final String homeTeam;
  final String awayTeam;
  final String displayTeam;
  final bool isHomeTeam;
  final bool enabled;
  final bool showCounters;
  final int? currentQuarter;
  final bool isCompletedGame;

  const ScorePanel({
    super.key,
    required this.events,
    required this.homeTeam,
    required this.awayTeam,
    required this.displayTeam,
    required this.isHomeTeam,
    this.enabled = true,
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
        component: 'ScorePanel',
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
          children: [
            // Team header with total score
            ScorePanelHeader(teamName: displayTeam, isHomeTeam: isHomeTeam),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScoreCounter(
                  label: 'Goals',
                  isGoal: true,
                  isHomeTeam: isHomeTeam,
                  enabled: enabled, // Pass the enabled state to the counter
                ),
                ScoreCounter(
                  label: 'Behinds',
                  isGoal: false,
                  isHomeTeam: isHomeTeam,
                  enabled: enabled, // Pass the enabled state to the counter
                ),
              ],
            ),

            // Score table
            ScoreTable(
              events: events,
              displayTeam: displayTeam,
              currentQuarter: currentQ,
              isCompletedGame: isCompletedGame,
              eventsByQuarter: _eventsByQuarter,
              calculateRunningTotals: _calculateRunningTotals,
            ),
          ],
        );
      },
    );
  }
}
