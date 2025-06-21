import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/services/game_state_service.dart';

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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: widget.enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 6),

            // Unified Counter Widget
            Card(
              elevation: 2,
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease Button
                    IconButton(
                      onPressed: widget.enabled &&
                              currentCount > 0 &&
                              scorePanelAdapter.hasEventInCurrentQuarter(
                                  widget.isHomeTeam, widget.isGoal)
                          ? () => _updateCount(currentCount - 1)
                          : null,
                      icon: const Icon(Icons.remove_outlined, size: 18),
                      padding: const EdgeInsets.all(8.0),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),

                    // Count Display
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
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
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),

                    // Increase Button
                    IconButton(
                      onPressed: widget.enabled && currentCount < 99
                          ? () => _updateCount(currentCount + 1)
                          : null,
                      icon: const Icon(Icons.add_outlined, size: 18),
                      padding: const EdgeInsets.all(8.0),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
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
    // Use the game state service directly
    final gameStateService = GameStateService.instance;

    // The game state service handles all event logic internally
    gameStateService.updateScore(widget.isHomeTeam, widget.isGoal, newCount);
  }
}
