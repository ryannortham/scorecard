// header widget displaying team name and total score

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/adaptive_title.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

/// header widget displaying team name and total score
class ScorePanelHeader extends StatelessWidget {
  const ScorePanelHeader({
    required this.teamName,
    required this.isHomeTeam,
    super.key,
  });
  final String teamName;
  final bool isHomeTeam;

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsViewModel>(
      builder: (context, teamsProvider, child) {
        // Look up the team object to get the logo
        final team = teamsProvider.findTeamByName(teamName);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              // Team logo
              TeamLogo(logoUrl: team?.logoUrl),
              const SizedBox(width: 8),
              // Team name
              Expanded(
                child: AdaptiveTitle(
                  title: teamName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.primary,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 16),
              Consumer<GameViewModel>(
                builder: (context, gameStateService, _) {
                  final goals = gameStateService.getScore(
                    isHomeTeam: isHomeTeam,
                    isGoal: true,
                  );
                  final behinds = gameStateService.getScore(
                    isHomeTeam: isHomeTeam,
                    isGoal: false,
                  );
                  final points = goals * 6 + behinds;

                  return Text(
                    points.toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
