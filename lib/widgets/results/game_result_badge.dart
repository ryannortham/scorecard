// badge widget displaying game result status (win, draw, or lead)

import 'package:flutter/material.dart';

import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/theme/colors.dart';

/// badge displaying game result (win/draw/lead)
class GameResultBadge extends StatelessWidget {
  const GameResultBadge({
    required this.game,
    required this.isComplete,
    super.key,
  });
  final GameRecord game;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final isDraw = game.homePoints == game.awayPoints;
    final homeWins = game.homePoints > game.awayPoints;
    final margin = (game.homePoints - game.awayPoints).abs();

    if (isDraw && game.homePoints == 0) return const SizedBox.shrink();

    String resultText;
    if (isDraw) {
      if (!isComplete) return const SizedBox.shrink();
      resultText = 'Draw';
    } else if (isComplete) {
      resultText =
          homeWins
              ? '${game.homeTeam} won by $margin'
              : '${game.awayTeam} won by $margin';
    } else {
      resultText =
          homeWins
              ? '${game.homeTeam} leads by $margin'
              : '${game.awayTeam} leads by $margin';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        resultText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.colors.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }
}
