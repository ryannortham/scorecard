// counter widget for incrementing and decrementing goals or behinds

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';

/// counter widget for scoring goals or behinds
class ScoreCounter extends StatefulWidget {
  const ScoreCounter({
    required this.label,
    required this.isGoal,
    required this.isHomeTeam,
    super.key,
    this.enabled = true,
  });
  final String label;
  final bool isGoal;
  final bool isHomeTeam;
  final bool enabled;

  @override
  ScoreCounterState createState() => ScoreCounterState();
}

class ScoreCounterState extends State<ScoreCounter> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameStateService, _) {
        final currentCount = gameStateService.getScore(
          isHomeTeam: widget.isHomeTeam,
          isGoal: widget.isGoal,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color:
                    widget.enabled
                        ? context.colors.onSurface
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
                      ? context.colors.secondaryContainer
                      : context.colors.onSurface.withValues(
                        alpha: 0.12,
                      ), // Material 3 disabled surface opacity
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
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
                          gameStateService.hasEventInCurrentQuarter(
                            isHomeTeam: widget.isHomeTeam,
                            isGoal: widget.isGoal,
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
                                  : context.colors.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
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
                                  : context.colors.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
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
    // Provide tactile feedback for score changes
    unawaited(HapticFeedback.lightImpact());

    // The game state service handles all event logic internally
    context.read<GameViewModel>().updateScore(
      isHomeTeam: widget.isHomeTeam,
      isGoal: widget.isGoal,
      newCount: newCount,
    );
  }
}
