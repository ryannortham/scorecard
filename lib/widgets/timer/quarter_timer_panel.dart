import 'package:flutter/material.dart';
import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'timer_widget.dart';
import 'package:provider/provider.dart';

class QuarterTimerPanel extends StatefulWidget {
  final ValueNotifier<bool> isTimerRunning;

  const QuarterTimerPanel({super.key, required this.isTimerRunning});

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        return Column(
          children: [
            // Quarter Progress Indicator
            _buildQuarterProgressIndicator(scorePanelProvider),
            const SizedBox(height: 6.0),

            // Timer Widget
            TimerWidget(key: _timerKey, isRunning: widget.isTimerRunning),
          ],
        );
      },
    );
  }

  Widget _buildQuarterProgressIndicator(ScorePanelAdapter scorePanelProvider) {
    final currentQuarter = scorePanelProvider.selectedQuarter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final quarterNumber = index + 1;
          final isCurrentQuarter = quarterNumber == currentQuarter;
          final isCompleted = quarterNumber < currentQuarter;

          return Expanded(
            child: Container(
              margin:
                  index < 3
                      ? const EdgeInsets.only(right: 8.0)
                      : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color:
                    isCurrentQuarter
                        ? Theme.of(context).colorScheme.primaryContainer
                        : isCompleted
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Q$quarterNumber',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      isCurrentQuarter
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : isCompleted
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight:
                      isCurrentQuarter ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
