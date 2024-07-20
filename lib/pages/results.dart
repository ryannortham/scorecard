import 'package:flutter/material.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/results_panel.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:provider/provider.dart';

class Results extends StatefulWidget {
  const Results({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  ResultsState createState() => ResultsState();
}

class ResultsState extends State<Results> {
  late GameSetupProvider gameSetupProvider;
  int _selectedIndex = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Column(
        children: [
          const ResultsPanel(),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: FittedBox(
              child: Text(
                homeTeamName,
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: ScoreTable(),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: FittedBox(
              child: Text(
                awayTeamName,
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: ScoreTable(),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
