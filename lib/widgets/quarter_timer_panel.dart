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

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupProvider, ScorePanelProvider>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        return Column(
          children: [
            // Quarter Selection
            ValueListenableBuilder<bool>(
              valueListenable: widget.isTimerRunning,
              builder: (context, isTimerRunning, _) {
                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Q1'),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('Q2'),
                      ),
                      ButtonSegment<int>(
                        value: 3,
                        label: Text('Q3'),
                      ),
                      ButtonSegment<int>(
                        value: 4,
                        label: Text('Q4'),
                      ),
                    ],
                    selected: {scorePanelProvider.selectedQuarter},
                    onSelectionChanged: (Set<int> newSelection) {
                      if (!isTimerRunning && newSelection.isNotEmpty) {
                        _handleQuarterChange(
                          newSelection.first,
                          scorePanelProvider,
                        );
                      }
                    },
                    multiSelectionEnabled: false,
                    emptySelectionAllowed: false,
                    showSelectedIcon: false,
                  ),
                );
              },
            ),
            const SizedBox(height: 12.0),

            // Timer Widget
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TimerWidget(
                    key: _timerKey, isRunning: widget.isTimerRunning),
              ),
            ),
          ],
        );
      },
    );
  }
}
