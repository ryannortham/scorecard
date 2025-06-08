import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/services/scoring_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/scoring/scoring.dart';
import 'package:goalkeeper/widgets/timer/timer.dart';

class Scoring extends StatefulWidget {
  const Scoring({super.key, required this.title});
  final String title;

  @override
  ScoringState createState() => ScoringState();
}

class ScoringState extends State<Scoring> {
  late ScorePanelAdapter scorePanelProvider;
  late GameSetupAdapter gameSetupProvider;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  List<bool> isSelected = [true, false, false, false];
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  // Use the decoupled scoring state manager
  final ScoringStateManager _scoringStateManager = ScoringStateManager.instance;
  bool _isClockRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Sync local clock state with provider state
    _isClockRunning = scorePanelProvider.isTimerRunning;

    // Initialize the game if not already started
    if (_scoringStateManager.currentGameId == null) {
      _scoringStateManager.startNewGame();
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

  /// Track timer state changes
  void _onTimerRunningChanged(bool isRunning) {
    // Use post-frame callback to avoid setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isRunning && !_isClockRunning) {
        // Timer started
        _isClockRunning = true;
        scorePanelProvider.setTimerRunning(true);
      } else if (!isRunning && _isClockRunning) {
        // Timer paused
        _isClockRunning = false;
        scorePanelProvider.setTimerRunning(false);
      }
    });
  }

  /// Record end of quarter event
  /// This method is called from the QuarterTimerPanel when quarters change
  /// and from the timer widget when a quarter's time expires
  void recordQuarterEnd(int quarter) {
    _scoringStateManager.recordQuarterEnd(quarter);

    // Stop the timer and update provider state
    _isClockRunning = false;
    scorePanelProvider.setTimerRunning(false);

    // If this is the end of quarter 4, handle game completion
    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  // Public method that can be called by score counter when events change
  void updateGameAfterEventChange() {
    // The scoring state manager handles automatic saving
    _scoringStateManager.updateGameAfterEventChange();
  }

  /// Check if the game is completed (Q4 has ended)
  bool _isGameComplete() {
    return _scoringStateManager.isGameComplete();
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

  // Access game events from the scoring state manager
  List<GameEvent> get gameEvents => _scoringStateManager.gameEvents;

  @override
  void dispose() {
    isTimerRunning.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupAdapter>(
      builder: (context, scorePanelState, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timer Panel Card
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
                      return Consumer<ScorePanelAdapter>(
                        builder: (context, scorePanelAdapter, child) {
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
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Away Team Score Table
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, timerRunning, child) {
                      return Consumer<ScorePanelAdapter>(
                        builder: (context, scorePanelAdapter, child) {
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
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
