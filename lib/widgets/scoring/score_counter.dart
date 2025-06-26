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
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color:
                    widget.enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.38),
                height: 1.2,
              ),
            ),

            Card(
              elevation: 0,
              margin: const EdgeInsets.only(top: 8),
              color:
                  widget.enabled
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ), // Material 3 disabled surface opacity
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrease Button
                  Builder(
                    builder: (context) {
                      final canDecrease =
                          widget.enabled &&
                          currentCount > 0 &&
                          scorePanelAdapter.hasEventInCurrentQuarter(
                            widget.isHomeTeam,
                            widget.isGoal,
                          );

                      return IconButton(
                        onPressed:
                            canDecrease
                                ? () => _updateCount(currentCount - 1)
                                : null,
                        icon: Icon(
                          Icons.remove_outlined,
                          size: 18,
                          color:
                              canDecrease
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                  : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.38),
                        ),
                      );
                    },
                  ),

                  // Count Display
                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    child: Text(
                      currentCount.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            widget.enabled
                                ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ),

                  // Increase Button
                  Builder(
                    builder: (context) {
                      final canIncrease = widget.enabled && currentCount < 99;

                      return IconButton(
                        onPressed:
                            canIncrease
                                ? () => _updateCount(currentCount + 1)
                                : null,
                        icon: Icon(
                          Icons.add_outlined,
                          size: 18,
                          color:
                              canIncrease
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                  : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.38),
                        ),
                      );
                    },
                  ),
                ],
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
