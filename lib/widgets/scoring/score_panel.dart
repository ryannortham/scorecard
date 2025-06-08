import 'package:flutter/material.dart';
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

  Widget _buildScoreCounter(String label, bool isGoal) {
    return ScoreCounter(
      label: label,
      isHomeTeam: isHomeTeam,
      isGoal: isGoal,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildScoreCounter('Goals', true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildScoreCounter('Behinds', false),
          ),
        ],
      ),
    );
  }
}
