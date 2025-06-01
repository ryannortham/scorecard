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
                    : Theme.of(context).colorScheme.outline,
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
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
            textColor: widget.enabled
                ? Theme.of(context).textTheme.titleLarge?.color
                : Theme.of(context).colorScheme.outline,
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
                    final now = DateTime.now();
                    final quarter = widget.scorePanelProvider.selectedQuarter;
                    final team = widget.isHomeTeam
                        ? (Provider.of<GameSetupProvider>(context,
                                listen: false)
                            .homeTeam)
                        : (Provider.of<GameSetupProvider>(context,
                                listen: false)
                            .awayTeam);
                    final type = widget.isGoal ? 'goal' : 'behind';
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
                        time: Duration(
                          hours: now.hour,
                          minutes: now.minute,
                          seconds: now.second,
                        ),
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
