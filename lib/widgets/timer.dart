import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/pages/scoring_tab.dart';

class TimerWidget extends StatefulWidget {
  final ValueNotifier<bool>? isRunning;
  const TimerWidget({super.key, this.isRunning});

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late int quarterMSec;
  late Stream<int> tenthSecondStream;
  late Stream<int> secondStream;
  late StopWatchTimer _stopWatchTimer;
  late GameSetupProvider gameSetupProvider;
  late ScorePanelProvider scorePanelProvider;
  late StreamSubscription<int> _secondSubscription;
  final isRunning = ValueNotifier<bool>(false);

  // Custom timer state for handling negative countdown
  Timer? _customTimer;
  int _customTimerValue = 0;
  bool _isCustomTimerRunning = false;
  bool _useCustomTimer = false;

  @override
  void initState() {
    super.initState();
    gameSetupProvider = Provider.of<GameSetupProvider>(context, listen: false);
    scorePanelProvider =
        Provider.of<ScorePanelProvider>(context, listen: false);
    quarterMSec = 1000 * 60 * gameSetupProvider.quarterMinutes;

    if (gameSetupProvider.isCountdownTimer) {
      // Use custom timer for countdown to handle negative values
      _useCustomTimer = true;
      _customTimerValue = quarterMSec;
      _setupCustomTimer();
    } else {
      // Use the standard StopWatchTimer for count-up
      _useCustomTimer = false;
      _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);
      _setupStandardTimer();
    }

    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    } else {
      isRunning.value = false;
    }
  }

  void _setupCustomTimer() {
    // Set up periodic updates for UI
    tenthSecondStream = Stream.periodic(const Duration(milliseconds: 100))
        .map((_) => _customTimerValue);
    secondStream = Stream.periodic(const Duration(seconds: 1))
        .map((_) => _customTimerValue);
    _secondSubscription = secondStream.listen((_) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRawTime(_customTimerValue);
      });
    });

    // Set initial timer value after build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scorePanelProvider.setTimerRawTime(_customTimerValue);
    });
  }

  void _setupStandardTimer() {
    _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);
    tenthSecondStream = Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => _stopWatchTimer.rawTime.value);
    secondStream = Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => _stopWatchTimer.rawTime.value);
    _secondSubscription = secondStream.listen((rawTime) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRawTime(_stopWatchTimer.rawTime.value);

        // Check if the quarter timer is completed (we've reached/exceeded the time limit)
        if (_isQuarterCompleted()) {
          _checkAndNotifyTimerCompletion();
        }
      });
    });
  }

  @override
  void dispose() {
    _customTimer?.cancel();
    if (!_useCustomTimer) {
      _stopWatchTimer.dispose();
    }
    _secondSubscription.cancel();
    super.dispose();
  }

  void toggleTimer() {
    setState(() {
      if (_useCustomTimer) {
        if (_isCustomTimerRunning) {
          _customTimer?.cancel();
          _isCustomTimerRunning = false;
        } else {
          _startCustomTimer();
          _isCustomTimerRunning = true;
        }
        if (widget.isRunning != null) {
          widget.isRunning!.value = _isCustomTimerRunning;
        } else {
          isRunning.value = _isCustomTimerRunning;
        }
      } else {
        if (_stopWatchTimer.isRunning) {
          _stopWatchTimer.onStopTimer();
        } else {
          _stopWatchTimer.onStartTimer();
        }
        if (widget.isRunning != null) {
          widget.isRunning!.value = _stopWatchTimer.isRunning;
        } else {
          isRunning.value = _stopWatchTimer.isRunning;
        }
      }
    });
  }

  void _startCustomTimer() {
    _customTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _customTimerValue -= 100; // Countdown by 100ms each tick

      // Update UI
      setState(() {});

      // Update provider after build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRawTime(_customTimerValue);

        // Check if the quarter timer is completed
        if (_isQuarterCompleted()) {
          _checkAndNotifyTimerCompletion();
        }
      });
    });
  }

  void resetTimer() {
    if (_useCustomTimer) {
      _customTimer?.cancel();
      _isCustomTimerRunning = false;
      _customTimerValue = quarterMSec;

      // Update provider after build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRawTime(_customTimerValue);
      });
    } else {
      _stopWatchTimer.onResetTimer();
    }

    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    } else {
      isRunning.value = false;
    }
  }

  // Check if timer has reached or exceeded the quarter length
  bool _isQuarterCompleted() {
    if (_useCustomTimer) {
      // For countdown timer, complete when <= 0
      return _customTimerValue <= 0;
    } else {
      // For count-up timer, complete when time exceeds quarter length
      return _stopWatchTimer.rawTime.value >= quarterMSec;
    }
  }

  // Method to notify timer completion
  void _checkAndNotifyTimerCompletion() {
    // Find parent ScoringTabState to notify of timer completion
    if (_isQuarterCompleted()) {
      // Use post-frame callback to avoid during-build state changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle quarter end event by notifying parent
        final scoringState = context.findAncestorStateOfType<ScoringTabState>();
        if (scoringState != null) {
          // Get the current quarter
          final currentQuarter = scorePanelProvider.selectedQuarter;
          // Record that the quarter has ended
          scoringState.recordQuarterEnd(currentQuarter);
          // Stop the timer
          toggleTimer();
        }
      });
    }
  }

  // Method to handle next quarter transition
  void _handleNextQuarter() async {
    final currentQuarter = scorePanelProvider.selectedQuarter;
    final isLastQuarter = currentQuarter == 4;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              isLastQuarter ? 'End Game?' : 'End Quarter $currentQuarter?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    // If user cancelled or dismissed dialog, don't proceed
    if (confirmed != true) return;

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    // Find parent ScoringTabState to record quarter end event
    final scoringState = context.findAncestorStateOfType<ScoringTabState>();
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
      if (isTimerActuallyRunning) {
        toggleTimer();
      }

      // Switch to the next quarter
      scorePanelProvider.setSelectedQuarter(nextQuarter);

      // Reset the timer for the new quarter
      resetTimer();
    }
  }

  bool get isTimerActuallyRunning =>
      _useCustomTimer ? _isCustomTimerRunning : _stopWatchTimer.isRunning;
  IconData getIcon() {
    if (_useCustomTimer) {
      return _isCustomTimerRunning
          ? FontAwesomeIcons.pause
          : FontAwesomeIcons.play;
    } else {
      return _stopWatchTimer.isRunning
          ? FontAwesomeIcons.pause
          : FontAwesomeIcons.play;
    }
  }

  Color getTimerColor() {
    if (_useCustomTimer) {
      // Custom countdown timer - show error color when in negative time
      if (_customTimerValue <= 0) {
        return Theme.of(context).colorScheme.error;
      }
    } else {
      // Standard count-up timer
      if (!_stopWatchTimer.isRunning) {
        return Theme.of(context).colorScheme.onSurface;
      }
      if (_stopWatchTimer.rawTime.value > quarterMSec) {
        return Theme.of(context).colorScheme.error;
      }
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      // Timer Display
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: StreamBuilder<int>(
          stream: tenthSecondStream,
          initialData: _useCustomTimer
              ? _customTimerValue
              : scorePanelProvider.timerRawTime,
          builder: (context, snap) {
            final value = snap.data!;
            String displayTime;

            if (_useCustomTimer && value < 0) {
              // Handle negative time display for custom countdown timer
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
      Consumer2<GameSetupProvider, ScorePanelProvider>(
        builder: (context, gameSetupProvider, scorePanelProvider, _) {
          double progress = 0.0;
          if (gameSetupProvider.quarterMSec > 0 &&
              scorePanelProvider.timerRawTime >= 0) {
            progress =
                scorePanelProvider.timerRawTime / gameSetupProvider.quarterMSec;
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
            valueListenable: widget.isRunning ?? isRunning,
            builder: (context, isTimerRunning, _) {
              // Check if reset should be enabled
              bool isResetEnabled;
              if (isTimerRunning) {
                // If timer is running, reset should be disabled
                isResetEnabled = false;
              } else {
                // If timer is stopped, check if it's at default value
                if (_useCustomTimer) {
                  // For countdown timer, default is quarterMSec
                  isResetEnabled = _customTimerValue != quarterMSec;
                } else {
                  // For count-up timer, default is 0
                  isResetEnabled = _stopWatchTimer.rawTime.value != 0;
                }
              }

              return Expanded(
                flex: 2, // Smaller relative size
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilledButton.tonalIcon(
                    onPressed: isResetEnabled ? resetTimer : null,
                    icon: FaIcon(
                      FontAwesomeIcons.arrowRotateLeft,
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
            valueListenable: widget.isRunning ?? isRunning,
            builder: (context, isTimerRunning, _) {
              return Expanded(
                flex: 3, // Largest relative size for primary action
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilledButton.icon(
                    onPressed: toggleTimer,
                    icon: FaIcon(getIcon(), size: 18),
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
            valueListenable: widget.isRunning ?? isRunning,
            builder: (context, isTimerRunning, _) {
              // Check if next should be enabled
              bool isNextEnabled;
              if (isTimerRunning) {
                // If timer is running, next should be disabled
                isNextEnabled = false;
              } else {
                // If timer is stopped, check if it's at default value
                if (_useCustomTimer) {
                  // For countdown timer, default is quarterMSec
                  isNextEnabled = _customTimerValue != quarterMSec;
                } else {
                  // For count-up timer, default is 0
                  isNextEnabled = _stopWatchTimer.rawTime.value != 0;
                }
              }

              // Check if it's the last quarter (Q4)
              final isLastQuarter = scorePanelProvider.selectedQuarter == 4;

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
                    icon: FaIcon(
                      isLastQuarter
                          ? FontAwesomeIcons.flag
                          : FontAwesomeIcons.arrowRight,
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
  }
}
