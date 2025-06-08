import 'package:flutter/material.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'timer_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupProvider, scorePanelProvider, _) {
          return Column(
            children: [
              // Quarter Progress Indicator
              _buildQuarterProgressIndicator(scorePanelProvider),
              const SizedBox(height: 8.0),

              // Timer Widget
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TimerWidget(
                      key: _timerKey, isRunning: widget.isTimerRunning),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuarterProgressIndicator(ScorePanelAdapter scorePanelProvider) {
    final currentQuarter = scorePanelProvider.selectedQuarter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final quarterNumber = index + 1;
          final isCurrentQuarter = quarterNumber == currentQuarter;
          final isCompleted = quarterNumber < currentQuarter;

          return Expanded(
            child: Container(
              margin: index < 3
                  ? const EdgeInsets.only(right: 4.0)
                  : EdgeInsets.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: isCurrentQuarter
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
                      color: isCurrentQuarter
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : isCompleted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
