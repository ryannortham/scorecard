// main timer widget with controls and quarter end handling

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/widgets/timer/timer_clock.dart';
import 'package:scorecard/widgets/timer/timer_controls.dart';

/// main timer widget with clock display and control buttons
class TimerDisplay extends StatefulWidget {
  const TimerDisplay({super.key, this.isRunning, this.onQuarterEnd});
  final ValueNotifier<bool>? isRunning;
  final void Function(int quarter)? onQuarterEnd;

  @override
  TimerDisplayState createState() => TimerDisplayState();
}

class TimerDisplayState extends State<TimerDisplay> {
  GameViewModel? _gameStateService;
  bool _listenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newService = context.read<GameViewModel>();

    if (_gameStateService != newService) {
      // Remove old listener if exists
      if (_listenerAdded && _gameStateService != null) {
        _gameStateService!.removeListener(_onTimerStateChanged);
      }

      _gameStateService = newService;
      _gameStateService!.addListener(_onTimerStateChanged);
      _listenerAdded = true;
      widget.isRunning?.value = _gameStateService!.isTimerRunning;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _onTimerStateChanged() {
    if (mounted) {
      widget.isRunning?.value = _gameStateService!.isTimerRunning;
    }
  }

  @override
  void dispose() {
    if (_listenerAdded && _gameStateService != null) {
      _gameStateService!.removeListener(_onTimerStateChanged);
    }
    super.dispose();
  }

  void toggleTimer() {
    unawaited(HapticFeedback.mediumImpact());

    _gameStateService!.setTimerRunning(
      isRunning: !_gameStateService!.isTimerRunning,
    );

    widget.isRunning?.value = _gameStateService!.isTimerRunning;
  }

  void resetTimer() {
    unawaited(HapticFeedback.selectionClick());

    _gameStateService!.resetTimer();

    widget.isRunning?.value = false;
  }

  Future<void> _handleNextQuarter() async {
    final currentQuarter = _gameStateService!.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;
    final remainingTime = _gameStateService!.getRemainingTimeInQuarter();
    final shouldSkipConfirmation = remainingTime <= 30000; // 30 seconds

    var confirmed = shouldSkipConfirmation;

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

    // Provide haptic feedback for quarter/game end
    unawaited(HapticFeedback.mediumImpact());

    widget.onQuarterEnd?.call(currentQuarter);

    if (currentQuarter == 4) return; // Game complete

    // Transition to next quarter
    if (_gameStateService!.isTimerRunning) {
      _gameStateService!.setTimerRunning(isRunning: false);
    }

    _gameStateService!.setSelectedQuarter(currentQuarter + 1);
    resetTimer();
  }

  Future<void> _handleBackQuarter() async {
    final currentQuarter = _gameStateService!.selectedQuarter;
    final previousQuarter = currentQuarter - 1;

    final confirmed = await DialogService.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: 'Go Back to Q$previousQuarter?',
    );

    if (!confirmed || !mounted) return;

    unawaited(HapticFeedback.selectionClick());

    _gameStateService!.goToPreviousQuarter();
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
            onBackQuarter: _handleBackQuarter,
            isRunningNotifier: widget.isRunning,
          ),
        ],
      ),
    );
  }
}
