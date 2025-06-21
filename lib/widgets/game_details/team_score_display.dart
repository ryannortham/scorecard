import 'package:flutter/material.dart';
import 'package:scorecard/widgets/adaptive_title.dart';

/// Widget for displaying a team's score with highlighting for the winner
class TeamScoreDisplay extends StatelessWidget {
  final String teamName;
  final int goals;
  final int behinds;
  final int points;
  final bool isWinner;
  final bool centerAlign;

  const TeamScoreDisplay({
    super.key,
    required this.teamName,
    required this.goals,
    required this.behinds,
    required this.points,
    required this.isWinner,
    this.centerAlign = true,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = centerAlign ? TextAlign.center : TextAlign.start;
    final crossAxisAlignment =
        centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        AdaptiveTitle(
          title: teamName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isWinner ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isWinner ? FontWeight.w600 : null,
              ),
          textAlign: centerAlign ? TextAlign.center : TextAlign.start,
          maxLines: 1,
          minScaleFactor: 0.6, // Allow more aggressive scaling for screenshots
        ),
        const SizedBox(height: 8),
        Text(
          '$points',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: isWinner ? Theme.of(context).colorScheme.primary : null,
                fontWeight: FontWeight.bold,
              ),
          textAlign: textAlign,
        ),
        Text(
          '$goals.$behinds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isWinner ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isWinner ? FontWeight.w600 : null,
              ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}
