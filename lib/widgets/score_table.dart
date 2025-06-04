// Score table widget for displaying team scores by quarter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';

class ScoreTable extends StatelessWidget {
  final List<GameEvent> events;
  final String homeTeam;
  final String awayTeam;
  final String displayTeam; // The team whose data this table should display

  const ScoreTable(
      {super.key,
      required this.events,
      required this.homeTeam,
      required this.awayTeam,
      required this.displayTeam});

  Map<String, List<GameEvent>> _eventsByQuarter(int quarter) {
    final teamEvents = events
        .where((e) => e.quarter == quarter && e.team == displayTeam)
        .toList();
    return {'team': teamEvents};
  }

  static const List<String> _quarterLabels = ['1st', '2nd', '3rd', '4th'];

  TableRow createRow(BuildContext context, int quarter) {
    final byQuarter = _eventsByQuarter(quarter + 1);
    final teamGoals = byQuarter['team']!.where((e) => e.type == 'goal').length;
    final teamBehinds =
        byQuarter['team']!.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    return TableRow(
      decoration: BoxDecoration(
        color: (quarter + 1 ==
                Provider.of<ScorePanelProvider>(context, listen: true)
                    .selectedQuarter)
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
      ),
      children: [
        createCell(context, _quarterLabels[quarter]),
        createCell(context, teamGoals.toString()),
        createCell(context, teamBehinds.toString()),
        createCell(context, teamPoints.toString(), isBold: true),
      ],
    );
  }

  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

  Widget createCell(BuildContext context, String text, {bool isBold = false}) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(text, style: isBold ? boldStyle : null),
      ),
    );
  }

  TableRow createSpecialRow(BuildContext context, List<String> values) {
    return TableRow(
      children: [
        createCell(context, values[0], isBold: true),
        createCell(context, values[1], isBold: true),
        createCell(context, values[2], isBold: true),
        createCell(context, values[3], isBold: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder(
          verticalInside:
              BorderSide(width: 1, color: Theme.of(context).dividerColor),
          horizontalInside:
              BorderSide(width: 1, color: Theme.of(context).dividerColor),
          top: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          bottom: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          left: BorderSide(width: 2, color: Theme.of(context).dividerColor),
          right: BorderSide(width: 2, color: Theme.of(context).dividerColor),
        ),
        columnWidths: const {
          0: FlexColumnWidth(0.25),
          1: FlexColumnWidth(0.25),
          2: FlexColumnWidth(0.25),
          3: FlexColumnWidth(0.25),
        },
        children: [
          createSpecialRow(context, [
            'Qtr',
            'Goals',
            'Behinds',
            'Points',
          ]),
          for (int i = 0; i < 4; i++) createRow(context, i),
        ],
      ),
    );
  }
}
