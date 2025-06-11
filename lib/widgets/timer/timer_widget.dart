import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/services/game_state_service.dart';
import 'package:goalkeeper/screens/scoring.dart';
import '../bottom_sheets/end_quarter_bottom_sheet.dart';

class TimerWidget extends StatefulWidget {
  final ValueNotifier<bool>? isRunning;
  const TimerWidget({super.key, this.isRunning});

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late GameSetupAdapter gameSetupProvider;
  late ScorePanelAdapter scorePanelProvider;
  final GameStateService _gameStateService = GameStateService.instance;

  @override
  void initState() {
    super.initState();

    // Initialize providers from context
    gameSetupProvider = Provider.of<GameSetupAdapter>(context, listen: false);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context, listen: false);

    // Listen to timer state changes to sync with widget.isRunning
    _gameStateService.addListener(_onTimerStateChanged);

    // Set initial state
    if (widget.isRunning != null) {
      widget.isRunning!.value = _gameStateService.isTimerRunning;
    }
  }

  void _onTimerStateChanged() {
    if (mounted && widget.isRunning != null) {
      widget.isRunning!.value = scorePanelProvider.isTimerRunning;
    }
  }

  @override
  void dispose() {
    _gameStateService.removeListener(_onTimerStateChanged);
    super.dispose();
  }

  void toggleTimer() {
    scorePanelProvider.setTimerRunning(!scorePanelProvider.isTimerRunning);

    if (widget.isRunning != null) {
      widget.isRunning!.value = scorePanelProvider.isTimerRunning;
    }
  }

  void resetTimer() {
    // Reset timer through the centralized service
    _gameStateService.resetTimer();

    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    }
  }

  // Method to handle next quarter transition
  void _handleNextQuarter() async {
    final currentQuarter = scorePanelProvider.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;

    // Check if there are 30 seconds or less remaining in the quarter
    // Use actual elapsed time for business logic, not display time
    final thirtySecondsInMs = 30 * 1000; // 30 seconds in milliseconds
    final remainingTimeInQuarter =
        _gameStateService.getRemainingTimeInQuarter();
    // Skip confirmation if 30 seconds or less remaining, OR if in overtime (negative time)
    final shouldSkipConfirmation = remainingTimeInQuarter <= thirtySecondsInMs;

    bool confirmed = true; // Default to confirmed if skipping dialog

    // Show confirmation bottom sheet only if more than 30 seconds remaining
    if (!shouldSkipConfirmation) {
      confirmed = await EndQuarterBottomSheet.show(
        context: context,
        currentQuarter: currentQuarter,
        isLastQuarter: isLastQuarter,
        onConfirm: () {}, // The bottom sheet handles navigation internally
      );
    }

    // If user cancelled dialog, don't proceed
    if (!confirmed) return;

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    // Find parent ScoringState to record quarter end event
    final scoringState = context.findAncestorStateOfType<ScoringState>();
    if (scoringState != null) {
      // Record clock_end event for the current quarter
      scoringState.recordQuarterEnd(currentQuarter);

      // If it's the last quarter (Q4), end the game
      if (currentQuarter == 4) {
        // Game completion is handled in recordQuarterEnd
        return;
      }

      // Otherwise, transition to the next quarter
      final nextQuarter = currentQuarter + 1;

      // If timer is running, pause it before changing quarters
      if (scorePanelProvider.isTimerRunning) {
        scorePanelProvider.setTimerRunning(false);
      }

      // Switch to the next quarter
      scorePanelProvider.setSelectedQuarter(nextQuarter);

      // Reset the timer for the new quarter
      resetTimer();
    }
  }

  bool get isTimerActuallyRunning => scorePanelProvider.isTimerRunning;

  IconData getIcon() {
    return scorePanelProvider.isTimerRunning ? Icons.pause : Icons.play_arrow;
  }

  Color getTimerColor() {
    final currentTime = scorePanelProvider.timerRawTime;
    final quarterMSec = gameSetupProvider.quarterMSec;

    if (gameSetupProvider.isCountdownTimer) {
      // Countdown timer - show error color when in negative time
      if (currentTime <= 0) {
        return Theme.of(context).colorScheme.error;
      }
    } else {
      // Count-up timer
      if (!scorePanelProvider.isTimerRunning) {
        return Theme.of(context).colorScheme.onSurface;
      }
      if (currentTime > quarterMSec) {
        return Theme.of(context).colorScheme.error;
      }
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupAdapter, scorePanelAdapter, _) {
      return Column(children: <Widget>[
        // Timer Display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: StreamBuilder<int>(
            stream: _gameStateService.timerStream,
            initialData: scorePanelAdapter.timerRawTime,
            builder: (context, snap) {
              final value = snap.data!;
              String displayTime;

              if (gameSetupAdapter.isCountdownTimer && value < 0) {
                // Handle negative time display for countdown timer
                final absValue = value.abs();
                final timeStr = StopWatchTimer.getDisplayTime(absValue,
                    hours: false, milliSecond: true);
                final trimmedTimeStr = timeStr.substring(0, timeStr.length - 1);
                displayTime = '-$trimmedTimeStr';
              } else {
                // Standard positive time display
                final timeStr = StopWatchTimer.getDisplayTime(value,
                    hours: false, milliSecond: true);
                displayTime = timeStr.substring(0, timeStr.length - 1);
              }

              return Text(
                displayTime,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: getTimerColor(),
                      fontWeight: FontWeight.w600,
                    ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Progress Indicator
        StreamBuilder<int>(
          stream: _gameStateService.timerStream,
          initialData: scorePanelAdapter.timerRawTime,
          builder: (context, snapshot) {
            final timerValue = snapshot.data ?? scorePanelAdapter.timerRawTime;
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
        const SizedBox(height: 12),

        // Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // Reset Button (moved to left, smaller relative size)
            ValueListenableBuilder<bool>(
              valueListenable: widget.isRunning ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                // Check if reset should be enabled
                bool isResetEnabled;
                if (isTimerRunning) {
                  // If timer is running, reset should be disabled
                  isResetEnabled = false;
                } else {
                  // If timer is stopped, check if it's at default value
                  final currentTime = scorePanelAdapter.timerRawTime;
                  final quarterMSec = gameSetupAdapter.quarterMSec;

                  if (gameSetupAdapter.isCountdownTimer) {
                    // For countdown timer, default is quarterMSec
                    isResetEnabled = currentTime != quarterMSec;
                  } else {
                    // For count-up timer, default is 0
                    isResetEnabled = currentTime != 0;
                  }
                }

                return Expanded(
                  flex: 2, // Smaller relative size
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilledButton.tonalIcon(
                      onPressed: isResetEnabled ? resetTimer : null,
                      icon: Icon(
                        Icons.refresh,
                        size: 16,
                        color: !isResetEnabled
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
              valueListenable: widget.isRunning ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                return Expanded(
                  flex: 3, // Largest relative size for primary action
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilledButton.icon(
                      onPressed: toggleTimer,
                      icon: Icon(getIcon(), size: 18),
                      label: Text(
                        isTimerRunning ? 'Pause' : 'Start',
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
              valueListenable: widget.isRunning ??
                  ValueNotifier(scorePanelAdapter.isTimerRunning),
              builder: (context, isTimerRunning, _) {
                // Check if next should be enabled
                bool isNextEnabled;
                if (isTimerRunning) {
                  // If timer is running, next should be disabled
                  isNextEnabled = false;
                } else {
                  // If timer is stopped, check if it's at default value
                  final currentTime = scorePanelAdapter.timerRawTime;
                  final quarterMSec = gameSetupAdapter.quarterMSec;

                  if (gameSetupAdapter.isCountdownTimer) {
                    // For countdown timer, default is quarterMSec
                    isNextEnabled = currentTime != quarterMSec;
                  } else {
                    // For count-up timer, default is 0
                    isNextEnabled = currentTime != 0;
                  }
                }

                // Check if it's the last quarter (Q4)
                final isLastQuarter = scorePanelAdapter.selectedQuarter == 4;

                return Expanded(
                  flex: 2, // Same relative size as reset button
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilledButton.tonalIcon(
                      onPressed: isNextEnabled
                          ? () {
                              _handleNextQuarter();
                            }
                          : null,
                      icon: Icon(
                        isLastQuarter
                            ? Icons.outlined_flag
                            : Icons.arrow_forward,
                        size: 16,
                        color: !isNextEnabled
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : null,
                      ),
                      label: Text(
                        isLastQuarter ? 'End' : 'Next',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ]);
    });
  }
}
