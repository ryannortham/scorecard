import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/widgets/game_details/game_info_card.dart';

/// Widget that displays the quarter breakdown section of a game
class QuarterBreakdownSection extends StatelessWidget {
  final GameRecord game;
  final bool isLiveData;
  final List<GameEvent>? liveEvents;
  final Widget Function({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
  }) scoreTableBuilder;

  const QuarterBreakdownSection({
    super.key,
    required this.game,
    required this.isLiveData,
    required this.scoreTableBuilder,
    this.liveEvents,
  });

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;

    return GameInfoCard(
      icon: Icons.timeline,
      title: 'Quarter Breakdown',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Home Team Label
          _buildTeamLabel(context, game.homeTeam, homeWins),

          // Home Team Score Table
          scoreTableBuilder(
            context: context,
            game: game,
            displayTeam: game.homeTeam,
            isHomeTeam: true,
          ),

          const SizedBox(height: 16),

          // Away Team Label
          _buildTeamLabel(context, game.awayTeam, awayWins),

          // Away Team Score Table
          scoreTableBuilder(
            context: context,
            game: game,
            displayTeam: game.awayTeam,
            isHomeTeam: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLabel(BuildContext context, String teamName, bool isWinner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Text(
        teamName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWinner ? Theme.of(context).colorScheme.primary : null,
            ),
      ),
    );
  }
}
