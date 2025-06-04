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
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  // Track previous timer state to detect quarter end
  int _previousTimerValue = 0;
  bool _hasShownQuarterEndDialog = false;
  int _lastCheckedQuarter = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);

    // Initialize previous timer value
    _previousTimerValue =
        gameSetupProvider.isCountdownTimer ? gameSetupProvider.quarterMSec : 0;

    // Initialize last checked quarter
    _lastCheckedQuarter = scorePanelProvider.selectedQuarter;

    // Listen for timer changes to detect quarter end
    // Remove any existing listener first to avoid duplicates
    scorePanelProvider.removeListener(_checkForQuarterEnd);
    scorePanelProvider.addListener(_checkForQuarterEnd);
  }

  @override
  void dispose() {
    isTimerRunning.dispose();
    scorePanelProvider.removeListener(_checkForQuarterEnd);
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

  Future<String?> _showSaveGameDialog(
      {String saveButtonText = 'Save & Exit'}) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Game?'),
          content: const Text('What would you like to do with this game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('discard'),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: Text(saveButtonText),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasGameStateChanged()) {
      final action = await _showSaveGameDialog(saveButtonText: 'Save & Exit');

      if (action == 'save') {
        await _saveGame();
        return true; // Allow exit after saving
      } else if (action == 'discard') {
        return true; // Allow exit without saving
      } else {
        return false; // Continue - don't exit
      }
    }
    return true; // Allow back navigation if no changes
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  void _checkForQuarterEnd() {
    // Exit early if widget is not mounted
    if (!mounted) return;

    final currentTimerValue = scorePanelProvider.timerRawTime;
    final quarterMSec = gameSetupProvider.quarterMSec;
    final currentQuarter = scorePanelProvider.selectedQuarter;
    final isCountdown = gameSetupProvider.isCountdownTimer;

    // Reset dialog flag if quarter has changed
    if (currentQuarter != _lastCheckedQuarter) {
      _hasShownQuarterEndDialog = false;
      _lastCheckedQuarter = currentQuarter;
      // Update previous timer value when quarter changes to prevent false quarter end detection
      _previousTimerValue = isCountdown ? quarterMSec : 0;
      return; // Exit early after quarter change to avoid false quarter end detection
    }

    // Reset dialog flag when timer is reset to initial values
    if (currentTimerValue != _previousTimerValue) {
      if ((isCountdown && currentTimerValue == quarterMSec) ||
          (!isCountdown && currentTimerValue == 0)) {
        _hasShownQuarterEndDialog = false;
      }
    }

    // Check if quarter has just ended (timer reached limit)
    bool quarterJustEnded = false;

    if (isCountdown) {
      // For countdown: quarter ends when timer reaches 0 or goes negative
      quarterJustEnded = _previousTimerValue > 0 && currentTimerValue <= 0;
    } else {
      // For count-up: quarter ends when timer reaches quarter length
      quarterJustEnded =
          _previousTimerValue < quarterMSec && currentTimerValue >= quarterMSec;
    }

    // Only show dialog once per quarter end and if timer is not running
    if (quarterJustEnded &&
        !_hasShownQuarterEndDialog &&
        !isTimerRunning.value) {
      _hasShownQuarterEndDialog = true;

      // Show appropriate dialog based on quarter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check mounted state before showing dialog
        if (!mounted) return;

        if (currentQuarter == 4) {
          _showEndOfGameDialog();
        } else {
          _showEndOfQuarterDialog(currentQuarter);
        }
      });
    }

    _previousTimerValue = currentTimerValue;
  }

  Future<void> _showEndOfQuarterDialog(int quarter) async {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    final nextQuarter = quarter + 1;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End of Quarter $quarter'),
          content:
              Text('Quarter $quarter has ended. What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('continue'),
              child: const Text('Continue Playing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('next'),
              child: Text('Go to Quarter $nextQuarter'),
            ),
            // Remove Save & Exit option for quarters 1-3
          ],
        );
      },
    );

    // Check mounted state before proceeding with actions
    if (!mounted) return;

    if (action == 'next') {
      // Move to next quarter
      scorePanelProvider.setSelectedQuarter(nextQuarter);
      // Reset timer for new quarter
      _quarterTimerKey.currentState?.resetTimer();
      // Reset the dialog flag for the new quarter
      _hasShownQuarterEndDialog = false;
      // Don't automatically start the timer - let user start it manually when ready
    } else if (action == 'continue') {
      // Reset the dialog flag so it can be shown again if quarter ends again
      _hasShownQuarterEndDialog = false;
      // Start the timer automatically when continuing
      _quarterTimerKey.currentState?.startTimer();
    }
    // No save option for quarters 1-3
  }

  Future<void> _showEndOfGameDialog() async {
    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End of Game'),
          content:
              const Text('The 4th quarter has ended. The game is complete!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('continue'),
              child: const Text('Continue Playing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('finish'),
              child: const Text('Finish Game'),
            ),
          ],
        );
      },
    );

    // Check mounted state before proceeding with actions
    if (!mounted) return;

    if (action == 'finish') {
      // Directly save and finish the game without additional prompts
      await _finishGame();
    } else if (action == 'continue') {
      // Reset the dialog flag so it can be shown again if game ends again in overtime
      _hasShownQuarterEndDialog = false;
      // Start the timer automatically when continuing into overtime
      _quarterTimerKey.currentState?.startTimer();
    }
    // 'continue' or null - do nothing, allow overtime play
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupProvider>(
      builder: (context, scorePanelState, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
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
                PopupMenuButton<String>(
                  onSelected: (String result) async {
                    if (result == 'finish') {
                      final action = await _showSaveGameDialog(
                          saveButtonText: 'Save & Finish');
                      if (action == 'save') {
                        await _finishGame();
                      } else if (action == 'discard') {
                        if (context.mounted) Navigator.of(context).pop();
                      }
                      // 'cancel' (Continue button) does nothing - stays on current screen
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'finish',
                      child: Text('Finish Game'),
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
                  QuarterTimerPanel(
                      key: _quarterTimerKey, isTimerRunning: isTimerRunning),
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, running, _) => ScorePanel(
                      teamName: homeTeamName,
                      isHomeTeam: true,
                      enabled: running,
                    ),
                  ),
                  ScoreTable(
                    events: List<GameEvent>.from(
                        gameEvents), // Create a defensive copy
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
                    events: List<GameEvent>.from(
                        gameEvents), // Create a defensive copy
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
