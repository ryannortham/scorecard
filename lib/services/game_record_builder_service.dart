import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/game_state_service.dart';

/// Service for building GameRecord instances from provider data
class GameRecordBuilderService {
  /// Builds a GameRecord from current provider data (for live data)
  static GameRecord buildFromProviders(
    BuildContext context,
    List<GameEvent> events,
  ) {
    final gameState = Provider.of<GameStateService>(context);

    return GameRecord(
      id: 'current-game', // Temporary ID for current game
      date: gameState.gameDate,
      homeTeam: gameState.homeTeam,
      awayTeam: gameState.awayTeam,
      quarterMinutes: gameState.quarterMinutes,
      isCountdownTimer: gameState.isCountdownTimer,
      events: events,
      homeGoals: gameState.homeGoals,
      homeBehinds: gameState.homeBehinds,
      awayGoals: gameState.awayGoals,
      awayBehinds: gameState.awayBehinds,
    );
  }
}
