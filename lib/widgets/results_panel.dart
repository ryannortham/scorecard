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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game date and progress info - more compact
          Text(
            '$gameDay • ${getGameProgress()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2, // Reduce line height
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Scoreboard - compact row layout
          Row(
            children: [
              // Home team
              Expanded(
                flex: 2,
                child: Text(
                  gameSetupProvider.homeTeam,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Home score
              Expanded(
                child: Text(
                  scorePanelProvider.homePoints.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        height: 1.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Versus indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'v',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),

              // Away score
              Expanded(
                child: Text(
                  scorePanelProvider.awayPoints.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        height: 1.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Away team
              Expanded(
                flex: 2,
                child: Text(
                  gameSetupProvider.awayTeam,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
