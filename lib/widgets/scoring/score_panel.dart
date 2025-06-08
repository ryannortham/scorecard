import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'score_counter.dart';

class ScorePanel extends StatelessWidget {
  final String teamName;
  final bool isHomeTeam;
  final bool enabled;

  const ScorePanel({
    super.key,
    required this.teamName,
    required this.isHomeTeam,
    this.enabled = true,
  });

  Widget _buildScoreCounter(
      String label, bool isGoal, ScorePanelProvider scorePanelProvider) {
    return ScoreCounter(
      label: label,
      isHomeTeam: isHomeTeam,
      isGoal: isGoal,
      scorePanelProvider: scorePanelProvider,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorePanelProvider>(
      builder: (context, scorePanelProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildScoreCounter('Goals', true, scorePanelProvider),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreCounter('Behinds', false, scorePanelProvider),
              ),
            ],
          ),
        );
      },
    );
  }
}
