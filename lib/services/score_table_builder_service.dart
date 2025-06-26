import 'package:flutter/material.dart';

import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/game_analysis_service.dart';
import 'package:scorecard/widgets/scoring/score_table.dart';

/// Service for building score table widgets with proper data handling
class ScoreTableBuilderService {
  /// Builds a score table widget that correctly handles live vs static data
  static Widget buildScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
    required bool isLiveData,
    List<GameEvent>? liveEvents,
    ScorePanelAdapter? scorePanelAdapter,
  }) {
    // Determine current quarter and completion status
    final int currentQuarter =
        isLiveData && scorePanelAdapter != null
            ? scorePanelAdapter.selectedQuarter
            : GameAnalysisService.getCurrentQuarter(game);

    final bool isCompleted =
        isLiveData
            ? false // Live games are not completed
            : GameAnalysisService.isGameComplete(game);

    // Use live events for live data, game events for static data
    final List<GameEvent> events =
        isLiveData ? (liveEvents ?? []) : game.events;

    return ScoreTable(
      events: events,
      displayTeam: displayTeam,
      currentQuarter: currentQuarter,
      isCompletedGame: isCompleted,
      eventsByQuarter: (int quarter) {
        return GameAnalysisService.getEventsByQuarter(
          events,
          displayTeam,
          quarter,
        );
      },
      calculateRunningTotals: (int upToQuarter) {
        return GameAnalysisService.calculateRunningTotals(
          events,
          displayTeam,
          upToQuarter,
        );
      },
    );
  }
}
