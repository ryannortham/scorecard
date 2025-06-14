import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';

/// Widget that displays the timer control buttons (Reset, Play/Pause, Next)
class TimerControls extends StatelessWidget {
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final VoidCallback onNextQuarter;
  final ValueNotifier<bool>? isRunningNotifier;

  const TimerControls({
    super.key,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onNextQuarter,
    this.isRunningNotifier,
  });

  /// Determines if the reset button should be enabled
  bool _isResetEnabled(
      GameSetupAdapter gameSetupAdapter, ScorePanelAdapter scorePanelAdapter) {
    if (scorePanelAdapter.isTimerRunning) {
      return false; // Disable while timer is running
    }

    final currentTime = scorePanelAdapter.timerRawTime;
    final quarterMSec = gameSetupAdapter.quarterMSec;

    if (gameSetupAdapter.isCountdownTimer) {
      return currentTime !=
          quarterMSec; // Enable if not at default countdown value
    } else {
      return currentTime != 0; // Enable if not at default count-up value
    }
  }

  /// Determines if the next button should be enabled
  bool _isNextEnabled(
      GameSetupAdapter gameSetupAdapter, ScorePanelAdapter scorePanelAdapter) {
    if (scorePanelAdapter.isTimerRunning) {
      return false; // Disable while timer is running
    }

    final currentTime = scorePanelAdapter.timerRawTime;
    final quarterMSec = gameSetupAdapter.quarterMSec;

    if (gameSetupAdapter.isCountdownTimer) {
      return currentTime !=
          quarterMSec; // Enable if not at default countdown value
    } else {
      return currentTime != 0; // Enable if not at default count-up value
    }
  }

  /// Gets the appropriate icon for the play/pause button
  IconData _getPlayPauseIcon(bool isRunning) {
    return isRunning ? Icons.pause : Icons.play_arrow;
  }

  /// Gets the appropriate label for the play/pause button
  String _getPlayPauseLabel(bool isRunning) {
    return isRunning ? 'Pause' : 'Start';
  }

  /// Gets the appropriate icon for the next button based on quarter
  IconData _getNextIcon(int currentQuarter) {
    return currentQuarter == 4 ? Icons.outlined_flag : Icons.arrow_forward;
  }

  /// Gets the appropriate label for the next button based on quarter
  String _getNextLabel(int currentQuarter) {
    return currentQuarter == 4 ? 'End' : 'Next';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupAdapter, scorePanelAdapter, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Reset Button
            ValueListenableBuilder<bool>(
              valueListenable: isRunningNotifier ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                final isEnabled =
                    _isResetEnabled(gameSetupAdapter, scorePanelAdapter);

                return Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: FilledButton.tonalIcon(
                      onPressed: isEnabled ? onResetTimer : null,
                      icon: Icon(
                        Icons.refresh,
                        size: 16,
                        color: !isEnabled
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : null,
                      ),
                      label: const Text(
                        'Reset',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Play/Pause Button
            ValueListenableBuilder<bool>(
              valueListenable: isRunningNotifier ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                return Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: FilledButton.icon(
                      onPressed: onToggleTimer,
                      icon: Icon(_getPlayPauseIcon(isTimerRunning), size: 18),
                      label: Text(
                        _getPlayPauseLabel(isTimerRunning),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Next Button
            ValueListenableBuilder<bool>(
              valueListenable: isRunningNotifier ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                final isEnabled =
                    _isNextEnabled(gameSetupAdapter, scorePanelAdapter);
                final currentQuarter = scorePanelAdapter.selectedQuarter;

                return Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: FilledButton.tonalIcon(
                      onPressed: isEnabled ? onNextQuarter : null,
                      icon: Icon(
                        _getNextIcon(currentQuarter),
                        size: 16,
                        color: !isEnabled
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : null,
                      ),
                      label: Text(
                        _getNextLabel(currentQuarter),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
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
