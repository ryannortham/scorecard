import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/quarter_timer_panel.dart';
import 'settings.dart';

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

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.exit_to_app_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Exit Game?'),
              content: const Text('Any unsaved progress will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    if (_hasGameStateChanged()) {
      // Simple confirmation when the user has changed the game state
      return await _showExitConfirmation();
    }
    return true; // Allow back navigation if no changes
  }

  // Removed _saveGame and _finishGame methods as they are no longer needed

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
          icon: Icon(
            Icons.sports_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          title: Text('End of Quarter $quarter'),
          content: Text(
            'Quarter $quarter has ended. What would you like to do?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('continue'),
              child: const Text('Continue Playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('next'),
              child: Text('Go to Quarter $nextQuarter'),
            ),
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
          icon: Icon(
            Icons.emoji_events_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          title: const Text('End of Game'),
          content: Text(
            'The 4th quarter has ended. The game is complete!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('continue'),
              child: const Text('Continue Playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('exit'),
              child: const Text('Exit Game'),
            ),
          ],
        );
      },
    );

    // Check mounted state before proceeding with actions
    if (!mounted) return;

    if (action == 'exit') {
      // Simply exit the game without saving
      if (context.mounted) {
        Navigator.of(context).pop();
      }
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header with title and menu
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () async {
                              final shouldPop = await _onWillPop();
                              if (shouldPop && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Title
                          Expanded(
                            child: Text(
                              widget.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          // Settings button
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'Menu',
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const Settings(title: 'Settings'),
                                ),
                              );
                              // Update game setup with current settings when returning
                              if (context.mounted) {
                                final settingsProvider =
                                    Provider.of<SettingsProvider>(context,
                                        listen: false);
                                final gameSetupProvider =
                                    Provider.of<GameSetupProvider>(context,
                                        listen: false);
                                gameSetupProvider.setQuarterMinutes(
                                    settingsProvider.defaultQuarterMinutes);
                                gameSetupProvider.setIsCountdownTimer(
                                    settingsProvider.defaultIsCountdownTimer);
                              }
                            },
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Home Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return Card(
                          elevation: 1,
                          child: ScoreTable(
                            events: List<GameEvent>.from(
                                gameEvents), // Create a defensive copy
                            homeTeam: homeTeamName,
                            awayTeam: awayTeamName,
                            displayTeam: homeTeamName,
                            isHomeTeam: true,
                            enabled: timerRunning,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Away Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return Card(
                          elevation: 1,
                          child: ScoreTable(
                            events: List<GameEvent>.from(
                                gameEvents), // Create a defensive copy
                            homeTeam: homeTeamName,
                            awayTeam: awayTeamName,
                            displayTeam: awayTeamName,
                            isHomeTeam: false,
                            enabled: timerRunning,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Timer Panel Card
                    Card(
                      elevation: 1,
                      child: QuarterTimerPanel(
                          key: _quarterTimerKey,
                          isTimerRunning: isTimerRunning),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
