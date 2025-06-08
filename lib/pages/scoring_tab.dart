import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/services/game_history_service.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/quarter_timer_panel.dart';
import 'dart:async';

class ScoringTab extends StatefulWidget {
  const ScoringTab({super.key});

  @override
  State<ScoringTab> createState() => ScoringTabState();
}

class ScoringTabState extends State<ScoringTab> {
  late ScorePanelProvider scorePanelProvider;
  late GameSetupProvider gameSetupProvider;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  List<bool> isSelected = [true, false, false, false];
  final List<GameEvent> gameEvents = [];
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  String? _currentGameId; // Track the current game's ID for updates
  Timer? _saveTimer; // Timer for throttling save operations

  // Add tracking for clock state
  bool _isClockRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);

    // Only add listener once, don't auto-save until actual game activity
    if (_currentGameId == null) {
      // Create the initial game record immediately to establish an ID
      _createInitialGameRecord();
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listener to the timer running state to track clock events
    isTimerRunning.addListener(() {
      _onTimerRunningChanged(isTimerRunning.value);
    });
  }

  void _createInitialGameRecord() async {
    // Only create a new game record if we don't already have one
    if (_currentGameId != null) return;

    try {
      final gameRecord = GameHistoryService.createGameRecord(
        date: DateTime.now(),
        homeTeam: gameSetupProvider.homeTeam,
        awayTeam: gameSetupProvider.awayTeam,
        quarterMinutes: gameSetupProvider.quarterMinutes,
        isCountdownTimer: gameSetupProvider.isCountdownTimer,
        events: List<GameEvent>.from(gameEvents),
        homeGoals: scorePanelProvider.homeGoals,
        homeBehinds: scorePanelProvider.homeBehinds,
        awayGoals: scorePanelProvider.awayGoals,
        awayBehinds: scorePanelProvider.awayBehinds,
      );

      await GameHistoryService.saveGame(gameRecord);
      _currentGameId = gameRecord.id;
      debugPrint(
          'Auto-saved initial game record: ${gameRecord.homeTeam} vs ${gameRecord.awayTeam}');

      // Now that we have a game ID, add the listener for future updates
      scorePanelProvider.addListener(_scheduleGameUpdate);
    } catch (e) {
      // Handle error silently - don't disrupt the user experience
      debugPrint('Error creating initial game record: $e');
    }
  }

  void _scheduleGameUpdate() {
    // If we don't have a game ID yet, this was called too early
    if (_currentGameId == null) {
      debugPrint('Attempted to update game before ID was created');
      return;
    }

    // Cancel any existing timer
    _saveTimer?.cancel();

    // Schedule a new save operation with a 2-second delay to throttle saves
    // The longer delay helps reduce unnecessary writes
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _updateGameRecord();
    });
  }

  void _updateGameRecord() async {
    if (_currentGameId == null) return;

    try {
      final gameRecord = GameHistoryService.createGameRecord(
        date: DateTime.now(),
        homeTeam: gameSetupProvider.homeTeam,
        awayTeam: gameSetupProvider.awayTeam,
        quarterMinutes: gameSetupProvider.quarterMinutes,
        isCountdownTimer: gameSetupProvider.isCountdownTimer,
        events: List<GameEvent>.from(gameEvents),
        homeGoals: scorePanelProvider.homeGoals,
        homeBehinds: scorePanelProvider.homeBehinds,
        awayGoals: scorePanelProvider.awayGoals,
        awayBehinds: scorePanelProvider.awayBehinds,
      );

      // Delete the old record and save the updated one
      await GameHistoryService.deleteGame(_currentGameId!);
      await GameHistoryService.saveGame(gameRecord);
      _currentGameId = gameRecord.id;
      debugPrint(
          'Auto-updated game record: ${gameRecord.homeTeam} ${gameRecord.homeGoals}.${gameRecord.homeBehinds} - ${gameRecord.awayTeam} ${gameRecord.awayGoals}.${gameRecord.awayBehinds}');
    } catch (e) {
      // Handle error silently - don't disrupt the user experience
      debugPrint('Error updating game record: $e');
    }
  }

  /// Records a clock event (start, pause, end) for the current quarter
  void _recordClockEvent(String eventType) {
    final currentQuarter = scorePanelProvider.selectedQuarter;
    final currentTime = Duration(milliseconds: scorePanelProvider.timerRawTime);

    // Only add the event if it doesn't duplicate the most recent event of the same type
    bool shouldAdd = true;
    if (gameEvents.isNotEmpty) {
      final lastEvent = gameEvents.last;
      // Don't add duplicate sequential events of the same type and quarter
      if (lastEvent.type == eventType && lastEvent.quarter == currentQuarter) {
        shouldAdd = false;
      }
    }

    if (shouldAdd) {
      setState(() {
        gameEvents.add(
          GameEvent(
            quarter: currentQuarter,
            time: currentTime,
            team: "", // Empty string for clock events
            type: eventType,
          ),
        );
      });

      // Update game record with the new clock event
      _scheduleGameUpdate();
    }
  }

  /// Track timer state changes
  void _onTimerRunningChanged(bool isRunning) {
    if (isRunning && !_isClockRunning) {
      // Timer started
      _recordClockEvent('clock_start');
      _isClockRunning = true;
    } else if (!isRunning && _isClockRunning) {
      // Timer paused
      _recordClockEvent('clock_pause');
      _isClockRunning = false;
    }
  }

  /// Record end of quarter event
  /// This method is called from the QuarterTimerPanel when quarters change
  /// and from the timer widget when a quarter's time expires
  void recordQuarterEnd(int quarter) {
    // Ensure we're using the current timer value
    final currentTime = Duration(milliseconds: scorePanelProvider.timerRawTime);

    setState(() {
      gameEvents.add(
        GameEvent(
          quarter: quarter,
          time: currentTime,
          team: "", // Empty string for clock events
          type: 'clock_end',
        ),
      );
    });

    // Update game record with the quarter end event
    _scheduleGameUpdate();

    // If this is the end of quarter 4, handle game completion
    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  // Public method that can be called by score counter when events change
  void updateGameAfterEventChange() {
    _scheduleGameUpdate();
  }

  /// Check if the game is completed (Q4 has ended)
  bool _isGameComplete() {
    // Check for any clock_end events in quarter 4
    return gameEvents.any((e) => e.quarter == 4 && e.type == 'clock_end');
  }

  /// Handle game completion by navigating back to previous screen
  void _handleGameCompletion() {
    // Only navigate back once when game is complete
    if (_isGameComplete()) {
      // Use post-frame callback to avoid during-build navigation issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Navigate back to previous screen (game history)
        Navigator.of(context).pop();
      });
    }
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
              content:
                  const Text('Are you sure you want to exit the current game?'),
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

  Future<bool> handleExit() async {
    final shouldExit = await _showExitConfirmation();

    // If the user confirms exit and the timer is still running, stop it and record the event
    if (shouldExit && _isClockRunning) {
      // Stop the timer
      isTimerRunning.value = false;

      // Make sure the timer is visually stopped
      _quarterTimerKey.currentState?.resetTimer();

      // Record the clock pause event manually since we're not going through the normal flow
      _recordClockEvent('clock_pause');
      _isClockRunning = false;
    }

    return shouldExit;
  }

  @override
  void dispose() {
    // Cancel any pending save timer
    _saveTimer?.cancel();

    // Force a final update before leaving the screen to ensure latest state is saved
    if (_currentGameId != null) {
      _updateGameRecord();
    }

    // Remove the listener to prevent memory leaks
    scorePanelProvider.removeListener(_scheduleGameUpdate);
    isTimerRunning.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupProvider>(
      builder: (context, scorePanelState, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Timer Panel Card - moved to top
              Card(
                elevation: 1,
                child: QuarterTimerPanel(
                    key: _quarterTimerKey, isTimerRunning: isTimerRunning),
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
