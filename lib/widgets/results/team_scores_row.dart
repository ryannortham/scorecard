// team scores display row with watermarks

import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/results/team_logo_watermark.dart';
import 'package:scorecard/widgets/results/team_name.dart';
import 'package:scorecard/widgets/results/team_scores.dart';

/// team scores row with watermark backgrounds
class TeamScoresRow extends StatelessWidget {
  const TeamScoresRow({required this.game, super.key});
  final GameRecord game;

  @override
  Widget build(BuildContext context) {
    final homeWins = game.homePoints > game.awayPoints;
    final awayWins = game.awayPoints > game.homePoints;

    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: TeamLogoWatermark(teamName: game.homeTeam)),
            const SizedBox(width: 18),
            Expanded(child: TeamLogoWatermark(teamName: game.awayTeam)),
          ],
        ),
        Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: TeamName(
                      teamName: game.homeTeam,
                      isWinner: homeWins,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: TeamName(
                      teamName: game.awayTeam,
                      isWinner: awayWins,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TeamScores(
                      goals: game.homeGoals,
                      behinds: game.homeBehinds,
                      points: game.homePoints,
                      isWinner: homeWins,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: TeamScores(
                      goals: game.awayGoals,
                      behinds: game.awayBehinds,
                      points: game.awayPoints,
                      isWinner: awayWins,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Center(
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: Container(
                width: 2,
                color: ColorService.withAlpha(context.colors.outline, 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
