import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:goalkeeper/services/game_history_service.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/quarter_timer_panel.dart';
import 'dart:async';
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

  String? _currentGameId; // Track the current game's ID for updates
  Timer? _saveTimer; // Timer for throttling save operations

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);

    // Auto-save a new game record when first entering the scoring screen
    if (_currentGameId == null) {
      _createInitialGameRecord();
      // Add listeners for score changes to auto-save
      scorePanelProvider.addListener(_scheduleGameUpdate);
    }
  }

  void _createInitialGameRecord() async {
    try {
      final gameRecord = GameHistoryService.createGameRecord(
        date: DateTime.now(),
        homeTeam: gameSetupProvider.homeTeam,
        awayTeam: gameSetupProvider.awayTeam,
        quarterMinutes: gameSetupProvider.quarterMinutes,
        isCountdownTimer: gameSetupProvider.isCountdownTimer,
        events: [],
        homeGoals: 0,
        homeBehinds: 0,
        awayGoals: 0,
        awayBehinds: 0,
      );

      await GameHistoryService.saveGame(gameRecord);
      _currentGameId = gameRecord.id;
      debugPrint(
          'Auto-saved initial game record: ${gameRecord.homeTeam} vs ${gameRecord.awayTeam}');
    } catch (e) {
      // Handle error silently - don't disrupt the user experience
      debugPrint('Error creating initial game record: $e');
    }
  }

  void _scheduleGameUpdate() {
    // Cancel any existing timer
    _saveTimer?.cancel();

    // Schedule a new save operation with a 1-second delay to throttle saves
    _saveTimer = Timer(const Duration(seconds: 1), () {
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

  // Public method that can be called by score counter when events change
  void updateGameAfterEventChange() {
    _scheduleGameUpdate();
  }

  @override
  void dispose() {
    // Cancel any pending save timer
    _saveTimer?.cancel();
    // Remove the listener to prevent memory leaks
    scorePanelProvider.removeListener(_scheduleGameUpdate);
    isTimerRunning.dispose();
    super.dispose();
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

  Future<bool> _onWillPop() async {
    return await _showExitConfirmation();
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

                    // Timer Panel Card - moved to top
                    Card(
                      elevation: 1,
                      child: QuarterTimerPanel(
                          key: _quarterTimerKey,
                          isTimerRunning: isTimerRunning),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
