import 'package:flutter/material.dart';
import 'package:scorecard/widgets/adaptive_title.dart';

/// Widget for displaying the game result (win/loss/draw) as a badge
class GameResultBadge extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homePoints;
  final int awayPoints;
  final bool isGameComplete;
  final bool isHistoryMode;

  const GameResultBadge({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homePoints,
    required this.awayPoints,
    required this.isGameComplete,
    this.isHistoryMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDraw = homePoints == awayPoints;
    final homeWins = homePoints > awayPoints;
    final margin = (homePoints - awayPoints).abs();

    // Don't show anything if it's a draw with no score
    if (isDraw && homePoints == 0) {
      return const SizedBox.shrink();
    }

    String resultText;
    if (isDraw) {
      if (isHistoryMode) {
        // Only show "Draw" for completed games
        resultText = 'Draw';
      } else {
        // For live games with tied scores, don't show anything
        return const SizedBox.shrink();
      }
    } else if (isHistoryMode) {
      // For history mode, always show "won by"
      if (homeWins) {
        resultText = '$homeTeam won by $margin';
      } else {
        resultText = '$awayTeam won by $margin';
      }
    } else {
      // For live mode, always show "leads by"
      if (homeWins) {
        resultText = '$homeTeam leads by $margin';
      } else {
        resultText = '$awayTeam leads by $margin';
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDraw
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AdaptiveTitle(
          title: resultText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDraw
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          minScaleFactor: 0.6, // Allow aggressive scaling for long team names
        ),
      ),
    );
  }
}
