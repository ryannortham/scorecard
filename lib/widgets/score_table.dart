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
    try {
      if (events.isEmpty) {
        return {'team': []};
      }
      final teamEvents = events
          .where((e) =>
              e.quarter == quarter &&
              e.team == displayTeam &&
              (e.type == 'goal' || e.type == 'behind'))
          .toList();
      return {'team': teamEvents};
    } catch (e) {
      // Return empty list as fallback if any error occurs
      return {'team': []};
    }
  }

  static const List<String> _quarterLabels = ['1st', '2nd', '3rd', '4th'];

  TableRow createRow(BuildContext context, int quarter) {
    final currentQuarter =
        Provider.of<ScorePanelProvider>(context, listen: true).selectedQuarter;
    final isCurrentQuarter = quarter + 1 == currentQuarter;
    final isFutureQuarter = quarter + 1 > currentQuarter;

    // For future quarters, show blank cells
    if (isFutureQuarter) {
      return TableRow(
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        children: [
          // Quarter label
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Text(_quarterLabels[quarter]),
          ),
          // Goals value - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: const Text(''),
          ),
          // Goals running total - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
            ),
            child: const Text(''),
          ),
          // Behinds value - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: const Text(''),
          ),
          // Behinds running total - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
            ),
            child: const Text(''),
          ),
          // Points value - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: const Text(''),
          ),
          // Points running total - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
            ),
            child: const Text(''),
          ),
        ],
      );
    }

    final byQuarter = _eventsByQuarter(quarter + 1);
    final teamEvents = byQuarter['team'] ?? [];
    final teamGoals = teamEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = teamEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    // Calculate running totals up to this quarter
    int runningGoals = 0;
    int runningBehinds = 0;
    try {
      for (int q = 1; q <= quarter + 1; q++) {
        final qEvents = _eventsByQuarter(q);
        final qTeamEvents = qEvents['team'] ?? [];
        runningGoals += qTeamEvents.where((e) => e.type == 'goal').length;
        runningBehinds += qTeamEvents.where((e) => e.type == 'behind').length;
      }
    } catch (e) {
      // Fallback to just this quarter's values if running total calculation fails
      runningGoals = teamGoals;
      runningBehinds = teamBehinds;
    }
    final runningPoints = runningGoals * 6 + runningBehinds;

    return TableRow(
      decoration: BoxDecoration(
        color: isCurrentQuarter
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
      ),
      children: [
        // Quarter label
        Container(
          height: 24,
          alignment: Alignment.center,
          child: Text(_quarterLabels[quarter]),
        ),
        // Goals value
        Container(
          height: 24,
          alignment: Alignment.center,
          child: Text(teamGoals.toString()),
        ),
        // Goals running total
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withAlpha(180)
                : Colors.grey.withAlpha(20),
          ),
          child: Text(
            runningGoals.toString(),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ),
        // Behinds value
        Container(
          height: 24,
          alignment: Alignment.center,
          child: Text(teamBehinds.toString()),
        ),
        // Behinds running total
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withAlpha(180)
                : Colors.grey.withAlpha(20),
          ),
          child: Text(
            runningBehinds.toString(),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ),
        // Points value
        Container(
          height: 24,
          alignment: Alignment.center,
          child: Text(
            teamPoints.toString(),
            style: boldStyle,
          ),
        ),
        // Points running total
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withAlpha(180)
                : Colors.grey.withAlpha(20),
          ),
          child: Text(
            runningPoints.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ),
      ],
    );
  }

  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

  Widget createCell(BuildContext context, String text,
      {bool isBold = false, bool isSmall = false}) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isSmall ? 10 : null,
            color: isSmall
                ? Theme.of(context).colorScheme.onSurface.withAlpha(179)
                : null,
          ),
        ),
      ),
    );
  }

  // This method is no longer used as we're creating a custom header row
  TableRow createSpecialRow(BuildContext context, List<String> values) {
    return TableRow(
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[0], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[1], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[2], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(values[3], style: boldStyle),
        ),
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text('Tot', style: boldStyle),
        ),
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
          0: FlexColumnWidth(0.10), // Qtr
          1: FlexColumnWidth(0.225), // Goals (75% of 30%)
          2: FlexColumnWidth(0.075), // Goals total (25% of 30%)
          3: FlexColumnWidth(0.225), // Behinds (75% of 30%)
          4: FlexColumnWidth(0.075), // Behinds total (25% of 30%)
          5: FlexColumnWidth(0.225), // Points (75% of 30%)
          6: FlexColumnWidth(0.075), // Points total (25% of 30%)
        },
        children: [
          // Custom header row with simple headers
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(width: 1, color: Theme.of(context).dividerColor),
              ),
            ),
            children: [
              // Quarter header
              Container(
                height: 28,
                alignment: Alignment.center,
                child: Text('Qtr', style: boldStyle),
              ),
              // Goals header
              Container(
                height: 28,
                alignment: Alignment.center,
                child: Text('Goals', style: boldStyle),
              ),
              // Goals total column
              Container(
                height: 28,
                alignment: Alignment.center,
                color: Colors.grey.withAlpha(10),
                child: Text('Tot',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179))),
              ),
              // Behinds header
              Container(
                height: 28,
                alignment: Alignment.center,
                child: Text('Behinds', style: boldStyle),
              ),
              // Behinds total column
              Container(
                height: 28,
                alignment: Alignment.center,
                color: Colors.grey.withAlpha(10),
                child: Text('Tot',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179))),
              ),
              // Points header
              Container(
                height: 28,
                alignment: Alignment.center,
                child: Text('Points', style: boldStyle),
              ),
              // Points total column
              Container(
                height: 28,
                alignment: Alignment.center,
                color: Colors.grey.withAlpha(10),
                child: Text('Tot',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179))),
              ),
            ],
          ),
          for (int i = 0; i < 4; i++) createRow(context, i),
        ],
      ),
    );
  }
}
