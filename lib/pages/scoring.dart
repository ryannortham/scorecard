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
                                  .titleLarge
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
