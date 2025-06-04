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

  @override
  void initState() {
    super.initState();
    gameSetupProvider = Provider.of<GameSetupProvider>(context, listen: false);
    scorePanelProvider =
        Provider.of<ScorePanelProvider>(context, listen: false);
    quarterMSec = 1000 * 60 * gameSetupProvider.quarterMinutes;
    _stopWatchTimer = StopWatchTimer(
      mode: gameSetupProvider.isCountdownTimer
          ? StopWatchMode.countDown
          : StopWatchMode.countUp,
    );
    if (gameSetupProvider.isCountdownTimer) {
      _stopWatchTimer.setPresetTime(mSec: quarterMSec);
    }
    tenthSecondStream = Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => _stopWatchTimer.rawTime.value);
    secondStream = Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => _stopWatchTimer.rawTime.value);
    _secondSubscription = secondStream.listen((_) {
      scorePanelProvider.setTimerRawTime(_stopWatchTimer.rawTime.value);
    });
    if (widget.isRunning != null) {
      widget.isRunning!.value = false;
    } else {
      isRunning.value = false;
    }
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    _secondSubscription.cancel();
    super.dispose();
  }

  void toggleTimer() {
    setState(() {
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
    });
  }

  void resetTimer() {
    _stopWatchTimer.onResetTimer();
    if (widget.isRunning != null) {
      widget.isRunning!.value = _stopWatchTimer.isRunning;
    } else {
      isRunning.value = _stopWatchTimer.isRunning;
    }
  }

  bool get isTimerActuallyRunning => _stopWatchTimer.isRunning;

  IconData getIcon() {
    return _stopWatchTimer.isRunning ? Icons.pause : Icons.play_arrow;
  }

  Color getTimerColor() {
    if (gameSetupProvider.isCountdownTimer) {
      if (_stopWatchTimer.rawTime.value <= 0) {
        return Theme.of(context).colorScheme.error;
      }
    } else {
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
          initialData: scorePanelProvider.timerRawTime,
          builder: (context, snap) {
            final value = snap.data!;
            final displayTime = StopWatchTimer.getDisplayTime(value,
                hours: false, milliSecond: true);
            final trimmedDisplayTime =
                displayTime.substring(0, displayTime.length - 1);
            return Text(
              trimmedDisplayTime,
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
