import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/score_panel_adapter.dart';

/// Header widget displaying team name and total score
class TeamScoreHeader extends StatelessWidget {
  final String teamName;
  final bool isHomeTeam;

  const TeamScoreHeader({
    super.key,
    required this.teamName,
    required this.isHomeTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Consumer<ScorePanelAdapter>(
            builder: (context, scorePanelAdapter, _) {
              final goals = scorePanelAdapter.getCount(isHomeTeam, true);
              final behinds = scorePanelAdapter.getCount(isHomeTeam, false);
              final points = goals * 6 + behinds;

              return Text(
                points.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
