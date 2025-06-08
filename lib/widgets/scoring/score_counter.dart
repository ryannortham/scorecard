import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/services/scoring_state_manager.dart';

class ScoreCounter extends StatefulWidget {
  final String label;
  final bool isGoal;
  final bool isHomeTeam;
  final bool enabled;

  const ScoreCounter({
    super.key,
    required this.label,
    required this.isGoal,
    required this.isHomeTeam,
    this.enabled = true,
  });

  @override
  ScoreCounterState createState() => ScoreCounterState();
}

class ScoreCounterState extends State<ScoreCounter> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScorePanelAdapter>(
      builder: (context, scorePanelAdapter, _) {
        final currentCount = scorePanelAdapter.getCount(
          widget.isHomeTeam,
          widget.isGoal,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 4),

            // Unified Counter Widget
            Card(
              elevation: 0,
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease Button
                    IconButton(
                      onPressed: widget.enabled && currentCount > 0
                          ? () => _updateCount(currentCount - 1)
                          : null,
                      icon: const Icon(Icons.remove, size: 16),
                      padding: const EdgeInsets.all(8.0),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // Count Display
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        currentCount.toString(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: widget.enabled
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.38),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),

                    // Increase Button
                    IconButton(
                      onPressed: widget.enabled && currentCount < 99
                          ? () => _updateCount(currentCount + 1)
                          : null,
                      icon: const Icon(Icons.add, size: 16),
                      padding: const EdgeInsets.all(8.0),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateCount(int newCount) {
    // Use the decoupled scoring state manager
    final scoringStateManager = ScoringStateManager.instance;

    // The scoring state manager handles all event logic internally
    scoringStateManager.updateScore(widget.isHomeTeam, widget.isGoal, newCount);
  }
}
