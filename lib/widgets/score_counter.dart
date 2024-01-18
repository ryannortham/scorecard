import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';
import '../providers/score_panel_provider.dart';

class ScoreCounter extends StatefulWidget {
  final String label;
  final bool isGoal;
  final bool isHomeTeam;
  final ScorePanelProvider scorePanelProvider;

  const ScoreCounter({
    Key? key,
    required this.label,
    required this.isGoal,
    required this.isHomeTeam,
    required this.scorePanelProvider,
  }) : super(key: key);

  @override
  ScoreCounterState createState() => ScoreCounterState();
}

class ScoreCounterState extends State<ScoreCounter> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(width: 8),
        CustomizableCounter(
          backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
          borderWidth: 2,
          borderRadius: 100,
          textSize: 22,
          count: widget.scorePanelProvider
              .getCount(
                widget.isHomeTeam,
                widget.isGoal,
              )
              .toDouble(),
          step: 1,
          minCount: 0,
          maxCount: 100,
          incrementIcon: const Icon(
            Icons.add,
          ),
          onCountChange: (newCount) {
            // Update the ScoreCounterProvider
            widget.scorePanelProvider.setCount(
              widget.isHomeTeam,
              widget.isGoal,
              newCount.toInt(),
            );
          },
        ),
      ],
    );
  }
}
