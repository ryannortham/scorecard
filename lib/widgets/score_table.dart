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
          // Goals column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
          ),
          // Behinds column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
          ),
          // Points column - blank
          Container(
            height: 24,
            alignment: Alignment.center,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Center(child: Text('')),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                    ),
                    child: const Center(child: Text('')),
                  ),
                ),
              ],
            ),
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
        // Goals column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(teamGoals.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withAlpha(180)
                        : Colors.grey.withAlpha(20),
                  ),
                  child: Center(
                    child: Text(
                      runningGoals.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Behinds column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(teamBehinds.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withAlpha(180)
                        : Colors.grey.withAlpha(20),
                  ),
                  child: Center(
                    child: Text(
                      runningBehinds.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Points column (value and total combined)
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentQuarter
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    teamPoints.toString(),
                    style: boldStyle,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentQuarter
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withAlpha(180)
                        : Colors.grey.withAlpha(20),
                  ),
                  child: Center(
                    child: Text(
                      runningPoints.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          1: FlexColumnWidth(0.30), // Goals (main + total)
          2: FlexColumnWidth(0.30), // Behinds (main + total)
          3: FlexColumnWidth(0.30), // Score (main + total)
        },
        children: [
          // Custom header row with spanning headers
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
              // Goals header spanning both columns
              Container(
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        width: 1, color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Text('Goals', style: boldStyle),
              ),
              // Behinds header spanning both columns
              Container(
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        width: 1, color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Text('Behinds', style: boldStyle),
              ),
              // Points header spanning both columns
              Container(
                height: 28,
                alignment: Alignment.center,
                child: Text('Score', style: boldStyle),
              ),
            ],
          ),
          for (int i = 0; i < 4; i++) createRow(context, i),
        ],
      ),
    );
  }
}
