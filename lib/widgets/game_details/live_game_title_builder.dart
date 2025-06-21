import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/services/game_state_service.dart';

/// Utility class for building live game titles
class LiveGameTitleBuilder {
  /// Builds the title for live games showing quarter and elapsed time
  static String buildTitle(
      BuildContext context, ScorePanelAdapter scorePanelAdapter) {
    final gameStateService = GameStateService.instance;

    final currentQuarter = scorePanelAdapter.selectedQuarter;
    final elapsedTimeMs = gameStateService.getElapsedTimeInQuarter();

    // Format elapsed time using the same method as timer widget
    final timeStr = StopWatchTimer.getDisplayTime(elapsedTimeMs,
        hours: false, milliSecond: true);
    // Remove the last character (centiseconds)
    final formattedTime = timeStr.substring(0, timeStr.length - 1);

    return 'In Progress: Q$currentQuarter $formattedTime';
  }
}
