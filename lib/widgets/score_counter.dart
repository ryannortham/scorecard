import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/pages/scoring.dart';

class ScoreCounter extends StatefulWidget {
  final String label;
  final bool isGoal;
  final bool isHomeTeam;
  final ScorePanelProvider scorePanelProvider;
  final bool enabled;

  const ScoreCounter({
    super.key,
    required this.label,
    required this.isGoal,
    required this.isHomeTeam,
    required this.scorePanelProvider,
    this.enabled = true,
  });

  @override
  ScoreCounterState createState() => ScoreCounterState();
}

class ScoreCounterState extends State<ScoreCounter> {
  @override
  Widget build(BuildContext context) {
    final currentCount = widget.scorePanelProvider.getCount(
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
        const SizedBox(height: 6),

        // Unified Counter Widget
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease Button
                IconButton(
                  onPressed: widget.enabled && currentCount > 0
                      ? () => _updateCount(currentCount - 1)
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                ),

                // Count Display
                Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    currentCount.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: widget.enabled
                              ? Theme.of(context).colorScheme.onSurfaceVariant
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
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateCount(int newCount) {
    final oldCount = widget.scorePanelProvider.getCount(
      widget.isHomeTeam,
      widget.isGoal,
    );

    widget.scorePanelProvider.setCount(
      widget.isHomeTeam,
      widget.isGoal,
      newCount,
    );

    final quarter = widget.scorePanelProvider.selectedQuarter;
    final gameSetupProvider =
        Provider.of<GameSetupProvider>(context, listen: false);
    final team = widget.isHomeTeam
        ? gameSetupProvider.homeTeam
        : gameSetupProvider.awayTeam;
    final type = widget.isGoal ? 'goal' : 'behind';

    // Calculate quarter elapsed time regardless of timer mode
    final timerRawTime = widget.scorePanelProvider.timerRawTime;
    final quarterMSec = gameSetupProvider.quarterMSec;

    // Calculate elapsed time based on timer mode
    int elapsedMSec;
    if (gameSetupProvider.isCountdownTimer) {
      // For countdown: full time - remaining time
      elapsedMSec = quarterMSec - timerRawTime;
    } else {
      // For count-up: elapsed time directly
      elapsedMSec = timerRawTime;
    }

    // Cap elapsed time at quarter maximum to handle overtime scoring
    elapsedMSec = elapsedMSec.clamp(0, quarterMSec);

    final quarterElapsedTime = Duration(milliseconds: elapsedMSec);

    final state = context.findAncestorStateOfType<ScoringState>();
    if (newCount < oldCount) {
      // Remove the last matching event for this team/type/quarter
      state?.setState(() {
        final idx = state.gameEvents.lastIndexWhere(
            (e) => e.quarter == quarter && e.team == team && e.type == type);
        if (idx != -1) {
          state.gameEvents.removeAt(idx);
        }
      });
    } else if (newCount > oldCount) {
      // Add a new event
      final event = GameEvent(
        quarter: quarter,
        time: quarterElapsedTime,
        team: team,
        type: type,
      );
      state?.setState(() {
        state.gameEvents.add(event);
      });
    }
  }
}
