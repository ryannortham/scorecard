import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';
import 'package:provider/provider.dart';
import '../providers/score_counter_provider.dart';

class ScoreCounter extends StatefulWidget {
  final String label;
  final bool isGoal;
  final bool isHomeTeam;

  ScoreCounter({
    required this.label,
    required this.isGoal,
    required this.isHomeTeam,
  });

  @override
  _ScoreCounterState createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter> {
  @override
  Widget build(BuildContext context) {
    final scoreCounterProvider = Provider.of<ScoreCounterProvider>(context);
    int _count = scoreCounterProvider.count;

    return Scaffold(
      body: Row(
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
            count: _count.toDouble(),
            step: 1,
            minCount: 0,
            maxCount: 100,
            incrementIcon: const Icon(
              Icons.add,
            ),
            decrementIcon: const Icon(
              Icons.remove,
            ),
            showButtonText: false,
            onCountChange: (count) {
              setState(() {
                _count = count.toInt();
                scoreCounterProvider.count = count.toInt();
              });
            },
          ),
        ],
      ),
    );
  }
}
