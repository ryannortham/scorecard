import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/services/game_history_service.dart';
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

  Future<void> _saveGame() async {
    try {
      final gameRecord = GameHistoryService.createGameRecord(
        date: gameSetupProvider.gameDate,
        homeTeam: gameSetupProvider.homeTeam,
        awayTeam: gameSetupProvider.awayTeam,
        quarterMinutes: gameSetupProvider.quarterMinutes,
        isCountdownTimer: gameSetupProvider.isCountdownTimer,
        events: gameEvents,
        homeGoals: scorePanelProvider.homeGoals,
        homeBehinds: scorePanelProvider.homeBehinds,
        awayGoals: scorePanelProvider.awayGoals,
        awayBehinds: scorePanelProvider.awayBehinds,
      );

      await GameHistoryService.saveGame(gameRecord);

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishGame() async {
    await _saveGame();
    if (mounted && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<String?> _showGameEndDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Complete'),
          content: const Text(
            'What would you like to do with this game?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('continue'),
              child: const Text('Continue Playing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('discard'),
              child: const Text('Discard Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save & Finish'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showExitConfirmation() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Game?'),
          content: const Text(
            'You have unsaved changes. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('discard'),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save & Exit'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasGameStateChanged()) {
      final result = await _showExitConfirmation();
      if (result == 'save') {
        await _saveGame();
        return true;
      } else if (result == 'discard') {
        return true;
      }
      return false; // Cancel
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
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;

            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                // Save Game button
                IconButton(
                  onPressed: _hasGameStateChanged() ? _saveGame : null,
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Game',
                ),
                // Finish Game button
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'finish') {
                      if (_hasGameStateChanged()) {
                        final result = await _showGameEndDialog();
                        if (result == 'save') {
                          await _finishGame();
                        } else if (result == 'discard') {
                          if (context.mounted) Navigator.of(context).pop();
                        }
                        // 'continue' does nothing - keeps playing
                      } else {
                        // No changes - just exit
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'finish',
                      child: Row(
                        children: [
                          Icon(Icons.flag),
                          SizedBox(width: 8),
                          Text('Finish Game'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
