import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/services/game_state_service.dart';

/// Widget that displays the timer value and progress indicator
class TimerClock extends StatelessWidget {
  const TimerClock({super.key});

  /// Gets the appropriate color for the timer display based on current state
  Color _getTimerColor(
    BuildContext context,
    int currentTime,
    int quarterMSec,
    bool isCountdownTimer,
  ) {
    final isOvertime =
        isCountdownTimer ? currentTime <= 0 : currentTime > quarterMSec;
    return isOvertime
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
  }

  /// Formats the timer display string
  String _formatTimerClock(int value, bool isCountdownTimer) {
    final absValue = isCountdownTimer && value < 0 ? value.abs() : value;
    final timeStr = StopWatchTimer.getDisplayTime(
      absValue,
      hours: false,
      milliSecond: true,
    );
    final trimmedTime = timeStr.substring(0, timeStr.length - 1);

    return (isCountdownTimer && value < 0) ? '-$trimmedTime' : trimmedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupAdapter, scorePanelAdapter, _) {
        return StreamBuilder<int>(
          stream: GameStateService.instance.timerStream,
          initialData: scorePanelAdapter.timerRawTime,
          builder: (context, snapshot) {
            final timerValue = snapshot.data ?? scorePanelAdapter.timerRawTime;
            final quarterMSec = gameSetupAdapter.quarterMSec;
            final isCountdownTimer = gameSetupAdapter.isCountdownTimer;

            final progress =
                quarterMSec > 0 && timerValue >= 0
                    ? (timerValue / quarterMSec).clamp(0.0, 1.0)
                    : 0.0;

            return Column(
              children: [
                Text(
                  _formatTimerClock(timerValue, isCountdownTimer),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _getTimerColor(
                      context,
                      timerValue,
                      quarterMSec,
                      isCountdownTimer,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress),
              ],
            );
          },
        );
      },
    );
  }
}
