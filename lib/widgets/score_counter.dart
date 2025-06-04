import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: widget.enabled
                    ? Theme.of(context).textTheme.titleLarge?.color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
              ),
        ),
        const SizedBox(width: 8),
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: CustomizableCounter(
            borderWidth: 2,
            borderRadius: 36,
            textSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 22,
            count: widget.scorePanelProvider
                .getCount(
                  widget.isHomeTeam,
                  widget.isGoal,
                )
                .toDouble(),
            minCount: 0,
            maxCount: 99,
            showButtonText: false,
            borderColor: widget.enabled
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.38),
            textColor: widget.enabled
                ? Theme.of(context).textTheme.titleLarge?.color
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38),
            onCountChange: widget.enabled
                ? (newCount) {
                    final oldCount = widget.scorePanelProvider.getCount(
                      widget.isHomeTeam,
                      widget.isGoal,
                    );
                    widget.scorePanelProvider.setCount(
                      widget.isHomeTeam,
                      widget.isGoal,
                      newCount.toInt(),
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

                    final quarterElapsedTime =
                        Duration(milliseconds: elapsedMSec);

                    final state =
                        context.findAncestorStateOfType<ScoringState>();
                    if (newCount < oldCount) {
                      // Remove the last matching event for this team/type/quarter
                      state?.setState(() {
                        final idx = state.gameEvents.lastIndexWhere((e) =>
                            e.quarter == quarter &&
                            e.team == team &&
                            e.type == type);
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
                : null,
          ),
        ),
      ],
    );
  }
}
