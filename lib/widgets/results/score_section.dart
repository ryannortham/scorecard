// score section widget displaying team scores, result badge, and game date

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/game_record_extensions.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/results/game_card.dart';
import 'package:scorecard/widgets/results/game_result_badge.dart';
import 'package:scorecard/widgets/results/team_scores_row.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

/// score section displaying team scores, result badge, and date
class ScoreSection extends StatelessWidget {
  const ScoreSection({required this.game, required this.isLiveData, super.key});
  final GameRecord game;
  final bool isLiveData;

  @override
  Widget build(BuildContext context) {
    final isComplete = game.isComplete;
    final title = _getScoreTitle(context, isComplete);

    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final shouldShowTrophy = game.shouldShowTrophy(userPrefs);
    final icon =
        shouldShowTrophy ? Icons.emoji_events_outlined : Icons.outlined_flag;

    return GameCard(
      icon: icon,
      title: title,
      child: Column(
        children: [
          TeamScoresRow(game: game),
          const SizedBox(height: 8),
          GameResultBadge(game: game, isComplete: isComplete),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(game.date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getScoreTitle(BuildContext context, bool isComplete) {
    if (isLiveData) {
      final gameState = context.read<GameStateService>();
      final quarter = gameState.selectedQuarter;
      final timeMs = gameState.getElapsedTimeInQuarter();
      final timeStr = StopWatchTimer.getDisplayTime(timeMs, hours: false);
      final formattedTime = timeStr.substring(0, timeStr.length - 1);
      return 'In Progress: Q$quarter $formattedTime';
    }

    if (isComplete) return 'Final Score';

    // For static incomplete games, build title from events
    return game.inProgressTitle;
  }
}
