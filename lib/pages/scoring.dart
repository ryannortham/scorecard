import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/score_panel.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/quarter_timer_panel.dart';

class Scoring extends StatefulWidget {
  const Scoring({super.key, required this.title});
  final String title;

  @override
  ScoringState createState() => ScoringState();
}

class ScoringState extends State<Scoring> {
  late ScorePanelProvider scorePanelProvider;
  late GameSetupProvider gameSetupProvider;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  List<bool> isSelected = [true, false, false, false];
  final List<GameEvent> gameEvents = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);
  }

  @override
  void dispose() {
    isTimerRunning.dispose();
    super.dispose();
  }

  bool _hasGameStateChanged() {
    // Check if any scores have been entered
    if (scorePanelProvider.homeGoals > 0 ||
        scorePanelProvider.homeBehinds > 0 ||
        scorePanelProvider.awayGoals > 0 ||
        scorePanelProvider.awayBehinds > 0) {
      return true;
    }

    // Check if any game events have been recorded
    if (gameEvents.isNotEmpty) {
      return true;
    }

    // Check if timer has actually been used (not just preset)
    // For countdown timer: initial value is quarterMSec, so any change means it was used
    // For count-up timer: initial value is 0, so any positive value means it was used
    final initialTimerValue =
        gameSetupProvider.isCountdownTimer ? gameSetupProvider.quarterMSec : 0;
    if (scorePanelProvider.timerRawTime != initialTimerValue) {
      return true;
    }

    // Check if quarter has been changed from initial
    if (scorePanelProvider.selectedQuarter != 1) {
      return true;
    }

    return false;
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Discard Game?'),
              content: const Text(
                'You have unsaved changes. Are you sure you want to leave and discard this game?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    if (_hasGameStateChanged()) {
      return await _showExitConfirmation();
    }
    return true; // Allow back navigation if no changes
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupProvider>(
      builder: (context, scorePanelState, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            if (didPop) return;

            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuarterTimerPanel(isTimerRunning: isTimerRunning),
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, running, _) => ScorePanel(
                      teamName: homeTeamName,
                      isHomeTeam: true,
                      enabled: running,
                    ),
                  ),
                  ScoreTable(
                    events: gameEvents,
                    homeTeam: homeTeamName,
                    awayTeam: awayTeamName,
                    displayTeam: homeTeamName,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, running, _) => ScorePanel(
                      teamName: awayTeamName,
                      isHomeTeam: false,
                      enabled: running,
                    ),
                  ),
                  ScoreTable(
                    events: gameEvents,
                    homeTeam: homeTeamName,
                    awayTeam: awayTeamName,
                    displayTeam: awayTeamName,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
