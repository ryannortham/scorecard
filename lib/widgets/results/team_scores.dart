// team scores display widget

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';

/// displays points and goals.behinds
class TeamScores extends StatelessWidget {
  const TeamScores({
    required this.goals,
    required this.behinds,
    required this.points,
    required this.isWinner,
    super.key,
  });
  final int goals;
  final int behinds;
  final int points;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? context.colors.primary : null;
    final fontWeight = isWinner ? FontWeight.w600 : null;

    return Column(
      children: [
        Text(
          '$points',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '$goals.$behinds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: fontWeight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
