import 'package:flutter/material.dart';

/// Widget for displaying the game result (win/loss/draw) as a badge
class GameResultBadge extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homePoints;
  final int awayPoints;
  final bool isGameComplete;

  const GameResultBadge({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homePoints,
    required this.awayPoints,
    required this.isGameComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGameComplete) {
      return const SizedBox.shrink();
    }

    final isDraw = homePoints == awayPoints;
    final homeWins = homePoints > awayPoints;
    final margin = (homePoints - awayPoints).abs();

    String resultText;
    if (isDraw) {
      resultText = 'Draw';
    } else if (homeWins) {
      resultText = '$homeTeam Won By $margin';
    } else {
      resultText = '$awayTeam Won By $margin';
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
        child: Text(
          resultText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDraw
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
