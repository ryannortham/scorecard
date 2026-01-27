// quarter breakdown section showing score tables for each team

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/services/score_table_builder_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/results/game_card.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

/// quarter breakdown section showing score tables for each team
class QuarterBreakdownSection extends StatelessWidget {
  const QuarterBreakdownSection({
    required this.game,
    super.key,
    this.liveEvents,
  });
  final GameRecord game;
  final List<GameEvent>? liveEvents;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      icon: Icons.scoreboard_outlined,
      title: 'Quarter Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamBreakdown(context, game.homeTeam, true),
          const SizedBox(height: 8),
          _buildTeamBreakdown(context, game.awayTeam, false),
        ],
      ),
    );
  }

  Widget _buildTeamBreakdown(
    BuildContext context,
    String teamName,
    bool isHome,
  ) {
    final homeWins = game.homePoints > game.awayPoints;
    final awayWins = game.awayPoints > game.homePoints;
    final isWinner = isHome ? homeWins : awayWins;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Consumer<TeamsViewModel>(
                builder: (context, teamsProvider, child) {
                  final team = teamsProvider.findTeamByName(teamName);
                  final logoUrl =
                      team?.logoUrl32 ?? team?.logoUrl48 ?? team?.logoUrl;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: TeamLogo(logoUrl: logoUrl),
                  );
                },
              ),
              Expanded(
                child: Text(
                  teamName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWinner ? context.colors.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        ScoreTableBuilderService.buildScoreTable(
          context: context,
          game: game,
          displayTeam: teamName,
          isHomeTeam: isHome,
          isLiveData: liveEvents != null,
          liveEvents: liveEvents,
        ),
      ],
    );
  }
}
