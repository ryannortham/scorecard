import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int quarterMSec;
  late Stream<int> tenthSecondStream;
  late StopWatchTimer _stopWatchTimer;
  late GameSetupProvider gameSetupProvider;

  @override
  void initState() {
    super.initState();
    gameSetupProvider = Provider.of<GameSetupProvider>(context, listen: false);
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
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    super.dispose();
  }

  void toggleTimer() {
    setState(() {
      if (_stopWatchTimer.isRunning) {
        _stopWatchTimer.onStopTimer();
      } else {
        _stopWatchTimer.onStartTimer();
      }
    });
  }

  IconData getIcon() {
    return _stopWatchTimer.isRunning ? Icons.stop : Icons.play_arrow;
  }

  Color getTimerColor() {
    if (gameSetupProvider.isCountdownTimer) {
      if (_stopWatchTimer.rawTime.value <= 0) {
        return Theme.of(context).colorScheme.error;
      }
    } else {
      if (_stopWatchTimer.rawTime.value >= quarterMSec) {
        return Theme.of(context).colorScheme.error;
      }
    }
    return Theme.of(context).colorScheme.onBackground;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<int>(
          stream: tenthSecondStream,
          initialData: 0,
          builder: (context, snap) {
            final value = snap.data!;
            final displayTime = StopWatchTimer.getDisplayTime(value,
                hours: false, milliSecond: true);
            final trimmedDisplayTime =
                displayTime.substring(0, displayTime.length - 1);
            return Text(
              trimmedDisplayTime,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: getTimerColor(),
                  ),
            );
          },
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: toggleTimer,
            child: Icon(getIcon()),
          ),
          ElevatedButton(
            onPressed: () {
              _stopWatchTimer.onResetTimer();
            },
            child: const Icon(Icons.restart_alt),
          ),
        ],
      ),
    ]);
  }
}
