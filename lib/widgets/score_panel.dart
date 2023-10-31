import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/score_panel_state.dart';
import 'score_counter.dart';

class ScorePanel extends StatefulWidget {
  final String teamName;
  final bool isHomeTeam;

  const ScorePanel({
    Key? key,
    required this.teamName,
    required this.isHomeTeam,
  }) : super(key: key);

  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScorePanelState>(
      builder: (context, scorePanelState, _) {
        return Scaffold(
          body: Column(
            children: [
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Text(
                  widget.teamName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.visible,
                ),
              ),
              Text(
                "0",
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ScoreCounter(
                    label: 'Goals',
                    isHomeTeam: widget.isHomeTeam,
                    isGoal: true,
                  ),
                  ScoreCounter(
                    label: 'Behinds',
                    isHomeTeam: widget.isHomeTeam,
                    isGoal: false,
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}
