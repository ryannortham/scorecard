// service for building score table widgets with proper data handling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/extensions/game_record_extensions.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/widgets/scoring/score_table.dart';

/// service for building score table widgets with proper data handling
class ScoreTableBuilder {
  /// builds a score table widget that correctly handles live vs static data
  static Widget buildScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
    required bool isLiveData,
    List<GameEvent>? liveEvents,
  }) {
    // Determine current quarter and completion status
    final currentQuarter =
        isLiveData
            ? context.read<GameStateService>().selectedQuarter
            : game.currentQuarter;

    final isCompleted = !isLiveData && game.isComplete;

    // Use live events for live data, game events for static data
    final events = isLiveData ? (liveEvents ?? []) : game.events;

    return ScoreTable(
      events: events,
      displayTeam: displayTeam,
      currentQuarter: currentQuarter,
      isCompletedGame: isCompleted,
      eventsByQuarter: (int quarter) {
        return game.getEventsByQuarter(displayTeam, quarter, events);
      },
      calculateRunningTotals: (int upToQuarter) {
        return game.calculateRunningTotals(displayTeam, upToQuarter, events);
      },
    );
  }
}
