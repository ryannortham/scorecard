import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/services/game_state_service.dart';
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
    return Consumer<GameStateService>(
      builder: (context, gameStateService, _) {
        final currentQ = currentQuarter ?? gameStateService.selectedQuarter;

        return Card(
          elevation: 0,
          child: Column(
            children: [
              // Team header with total score (no padding)
              ScorePanelHeader(teamName: displayTeam, isHomeTeam: isHomeTeam),

              // Content with padding
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    const SizedBox(height: 4),

                    // Goal and behind counters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ScoreCounter(
                          label: 'Goals',
                          isGoal: true,
                          isHomeTeam: isHomeTeam,
                          enabled: enabled,
                        ),
                        ScoreCounter(
                          label: 'Behinds',
                          isGoal: false,
                          isHomeTeam: isHomeTeam,
                          enabled: enabled,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
