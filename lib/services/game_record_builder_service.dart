import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';

/// Service for building GameRecord instances from provider data
class GameRecordBuilderService {
  /// Builds a GameRecord from current provider data (for live data)
  static GameRecord buildFromProviders(
    BuildContext context,
    List<GameEvent> events,
  ) {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(context);
    final scorePanelAdapter = Provider.of<ScorePanelAdapter>(context);

    return GameRecord(
      id: 'current-game', // Temporary ID for current game
      date: gameSetupAdapter.gameDate,
      homeTeam: gameSetupAdapter.homeTeam,
      awayTeam: gameSetupAdapter.awayTeam,
      quarterMinutes: gameSetupAdapter.quarterMinutes,
      isCountdownTimer: gameSetupAdapter.isCountdownTimer,
      events: events,
      homeGoals: scorePanelAdapter.homeGoals,
      homeBehinds: scorePanelAdapter.homeBehinds,
      awayGoals: scorePanelAdapter.awayGoals,
      awayBehinds: scorePanelAdapter.awayBehinds,
    );
  }
}
