import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/widgets/timer.dart';
import 'package:provider/provider.dart';

class QuarterTimerPanel extends StatefulWidget {
  final ValueNotifier<bool> isTimerRunning;

  const QuarterTimerPanel({
    super.key,
    required this.isTimerRunning,
  });

  @override
  State<QuarterTimerPanel> createState() => QuarterTimerPanelState();
}

class QuarterTimerPanelState extends State<QuarterTimerPanel> {
  final GlobalKey<TimerWidgetState> _timerKey = GlobalKey<TimerWidgetState>();

  // Expose method to reset timer from parent widgets
  void resetTimer() {
    _timerKey.currentState?.resetTimer();
  }

  // Expose method to start timer from parent widgets
  void startTimer() {
    final timerState = _timerKey.currentState;
    if (timerState != null && !timerState.isTimerActuallyRunning) {
      timerState.toggleTimer();
    }
  }

  double getProgressValue(GameSetupProvider gameSetupProvider,
      ScorePanelProvider scorePanelProvider) {
    if (gameSetupProvider.quarterMSec <= 0 ||
        scorePanelProvider.timerRawTime < 0) {
      return 0.0;
    }

    double progress =
        scorePanelProvider.timerRawTime / gameSetupProvider.quarterMSec;
    return progress.clamp(0.0, 1.0);
  }

  void _handleQuarterChange(
    int newQuarter,
    ScorePanelProvider scorePanelProvider,
  ) {
    final currentQuarter = scorePanelProvider.selectedQuarter;

    // If selecting the same quarter, do nothing
    if (newQuarter == currentQuarter) return;

    // Switch to the new quarter
    scorePanelProvider.setSelectedQuarter(newQuarter);

    // Reset the actual timer widget
    _timerKey.currentState?.resetTimer();
  }

  Color? _getQuarterTextColor(BuildContext context, int quarterNumber,
      int selectedQuarter, bool isTimerRunning) {
    // When timer is running, mute non-selected quarters to show they're effectively disabled
    if (isTimerRunning && quarterNumber != selectedQuarter) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    }

    // For all other cases (timer not running, or selected quarter), use default colors
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupProvider, ScorePanelProvider>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(
                value: getProgressValue(gameSetupProvider, scorePanelProvider),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder<bool>(
              valueListenable: widget.isTimerRunning,
              builder: (context, isTimerRunning, _) {
                return ToggleButtons(
                  isSelected: List.generate(
                      4,
                      (index) =>
                          scorePanelProvider.selectedQuarter == index + 1),
                  onPressed: (index) {
                    final quarterNumber = index + 1;
                    // If timer is running, only allow selecting the current quarter (no-op)
                    if (isTimerRunning &&
                        quarterNumber != scorePanelProvider.selectedQuarter) {
                      return;
                    }
                    _handleQuarterChange(quarterNumber, scorePanelProvider);
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Quarter 1',
                        style: TextStyle(
                          color: _getQuarterTextColor(
                              context,
                              1,
                              scorePanelProvider.selectedQuarter,
                              isTimerRunning),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Quarter 2',
                        style: TextStyle(
                          color: _getQuarterTextColor(
                              context,
                              2,
                              scorePanelProvider.selectedQuarter,
                              isTimerRunning),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Quarter 3',
                        style: TextStyle(
                          color: _getQuarterTextColor(
                              context,
                              3,
                              scorePanelProvider.selectedQuarter,
                              isTimerRunning),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Quarter 4',
                        style: TextStyle(
                          color: _getQuarterTextColor(
                              context,
                              4,
                              scorePanelProvider.selectedQuarter,
                              isTimerRunning),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            TimerWidget(key: _timerKey, isRunning: widget.isTimerRunning),
            const SizedBox(height: 8.0),
          ],
        );
      },
    );
  }
}
