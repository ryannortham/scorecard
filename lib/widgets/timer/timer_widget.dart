import 'package:flutter/material.dart';

import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/screens/scoring/scoring_screen.dart';
import 'package:scorecard/widgets/timer/timer_controls.dart';
import 'package:scorecard/widgets/timer/timer_clock.dart';

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

    widget.isRunning?.value = _gameStateService.isTimerRunning;
  }

  void _onTimerStateChanged() {
    if (mounted) {
      widget.isRunning?.value = _gameStateService.isTimerRunning;
    }
  }

  @override
  void dispose() {
    _gameStateService.removeListener(_onTimerStateChanged);
    super.dispose();
  }

  void toggleTimer() {
    _gameStateService.setTimerRunning(!_gameStateService.isTimerRunning);

    widget.isRunning?.value = _gameStateService.isTimerRunning;
  }

  void resetTimer() {
    _gameStateService.resetTimer();

    widget.isRunning?.value = false;
  }

  Future<void> _handleNextQuarter() async {
    final currentQuarter = _gameStateService.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;
    final remainingTime = _gameStateService.getRemainingTimeInQuarter();
    final shouldSkipConfirmation = remainingTime <= 30000; // 30 seconds

    bool confirmed = shouldSkipConfirmation;

    if (!shouldSkipConfirmation) {
      final actionText = isLastQuarter ? 'End Game?' : 'End Quarter?';

      confirmed = await DialogService.showConfirmationDialog(
        context: context,
        title: '',
        content: '',
        confirmText: actionText,
      );
    }

    if (!confirmed || !mounted) return;

    final scoringState = context.findAncestorStateOfType<ScoringScreenState>();
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
