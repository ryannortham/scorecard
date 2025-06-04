import 'package:flutter/material.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/results_panel.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:provider/provider.dart';
import 'settings.dart';

class Results extends StatefulWidget {
  const Results({super.key, required this.title});
  final String title;

  @override
  ResultsState createState() => ResultsState();
}

class ResultsState extends State<Results> {
  late GameSetupProvider gameSetupProvider;
  // Temporary: Use an empty list for events until you implement persistence/sharing
  final List<GameEvent> gameEvents = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Settings(title: 'Settings'),
              ),
            ),
          ),
        ],
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScoreTable(
              events: gameEvents,
              homeTeam: homeTeamName,
              awayTeam: awayTeamName,
              displayTeam: homeTeamName,
            ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScoreTable(
              events: gameEvents,
              homeTeam: homeTeamName,
              awayTeam: awayTeamName,
              displayTeam: awayTeamName,
            ),
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
