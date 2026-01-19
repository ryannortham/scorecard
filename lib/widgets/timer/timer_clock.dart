import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:vibration/vibration.dart';

import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';

/// Widget that displays the timer value and progress indicator
class TimerClock extends StatefulWidget {
  const TimerClock({super.key});

  @override
  State<TimerClock> createState() => _TimerClockState();
}

class _TimerClockState extends State<TimerClock> {
  int? _previousTimerValue;
  bool _hasVibratedForOvertime = false;
  bool? _hasVibrator; // Cache vibration capability

  @override
  void initState() {
    super.initState();
    _checkVibrationCapability();
  }

  /// Check vibration capability once and cache the result
  void _checkVibrationCapability() async {
    _hasVibrator = await Vibration.hasVibrator();
  }

  /// Gets the appropriate color for the timer display based on current state
  Color _getTimerColor(
    BuildContext context,
    int currentTime,
    int quarterMSec,
    bool isCountdownTimer,
  ) {
    final isOvertime =
        isCountdownTimer ? currentTime <= 0 : currentTime > quarterMSec;
    return isOvertime ? context.colors.error : context.colors.onSurface;
  }

  /// Formats the timer display string based on user preference, not game state
  String _formatTimerClock(
    int elapsedTime,
    bool displayAsCountdown,
    int quarterMSec,
  ) {
    // Calculate what the display value should be based on display preference
    int displayValue;
    if (displayAsCountdown) {
      // Show remaining time (quarter time - elapsed time)
      displayValue = quarterMSec - elapsedTime;
    } else {
      // Show elapsed time
      displayValue = elapsedTime;
    }

    final absValue = displayValue < 0 ? displayValue.abs() : displayValue;
    final timeStr = StopWatchTimer.getDisplayTime(
      absValue,
      hours: false,
      milliSecond: true,
    );
    final trimmedTime = timeStr.substring(0, timeStr.length - 1);

    return (displayValue < 0) ? '-$trimmedTime' : trimmedTime;
  }

  /// Triggers vibration when timer reaches quarter end/overtime (optimized)
  void _checkForOvertimeVibration(
    int currentTime,
    int quarterMSec,
    bool isCountdownTimer,
  ) {
    // Early exit if no vibration capability
    if (_hasVibrator != true) {
      _previousTimerValue = currentTime;
      return;
    }

    final isOvertime =
        isCountdownTimer ? currentTime <= 0 : currentTime > quarterMSec;

    // Reset vibration flag when not in overtime
    if (!isOvertime) {
      _hasVibratedForOvertime = false;
      _previousTimerValue = currentTime;
      return;
    }

    // Check if we just entered overtime and haven't vibrated yet
    if (_hasVibratedForOvertime) {
      _previousTimerValue = currentTime;
      return;
    }

    final wasNotOvertime =
        _previousTimerValue != null &&
        (isCountdownTimer
            ? _previousTimerValue! > 0
            : _previousTimerValue! <= quarterMSec);

    // Trigger vibration when transitioning from normal time to overtime
    if (wasNotOvertime) {
      _triggerOvertimeVibration();
      _hasVibratedForOvertime = true;
    }

    _previousTimerValue = currentTime;
  }

  /// Triggers vibration pattern for overtime (non-blocking)
  void _triggerOvertimeVibration() {
    // Check if vibration is available (using cached result)
    if (_hasVibrator == true) {
      // Use fire-and-forget to avoid blocking the UI thread
      Vibration.vibrate(pattern: [0, 200, 100, 400]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameStateService, UserPreferencesProvider>(
      builder: (context, gameState, userPreferences, _) {
        return StreamBuilder<int>(
          stream: GameStateService.instance.timerStream,
          initialData: gameState.timerRawTime,
          builder: (context, snapshot) {
            final timerValue = snapshot.data ?? gameState.timerRawTime;
            final quarterMSec = gameState.quarterMSec;
            final isCountdownTimer = gameState.isCountdownTimer;
            final displayAsCountdown = userPreferences.isCountdownTimer;
            final currentQuarter = gameState.selectedQuarter;

            // Get elapsed time for display calculation
            final elapsedTime = gameState.getElapsedTimeInQuarter();

            final progress =
                quarterMSec > 0 && timerValue >= 0
                    ? (timerValue / quarterMSec).clamp(0.0, 1.0)
                    : 0.0;

            // Check and trigger vibration for overtime
            _checkForOvertimeVibration(
              timerValue,
              quarterMSec,
              isCountdownTimer,
            );

            return Column(
              children: [
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      // Left section for quarter text
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Q$currentQuarter',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: _getTimerColor(
                                context,
                                timerValue,
                                quarterMSec,
                                isCountdownTimer,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      // Center section for timer text
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            _formatTimerClock(
                              elapsedTime,
                              displayAsCountdown,
                              quarterMSec,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: _getTimerColor(
                                context,
                                timerValue,
                                quarterMSec,
                                isCountdownTimer,
                              ),
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Right section for balance
                      const Expanded(flex: 1, child: SizedBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress),
              ],
            );
          },
        );
      },
    );
  }
}
