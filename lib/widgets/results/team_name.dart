// team name display widget

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';

/// displays team name with winner highlighting
class TeamName extends StatelessWidget {
  const TeamName({required this.teamName, required this.isWinner, super.key});
  final String teamName;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? context.colors.primary : null;
    final fontWeight = isWinner ? FontWeight.w600 : null;

    return Text(
      teamName,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: color, fontWeight: fontWeight),
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
    );
  }
}
