import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/widgets/game_details/game_info_card.dart';
import 'package:scorecard/widgets/game_details/game_result_badge.dart';
import 'package:scorecard/widgets/game_details/team_score_display.dart';

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
            content: _buildScoreContent(
              context,
              homeWins,
              awayWins,
              isComplete,
            ),
          );
        },
      );
    } else {
      // For static data, check if the game is complete to determine the title
      final title = isComplete ? 'Final Score' : _buildStaticGameTitle(game);
      return GameInfoCard(
        icon: Icons.outlined_flag,
        title: title,
        content: _buildScoreContent(context, homeWins, awayWins, isComplete),
      );
    }
  }

  Widget _buildScoreContent(
    BuildContext context,
    bool homeWins,
    bool awayWins,
    bool isComplete,
  ) {
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
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
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
          isHistoryMode:
              isComplete, // Use game completion status instead of !isLiveData
        ),
      ],
    );
  }

  /// Determines if the game is complete based on timer events
  bool _isGameComplete(GameRecord game) {
    if (game.events.isEmpty) return false;
    bool hasQ4ClockEnd = game.events.any(
      (e) => e.quarter == 4 && e.type == 'clock_end',
    );
    return hasQ4ClockEnd;
  }

  /// Builds the title for in-progress games using static game data
  String _buildStaticGameTitle(GameRecord game) {
    // Find the current quarter from events
    int currentQuarter = 1;
    if (game.events.isNotEmpty) {
      // Get the highest quarter with events, but not if it has a clock_end
      final activeQuarters =
          game.events
              .where((e) => e.type != 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      final endedQuarters =
          game.events
              .where((e) => e.type == 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      if (activeQuarters.isNotEmpty) {
        currentQuarter = activeQuarters.reduce((a, b) => a > b ? a : b);
        // If this quarter has ended, we're in the next quarter
        if (endedQuarters.contains(currentQuarter) && currentQuarter < 4) {
          currentQuarter++;
        }
      }
    }

    // Calculate elapsed time in current quarter
    Duration elapsedTime = Duration.zero;
    if (game.events.isNotEmpty) {
      // Find the latest timer events for the current quarter
      final quarterEvents =
          game.events.where((e) => e.quarter == currentQuarter).toList();

      if (quarterEvents.isNotEmpty) {
        // Find the last timer event (clock_start, clock_pause, etc.)
        final timerEvents =
            quarterEvents.where((e) => e.type.startsWith('clock_')).toList();

        if (timerEvents.isNotEmpty) {
          // Use the time from the latest event as the current elapsed time
          elapsedTime = timerEvents.last.time;
        }
      }
    }

    // Format the time similar to how it's done in the timer display
    final totalMinutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;
    final timeStr =
        '${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return 'Q$currentQuarter $timeStr';
  }
}
