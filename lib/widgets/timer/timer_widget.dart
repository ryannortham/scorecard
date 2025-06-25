import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/screens/scoring.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/widgets/bottom_sheets/end_quarter_bottom_sheet.dart';
import 'package:scorecard/widgets/timer/timer_controls.dart';
import 'package:scorecard/widgets/timer/timer_clock.dart';
import 'quarter_progress.dart';

class TimerWidget extends StatefulWidget {
  final ValueNotifier<bool>? isRunning;
  const TimerWidget({super.key, this.isRunning});

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late GameSetupAdapter gameSetupProvider;
  late ScorePanelAdapter scorePanelProvider;
  final GameStateService _gameStateService = GameStateService.instance;

  @override
  void initState() {
    super.initState();

    // Initialize providers from context
    gameSetupProvider = Provider.of<GameSetupAdapter>(context, listen: false);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context, listen: false);

    // Listen to timer state changes to sync with widget.isRunning
    _gameStateService.addListener(_onTimerStateChanged);

    // Set initial state
    if (widget.isRunning != null) {
      widget.isRunning!.value = _gameStateService.isTimerRunning;
    }
  }

  void _onTimerStateChanged() {
    if (mounted && widget.isRunning != null) {
      widget.isRunning!.value = scorePanelProvider.isTimerRunning;
    }
  }

  @override
  void dispose() {
    _gameStateService.removeListener(_onTimerStateChanged);
    super.dispose();
  }

  void toggleTimer() {
    scorePanelProvider.setTimerRunning(!scorePanelProvider.isTimerRunning);

    if (widget.isRunning != null) {
      widget.isRunning!.value = scorePanelProvider.isTimerRunning;
    }
  }

  void resetTimer() {
    // Reset timer through the centralized service
    _gameStateService.resetTimer();

    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    }
  }

  // Method to handle next quarter transition
  void _handleNextQuarter() async {
    final currentQuarter = scorePanelProvider.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;

    // Check if there are 30 seconds or less remaining in the quarter
    // Use actual elapsed time for business logic, not display time
    final thirtySecondsInMs = 30 * 1000; // 30 seconds in milliseconds
    final remainingTimeInQuarter =
        _gameStateService.getRemainingTimeInQuarter();
    // Skip confirmation if 30 seconds or less remaining, OR if in overtime (negative time)
    final shouldSkipConfirmation = remainingTimeInQuarter <= thirtySecondsInMs;

    bool confirmed = true; // Default to confirmed if skipping dialog

    // Show confirmation bottom sheet only if more than 30 seconds remaining
    if (!shouldSkipConfirmation) {
      confirmed = await EndQuarterBottomSheet.show(
        context: context,
        currentQuarter: currentQuarter,
        isLastQuarter: isLastQuarter,
        onConfirm: () {}, // The bottom sheet handles navigation internally
      );
    }

    // If user cancelled dialog, don't proceed
    if (!confirmed) return;

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    // Find parent ScoringState to record quarter end event
    final scoringState = context.findAncestorStateOfType<ScoringState>();
    if (scoringState != null) {
      // Record clock_end event for the current quarter
      scoringState.recordQuarterEnd(currentQuarter);

      // If it's the last quarter (Q4), end the game
      if (currentQuarter == 4) {
        // Game completion is handled in recordQuarterEnd
        return;
      }

      // Otherwise, transition to the next quarter
      final nextQuarter = currentQuarter + 1;

      // If timer is running, pause it before changing quarters
      if (scorePanelProvider.isTimerRunning) {
        scorePanelProvider.setTimerRunning(false);
      }

      // Switch to the next quarter
      scorePanelProvider.setSelectedQuarter(nextQuarter);

      // Reset the timer for the new quarter
      resetTimer();
    }
  }

  bool get isTimerActuallyRunning => scorePanelProvider.isTimerRunning;

  IconData getIcon() {
    return scorePanelProvider.isTimerRunning ? Icons.pause : Icons.play_arrow;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuarterProgress(scorePanelProvider: scorePanelProvider),

        SizedBox(height: 8),

        // Timer Display Component
        const TimerClock(),

        // Timer Controls Component
        TimerControls(
          onToggleTimer: toggleTimer,
          onResetTimer: resetTimer,
          onNextQuarter: _handleNextQuarter,
          isRunningNotifier: widget.isRunning,
        ),
      ],
    );
  }
}
