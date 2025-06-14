import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/services/game_state_service.dart';

/// Widget that displays the timer value and progress indicator
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  /// Gets the appropriate color for the timer display based on current state
  Color _getTimerColor(BuildContext context) {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final scorePanelAdapter =
        Provider.of<ScorePanelAdapter>(context, listen: false);

    final currentTime = scorePanelAdapter.timerRawTime;
    final quarterMSec = gameSetupAdapter.quarterMSec;

    if (gameSetupAdapter.isCountdownTimer) {
      // Countdown timer - show error color when in negative time
      if (currentTime <= 0) {
        return Theme.of(context).colorScheme.error;
      }
    } else {
      // Count-up timer
      if (!scorePanelAdapter.isTimerRunning) {
        return Theme.of(context).colorScheme.onSurface;
      }
      if (currentTime > quarterMSec) {
        return Theme.of(context).colorScheme.error;
      }
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Formats the timer display string
  String _formatTimerDisplay(int value, bool isCountdownTimer) {
    if (isCountdownTimer && value < 0) {
      // Handle negative time display for countdown timer
      final absValue = value.abs();
      final timeStr = StopWatchTimer.getDisplayTime(absValue,
          hours: false, milliSecond: true);
      final trimmedTimeStr = timeStr.substring(0, timeStr.length - 1);
      return '-$trimmedTimeStr';
    } else {
      // Standard positive time display
      final timeStr =
          StopWatchTimer.getDisplayTime(value, hours: false, milliSecond: true);
      return timeStr.substring(0, timeStr.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameStateService = GameStateService.instance;

    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupAdapter, scorePanelAdapter, _) {
        return Column(
          children: [
            // Timer Display
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: StreamBuilder<int>(
                stream: gameStateService.timerStream,
                initialData: scorePanelAdapter.timerRawTime,
                builder: (context, snap) {
                  final value = snap.data!;
                  final displayTime = _formatTimerDisplay(
                      value, gameSetupAdapter.isCountdownTimer);

                  return Text(
                    displayTime,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _getTimerColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Progress Indicator
            StreamBuilder<int>(
              stream: gameStateService.timerStream,
              initialData: scorePanelAdapter.timerRawTime,
              builder: (context, snapshot) {
                final timerValue =
                    snapshot.data ?? scorePanelAdapter.timerRawTime;
                double progress = 0.0;
                if (gameSetupAdapter.quarterMSec > 0 && timerValue >= 0) {
                  progress = timerValue / gameSetupAdapter.quarterMSec;
                  progress = progress.clamp(0.0, 1.0);
                }

                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
