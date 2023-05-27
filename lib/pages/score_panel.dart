import 'package:flutter/material.dart';
import '../widgets/score_counter.dart';

class ScorePanel extends StatefulWidget {
  final String teamName;

  const ScorePanel({Key? key, required this.teamName}) : super(key: key);

  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel> {
  int _goals = 0;
  int _behinds = 0;
  int _points = 0;

  void onCountChange(int count) {
    setState(() {
      _points = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntrinsicHeight(
        child: Column(
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
                overflow: null,
              ),
            ),
            Text(
              _points.toString(),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScoreCounter(
                    label: 'Goals', onCountChange: onCountChange, isGoal: true),
                ScoreCounter(
                    label: 'Behinds',
                    onCountChange: onCountChange,
                    isGoal: false),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}
