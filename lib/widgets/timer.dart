import 'dart:async';
import 'package:flutter/material.dart';
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
      return _isCustomTimerRunning ? Icons.pause : Icons.play_arrow;
    } else {
      return _stopWatchTimer.isRunning ? Icons.pause : Icons.play_arrow;
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
      Padding(
        padding: const EdgeInsets.all(4),
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
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: getTimerColor(),
                  ),
            );
          },
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.30,
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.isRunning ?? isRunning,
              builder: (context, isTimerRunning, _) {
                return ElevatedButton(
                  onPressed: toggleTimer,
                  child: Icon(getIcon()),
                );
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.30,
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.isRunning ?? isRunning,
              builder: (context, isTimerRunning, _) {
                return ElevatedButton(
                  onPressed: isTimerRunning
                      ? null
                      : () {
                          resetTimer();
                        },
                  child: Icon(
                    Icons.restart_alt,
                    color: isTimerRunning
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38)
                        : null, // null defaults to the icon theme color
                  ),
                );
              },
            ),
          )
        ],
      ),
    ]);
  }
}
