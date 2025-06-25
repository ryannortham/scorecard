import 'package:flutter/material.dart';
import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'timer_widget.dart';
import 'quarter_progress.dart';
import 'package:provider/provider.dart';

class TimerPanel extends StatefulWidget {
  final ValueNotifier<bool> isTimerRunning;

  const TimerPanel({super.key, required this.isTimerRunning});

  @override
  State<TimerPanel> createState() => TimerPanelState();
}

class TimerPanelState extends State<TimerPanel> {
  final GlobalKey<TimerWidgetState> _timerKey = GlobalKey<TimerWidgetState>();

  // Expose method to reset timer from parent widgets
  void resetTimer() {
    _timerKey.currentState?.resetTimer();
  }

  // Expose method to start timer from parent widgets
  void startTimer() {
    final timerState = _timerKey.currentState;
    if (timerState != null && !timerState.isTimerActuallyRunning) {
      timerState.toggleTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        return Column(
          children: [
            QuarterProgress(scorePanelProvider: scorePanelProvider),

            const SizedBox(height: 6.0),

            TimerWidget(key: _timerKey, isRunning: widget.isTimerRunning),
          ],
        );
      },
    );
  }
}
