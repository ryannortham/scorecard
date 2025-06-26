import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';

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

  /// Determines if reset/next buttons should be enabled
  bool _isButtonEnabled(
    GameSetupAdapter gameSetupAdapter,
    ScorePanelAdapter scorePanelAdapter,
  ) {
    if (scorePanelAdapter.isTimerRunning) return false;

    final currentTime = scorePanelAdapter.timerRawTime;
    final quarterMSec = gameSetupAdapter.quarterMSec;

    return gameSetupAdapter.isCountdownTimer
        ? currentTime != quarterMSec
        : currentTime != 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupAdapter, scorePanelAdapter, _) {
          return ValueListenableBuilder<bool>(
            valueListenable:
                isRunningNotifier ??
                ValueNotifier(scorePanelAdapter.isTimerRunning),
            builder: (context, isTimerRunning, _) {
              final isEnabled = _isButtonEnabled(
                gameSetupAdapter,
                scorePanelAdapter,
              );
              final currentQuarter = scorePanelAdapter.selectedQuarter;
              final isLastQuarter = currentQuarter == 4;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonalIcon(
                      onPressed: isEnabled ? onResetTimer : null,
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
                      child: FilledButton.tonalIcon(
                        onPressed: onToggleTimer,
                        icon: Icon(
                          isTimerRunning ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          isTimerRunning ? 'Pause' : 'Start',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonalIcon(
                      onPressed: isEnabled ? onNextQuarter : null,
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
