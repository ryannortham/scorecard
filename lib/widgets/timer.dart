import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';

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
    _secondSubscription = secondStream.listen((_) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRawTime(_stopWatchTimer.rawTime.value);
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

  bool get isTimerActuallyRunning =>
      _useCustomTimer ? _isCustomTimerRunning : _stopWatchTimer.isRunning;
  IconData getIcon() {
    if (_useCustomTimer) {
      if (_isCustomTimerRunning) {
        // If timer is running and in negative time (overtime), show stop icon
        if (_customTimerValue <= 0) {
          return FontAwesomeIcons.stop;
        }
        return FontAwesomeIcons.pause;
      } else {
        return FontAwesomeIcons.play;
      }
    } else {
      if (_stopWatchTimer.isRunning) {
        // If timer is running and past quarter end (overtime), show stop icon
        if (_stopWatchTimer.rawTime.value > quarterMSec) {
          return FontAwesomeIcons.stop;
        }
        return FontAwesomeIcons.pause;
      } else {
        return FontAwesomeIcons.play;
      }
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: getTimerColor(),
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
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
          // Play/Pause/Stop Button
          ValueListenableBuilder<bool>(
            valueListenable: widget.isRunning ?? isRunning,
            builder: (context, isTimerRunning, _) {
              // Determine button text based on current state
              String buttonText;
              if (!isTimerRunning) {
                buttonText = 'Start';
              } else {
                // Check if we're in overtime (should show "Stop")
                if (_useCustomTimer) {
                  buttonText = _customTimerValue <= 0 ? 'Stop' : 'Pause';
                } else {
                  buttonText = _stopWatchTimer.rawTime.value > quarterMSec
                      ? 'Stop'
                      : 'Pause';
                }
              }

              return SizedBox(
                width: 120, // Wider to accommodate full text
                child: FilledButton.icon(
                  onPressed: toggleTimer,
                  icon: FaIcon(getIcon(), size: 18),
                  label: Text(
                    buttonText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            },
          ),

          // Reset Button
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

              return SizedBox(
                width: 120, // Wider to match the other button
                child: FilledButton.tonalIcon(
                  onPressed: isResetEnabled ? resetTimer : null,
                  icon: FaIcon(
                    FontAwesomeIcons.arrowRotateLeft,
                    size: 18,
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
              );
            },
          ),
        ],
      ),
    ]);
  }
}
