import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_info_card.dart';
import 'package:goalkeeper/widgets/game_details/game_score_section.dart';
import 'package:goalkeeper/widgets/game_details/quarter_breakdown_section.dart';
import 'package:goalkeeper/widgets/scoring/score_table.dart';

/// A screenshot-optimized version of GameDetailsWidget that uses the same components
/// but in a fixed-height, non-scrollable layout designed for sharing
class GameDetailsScreenshotWidget extends StatelessWidget {
  final GameRecord? staticGame;
  final List<GameEvent>? liveEvents;
  final bool isLiveData;

  const GameDetailsScreenshotWidget.fromStaticData({
    super.key,
    required GameRecord game,
  })  : staticGame = game,
        liveEvents = null,
        isLiveData = false;

  const GameDetailsScreenshotWidget.fromLiveData({
    super.key,
    required List<GameEvent> events,
  })  : staticGame = null,
        liveEvents = events,
        isLiveData = true;

  @override
  Widget build(BuildContext context) {
    final game = isLiveData ? _buildGameFromProviders(context) : staticGame!;

    return Container(
      width: 400,
      height: 800,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match Info Card - same as original
            GameInfoCard(
              icon: Icons.sports_rugby,
              title: '${game.homeTeam} vs ${game.awayTeam}',
              content: Text(
                DateFormat('EEEE, MMM d, yyyy').format(game.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 16),

            // Final Score Card - same as original
            isLiveData
                ? Consumer<ScorePanelAdapter>(
                    builder: (context, scorePanelAdapter, child) {
                      return GameScoreSection(
                        game: game,
                        isLiveData: true,
                      );
                    },
                  )
                : GameScoreSection(
                    game: game,
                    isLiveData: false,
                  ),

            // Quarter Breakdown Card - same as original but in remaining space
            const SizedBox(height: 16),
            Expanded(
              child: QuarterBreakdownSection(
                game: game,
                isLiveData: isLiveData,
                liveEvents: liveEvents,
                scoreTableBuilder: _buildScoreTable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  GameRecord _buildGameFromProviders(BuildContext context) {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final scorePanelAdapter =
        Provider.of<ScorePanelAdapter>(context, listen: false);

    return GameRecord(
      id: 'current-game',
      date: gameSetupAdapter.gameDate,
      homeTeam: gameSetupAdapter.homeTeam,
      awayTeam: gameSetupAdapter.awayTeam,
      quarterMinutes: gameSetupAdapter.quarterMinutes,
      isCountdownTimer: gameSetupAdapter.isCountdownTimer,
      events: liveEvents ?? [],
      homeGoals: scorePanelAdapter.homeGoals,
      homeBehinds: scorePanelAdapter.homeBehinds,
      awayGoals: scorePanelAdapter.awayGoals,
      awayBehinds: scorePanelAdapter.awayBehinds,
    );
  }

  Widget _buildScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
  }) {
    return ScoreTable(
      events: game.events,
      homeTeam: game.homeTeam,
      awayTeam: game.awayTeam,
      displayTeam: displayTeam,
      isHomeTeam: isHomeTeam,
      enabled: false, // Always disabled for screenshots
    );
  }
}
