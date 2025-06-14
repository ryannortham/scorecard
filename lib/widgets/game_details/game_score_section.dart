import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_info_card.dart';
import 'package:goalkeeper/widgets/game_details/game_result_badge.dart';
import 'package:goalkeeper/widgets/game_details/team_score_display.dart';

/// Widget that displays the final score section of a game
class GameScoreSection extends StatelessWidget {
  final GameRecord game;
  final bool isLiveData;
  final String? liveTitleOverride;

  const GameScoreSection({
    super.key,
    required this.game,
    required this.isLiveData,
    this.liveTitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;
    final bool isComplete = _isGameComplete(game);

    if (isLiveData) {
      return Consumer<ScorePanelAdapter>(
        builder: (context, scorePanelAdapter, child) {
          return GameInfoCard(
            icon: Icons.outlined_flag,
            title: liveTitleOverride ?? 'Current Score',
            content:
                _buildScoreContent(context, homeWins, awayWins, isComplete),
          );
        },
      );
    } else {
      return GameInfoCard(
        icon: Icons.outlined_flag,
        title: 'Final Score',
        content: _buildScoreContent(context, homeWins, awayWins, isComplete),
      );
    }
  }

  Widget _buildScoreContent(
      BuildContext context, bool homeWins, bool awayWins, bool isComplete) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TeamScoreDisplay(
                teamName: game.homeTeam,
                goals: game.homeGoals,
                behinds: game.homeBehinds,
                points: game.homePoints,
                isWinner: homeWins,
              ),
            ),
            Container(
              width: 2,
              height: 80,
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: TeamScoreDisplay(
                teamName: game.awayTeam,
                goals: game.awayGoals,
                behinds: game.awayBehinds,
                points: game.awayPoints,
                isWinner: awayWins,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GameResultBadge(
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          homePoints: game.homePoints,
          awayPoints: game.awayPoints,
          isGameComplete: isComplete,
          isHistoryMode: !isLiveData,
        ),
      ],
    );
  }

  /// Determines if the game is complete based on timer events
  bool _isGameComplete(GameRecord game) {
    if (game.events.isEmpty) return false;
    bool hasQ4ClockEnd =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_end');
    return hasQ4ClockEnd;
  }
}
