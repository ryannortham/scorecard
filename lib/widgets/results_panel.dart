import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';

class ResultsPanel extends StatefulWidget {
  const ResultsPanel({super.key});

  @override
  ResultsPanelState createState() => ResultsPanelState();
}

class ResultsPanelState extends State<ResultsPanel> {
  late GameSetupProvider gameSetupProvider;
  late ScorePanelProvider scorePanelProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);
  }

  String getGameProgress() {
    String gameProgress = '';
    String qtrTime = StopWatchTimer.getDisplayTime(
        scorePanelProvider.timerRawTime,
        hours: false,
        milliSecond: false);

    if (scorePanelProvider.selectedQuarter == 1) {
      gameProgress = '1st Quarter';
    } else if (scorePanelProvider.selectedQuarter == 2) {
      gameProgress = '2nd Quarter';
    } else if (scorePanelProvider.selectedQuarter == 3) {
      gameProgress = '3rd Quarter';
    } else if (scorePanelProvider.selectedQuarter == 4) {
      gameProgress = '4th Quarter';
    }

    return '$gameProgress: $qtrTime';
  }

  @override
  Widget build(BuildContext context) {
    String gameDay =
        DateFormat('EEEE MMMM d').format(gameSetupProvider.gameDate);

    return Column(children: [
      Text(
        gameDay,
        style: Theme.of(context).textTheme.bodyLarge,
        overflow: TextOverflow.visible,
      ),
      Text(
        getGameProgress(),
        style: Theme.of(context).textTheme.bodyLarge,
        overflow: TextOverflow.visible,
      ),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double totalWidth = constraints.maxWidth;
          return Wrap(
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: totalWidth * 0.4,
                child: Center(
                  child: Text(
                    gameSetupProvider.homeTeam,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: totalWidth * 0.1,
                child: Center(
                  child: Text(
                    scorePanelProvider.homePoints.toString(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: totalWidth * 0.1,
                child: Center(
                  child: Text(
                    scorePanelProvider.awayPoints.toString(),
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: totalWidth * 0.4,
                child: Center(
                  child: Text(
                    gameSetupProvider.awayTeam,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      )
    ]);
  }
}
