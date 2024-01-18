import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/score_panel_state.dart';
import 'score_counter.dart';

class ScorePanel extends StatelessWidget {
  final String teamName;
  final bool isHomeTeam;

  const ScorePanel({
    Key? key,
    required this.teamName,
    required this.isHomeTeam,
  }) : super(key: key);

  Widget _buildScoreCounter(
      String label, bool isGoal, ScorePanelState scorePanelState) {
    return ScoreCounter(
      label: label,
      isHomeTeam: isHomeTeam,
      isGoal: isGoal,
      scorePanelState: scorePanelState,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorePanelState>(
      builder: (context, scorePanelState, _) {
        return Column(
          children: [
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: FittedBox(
                child: Text(
                  teamName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            Text(
              isHomeTeam
                  ? scorePanelState.homePoints.toString()
                  : scorePanelState.awayPoints.toString(),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreCounter('Goals', true, scorePanelState),
                _buildScoreCounter('Behinds', false, scorePanelState),
              ],
            ),
          ],
        );
      },
    );
  }
}
