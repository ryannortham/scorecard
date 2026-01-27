// card widget for selecting home and away teams

import 'package:flutter/material.dart';
import 'package:scorecard/widgets/scoring_setup/team_selector.dart';

/// card widget for selecting home and away teams
class TeamsCard extends StatelessWidget {
  const TeamsCard({
    required this.homeTeam,
    required this.awayTeam,
    required this.onHomeTeamChanged,
    required this.onAwayTeamChanged,
    super.key,
  });

  final String? homeTeam;
  final String? awayTeam;
  final void Function(String?) onHomeTeamChanged;
  final void Function(String?) onAwayTeamChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            TeamSelector(
              homeTeam: homeTeam,
              awayTeam: awayTeam,
              onHomeTeamChanged: onHomeTeamChanged,
              onAwayTeamChanged: onAwayTeamChanged,
            ),
          ],
        ),
      ),
    );
  }
}
