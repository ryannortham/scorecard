// timer control buttons (reset, play/pause, next quarter)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/viewmodels/game_view_model.dart';

/// widget that displays the timer control buttons
class TimerControls extends StatelessWidget {
  const TimerControls({
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onNextQuarter,
    this.onBackQuarter,
    super.key,
    this.isRunningNotifier,
  });
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final VoidCallback onNextQuarter;
  final VoidCallback? onBackQuarter;
  final ValueNotifier<bool>? isRunningNotifier;

  /// determines if reset button should be enabled
  bool _isResetEnabled(GameViewModel gameState) {
    // Reset button should never be enabled while timer is running
    if (gameState.isTimerRunning) return false;

    final currentTime = gameState.timerRawTime;
    final quarterMSec = gameState.quarterMSec;

    return gameState.isCountdownTimer
        ? currentTime != quarterMSec
        : currentTime != 0;
  }

  /// determines if next button should be enabled
  bool _isNextEnabled(GameViewModel gameState) {
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

  /// determines if back button should show instead of reset
  /// Shows when timer is at initial value (reset state) and not in Q1
  bool _shouldShowBackButton(GameViewModel gameState) {
    if (gameState.isTimerRunning) return false;
    if (gameState.selectedQuarter <= 1) return false;

    // Show back when reset is disabled (timer at initial value)
    return !_isResetEnabled(gameState);
  }

  /// creates a button that switches to icon-only when space is limited
  Widget _buildAdaptiveButton({
    required VoidCallback? onPressed,
    required IconData iconData,
    required String label,
    required bool isTonal,
    double iconSize = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate if text will fit: icon + padding + text width
        // This is a rough estimate to avoid complex text measuring
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final estimatedWidth = iconSize + 16 + textPainter.width + 30;
        final hasSpace = constraints.maxWidth >= estimatedWidth;

        if (hasSpace) {
          // Show icon + label
          return isTonal
              ? FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(iconData, size: iconSize),
                label: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
              : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(iconData, size: iconSize),
                label: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
        } else {
          // Show icon only
          return isTonal
              ? FilledButton.tonal(
                onPressed: onPressed,
                child: Icon(iconData, size: iconSize),
              )
              : FilledButton(
                onPressed: onPressed,
                child: Icon(iconData, size: iconSize),
              );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Consumer<GameViewModel>(
        builder: (context, gameState, _) {
          return ValueListenableBuilder<bool>(
            valueListenable:
                isRunningNotifier ?? ValueNotifier(gameState.isTimerRunning),
            builder: (context, isTimerRunning, _) {
              final isResetEnabled = _isResetEnabled(gameState);
              final isNextEnabled = _isNextEnabled(gameState);
              final currentQuarter = gameState.selectedQuarter;
              final isLastQuarter = currentQuarter == 4;
              final showBackButton = _shouldShowBackButton(gameState);

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
                  // Reset/Back Button
                  Expanded(
                    flex: 2,
                    child:
                        showBackButton
                            ? _buildAdaptiveButton(
                              onPressed: onBackQuarter,
                              iconData: Icons.arrow_back_outlined,
                              label: 'Back',
                              isTonal: true,
                            )
                            : _buildAdaptiveButton(
                              onPressed: isResetEnabled ? onResetTimer : null,
                              iconData: Icons.refresh_outlined,
                              label: 'Reset',
                              isTonal: true,
                            ),
                  ),

                  // Play/Pause Button
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child:
                          isTimerRunning
                              ? FilledButton.tonalIcon(
                                onPressed: onToggleTimer,
                                icon: const Icon(
                                  Icons.pause_outlined,
                                  size: 18,
                                ),
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
                                      Icons.play_arrow_outlined,
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
                                      Icons.play_arrow_outlined,
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
                    child: _buildAdaptiveButton(
                      onPressed: isNextEnabled ? onNextQuarter : null,
                      iconData:
                          isLastQuarter
                              ? Icons.outlined_flag
                              : Icons.arrow_forward_outlined,
                      label: isLastQuarter ? 'End' : 'Next',
                      isTonal: !isOvertime,
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
