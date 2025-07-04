import 'package:flutter/material.dart';

import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/screens/scoring.dart';
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
  final GameStateService _gameStateService = GameStateService.instance;

  @override
  void initState() {
    super.initState();

    _gameStateService.addListener(_onTimerStateChanged);

    if (widget.isRunning != null) {
      widget.isRunning!.value = _gameStateService.isTimerRunning;
    }
  }

  void _onTimerStateChanged() {
    if (mounted && widget.isRunning != null) {
      widget.isRunning!.value = _gameStateService.isTimerRunning;
    }
  }

  @override
  void dispose() {
    _gameStateService.removeListener(_onTimerStateChanged);
    super.dispose();
  }

  void toggleTimer() {
    _gameStateService.setTimerRunning(!_gameStateService.isTimerRunning);

    if (widget.isRunning != null) {
      widget.isRunning!.value = _gameStateService.isTimerRunning;
    }
  }

  void resetTimer() {
    _gameStateService.resetTimer();

    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    }
  }

  Future<void> _handleNextQuarter() async {
    final currentQuarter = _gameStateService.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;
    final remainingTime = _gameStateService.getRemainingTimeInQuarter();
    final shouldSkipConfirmation = remainingTime <= 30000; // 30 seconds

    bool confirmed = shouldSkipConfirmation;

    if (!shouldSkipConfirmation) {
      confirmed = await EndQuarterBottomSheet.show(
        context: context,
        currentQuarter: currentQuarter,
        isLastQuarter: isLastQuarter,
        onConfirm: () {},
      );
    }

    if (!confirmed || !mounted) return;

    final scoringState = context.findAncestorStateOfType<ScoringState>();
    if (scoringState == null) return;

    scoringState.recordQuarterEnd(currentQuarter);

    if (currentQuarter == 4) return; // Game complete

    // Transition to next quarter
    if (_gameStateService.isTimerRunning) {
      _gameStateService.setTimerRunning(false);
    }

    _gameStateService.setSelectedQuarter(currentQuarter + 1);
    resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          QuarterProgress(),
          const SizedBox(height: 8),
          const TimerClock(),
          TimerControls(
            onToggleTimer: toggleTimer,
            onResetTimer: resetTimer,
            onNextQuarter: _handleNextQuarter,
            isRunningNotifier: widget.isRunning,
          ),
        ],
      ),
    );
  }
}
