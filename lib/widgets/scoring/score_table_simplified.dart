import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';

import 'quarter_score_row.dart';
import 'score_counter.dart';
import 'score_table_header.dart';
import 'team_score_header.dart';

/// Simplified score table widget for displaying team scores by quarter
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

  /// Filter events by quarter and team
  List<GameEvent> _getQuarterEvents(int quarter) {
    if (events.isEmpty) return [];

    return events
        .where((e) =>
            e.quarter == quarter &&
            e.team == displayTeam &&
            (e.type == 'goal' || e.type == 'behind'))
        .toList();
  }

  /// Calculate running totals up to a specific quarter
  Map<String, int> _calculateRunningTotals(int upToQuarter) {
    int totalGoals = 0;
    int totalBehinds = 0;

    for (int q = 1; q <= upToQuarter; q++) {
      final quarterEvents = _getQuarterEvents(q);
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Header (conditionally shown)
          if (showHeader) ...[
            TeamScoreHeader(
              teamName: displayTeam,
              isHomeTeam: isHomeTeam,
            ),
            const SizedBox(height: 8),
          ],

          // Score Counters (conditionally shown)
          if (showCounters) ...[
            Row(
              children: [
                Expanded(
                  child: ScoreCounter(
                    label: 'Goals',
                    isHomeTeam: isHomeTeam,
                    isGoal: true,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScoreCounter(
                    label: 'Behinds',
                    isHomeTeam: isHomeTeam,
                    isGoal: false,
                    enabled: enabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Quarter Breakdown
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                // Table Header
                const ScoreTableHeader(),

                // Quarter Rows
                ...List.generate(
                    4, (index) => _buildQuarterRow(context, index)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterRow(BuildContext context, int quarterIndex) {
    final quarter = quarterIndex + 1;

    // Determine current quarter
    int effectiveCurrentQuarter;
    if (currentQuarter != null) {
      effectiveCurrentQuarter = currentQuarter!;
    } else if (isCompletedGame) {
      effectiveCurrentQuarter = 5; // Show all quarters for completed games
    } else {
      effectiveCurrentQuarter =
          Provider.of<ScorePanelAdapter>(context, listen: true).selectedQuarter;
    }

    final isCurrentQuarter = quarter == effectiveCurrentQuarter;
    final isFutureQuarter =
        quarter > effectiveCurrentQuarter && !isCompletedGame;

    // Get events and calculate totals
    final quarterEvents = _getQuarterEvents(quarter);
    final runningTotals = _calculateRunningTotals(quarter);

    return QuarterScoreRow(
      quarter: quarterIndex,
      quarterEvents: quarterEvents,
      isCurrentQuarter: isCurrentQuarter,
      isFutureQuarter: isFutureQuarter,
      runningGoals: runningTotals['goals']!,
      runningBehinds: runningTotals['behinds']!,
      runningPoints: runningTotals['points']!,
    );
  }
}
