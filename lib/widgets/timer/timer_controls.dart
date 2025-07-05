import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/services/game_state_service.dart';

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

  /// Determines if reset button should be enabled
  bool _isResetEnabled(GameStateService gameState) {
    // Reset button should never be enabled while timer is running
    if (gameState.isTimerRunning) return false;

    final currentTime = gameState.timerRawTime;
    final quarterMSec = gameState.quarterMSec;

    return gameState.isCountdownTimer
        ? currentTime != quarterMSec
        : currentTime != 0;
  }

  /// Determines if next button should be enabled
  bool _isNextEnabled(GameStateService gameState) {
    final currentTime = gameState.timerRawTime;
    final quarterMSec = gameState.quarterMSec;

    // Check if we're in overtime
    final isOvertime =
        gameState.isCountdownTimer
            ? currentTime <= 0
            : currentTime > quarterMSec;

    // Enable if in overtime, regardless of timer state
    if (isOvertime) return true;

    // Otherwise, only enable if timer is stopped and time has changed
    if (gameState.isTimerRunning) return false;

    return gameState.isCountdownTimer
        ? currentTime != quarterMSec
        : currentTime != 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Consumer<GameStateService>(
        builder: (context, gameState, _) {
          return ValueListenableBuilder<bool>(
            valueListenable:
                isRunningNotifier ?? ValueNotifier(gameState.isTimerRunning),
            builder: (context, isTimerRunning, _) {
              final isResetEnabled = _isResetEnabled(gameState);
              final isNextEnabled = _isNextEnabled(gameState);
              final currentQuarter = gameState.selectedQuarter;
              final isLastQuarter = currentQuarter == 4;

              // Check if we're in overtime for button styling
              final currentTime = gameState.timerRawTime;
              final quarterMSec = gameState.quarterMSec;
              final isOvertime =
                  gameState.isCountdownTimer
                      ? currentTime <= 0
                      : currentTime > quarterMSec;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonalIcon(
                      onPressed: isResetEnabled ? onResetTimer : null,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'Reset',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),

                  // Play/Pause Button
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child:
                          isTimerRunning
                              ? FilledButton.tonalIcon(
                                onPressed: onToggleTimer,
                                icon: const Icon(Icons.pause, size: 18),
                                label: const Text(
                                  'Pause',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )
                              : (isOvertime
                                  ? FilledButton.tonalIcon(
                                    onPressed: onToggleTimer,
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Start',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )
                                  : FilledButton.icon(
                                    onPressed: onToggleTimer,
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Start',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )),
                    ),
                  ),

                  // Next Button
                  Expanded(
                    flex: 2,
                    child:
                        isOvertime
                            ? FilledButton.icon(
                              onPressed: isNextEnabled ? onNextQuarter : null,
                              icon: Icon(
                                isLastQuarter
                                    ? Icons.outlined_flag
                                    : Icons.arrow_forward,
                                size: 16,
                              ),
                              label: Text(
                                isLastQuarter ? 'End' : 'Next',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            )
                            : FilledButton.tonalIcon(
                              onPressed: isNextEnabled ? onNextQuarter : null,
                              icon: Icon(
                                isLastQuarter
                                    ? Icons.outlined_flag
                                    : Icons.arrow_forward,
                                size: 16,
                              ),
                              label: Text(
                                isLastQuarter ? 'End' : 'Next',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
