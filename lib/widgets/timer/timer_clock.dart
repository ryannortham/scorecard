import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

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
    return Consumer<GameStateService>(
      builder: (context, gameState, _) {
        return StreamBuilder<int>(
          stream: GameStateService.instance.timerStream,
          initialData: gameState.timerRawTime,
          builder: (context, snapshot) {
            final timerValue = snapshot.data ?? gameState.timerRawTime;
            final quarterMSec = gameState.quarterMSec;
            final isCountdownTimer = gameState.isCountdownTimer;
            final currentQuarter = gameState.selectedQuarter;

            final progress =
                quarterMSec > 0 && timerValue >= 0
                    ? (timerValue / quarterMSec).clamp(0.0, 1.0)
                    : 0.0;

            return Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      // Left section for quarter text
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Q$currentQuarter',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: _getTimerColor(
                                context,
                                timerValue,
                                quarterMSec,
                                isCountdownTimer,
                              ).withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      // Center section for timer text
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            _formatTimerClock(timerValue, isCountdownTimer),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: _getTimerColor(
                                context,
                                timerValue,
                                quarterMSec,
                                isCountdownTimer,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right section for balance
                      const Expanded(flex: 1, child: SizedBox()),
                    ],
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
