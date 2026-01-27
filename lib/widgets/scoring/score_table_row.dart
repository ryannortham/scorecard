// single row displaying quarter score data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/widgets/scoring/progressive_display.dart';
import 'package:scorecard/widgets/scoring/progressive_number.dart';
import 'package:scorecard/widgets/scoring/tally_display.dart';

/// types of score columns in the table
enum ScoreColumnType { goals, behinds, points }

/// single row displaying quarter score data
class ScoreTableRow extends StatelessWidget {
  const ScoreTableRow({
    required this.quarter,
    required this.quarterEvents,
    required this.isCurrentQuarter,
    required this.isFutureQuarter,
    required this.previousRunningGoals,
    required this.previousRunningBehinds,
    required this.runningGoals,
    required this.runningBehinds,
    required this.runningPoints,
    super.key,
  });
  final int quarter; // 0-based quarter index
  final List<GameEvent> quarterEvents;
  final bool isCurrentQuarter;
  final bool isFutureQuarter;
  final int previousRunningGoals;
  final int previousRunningBehinds;
  final int runningGoals;
  final int runningBehinds;
  final int runningPoints;

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<PreferencesViewModel>(context);
    final useTallyMode = userPreferences.useTallys;

    final teamGoals = quarterEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = quarterEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    // quarter is complete if it's not current and not future
    final isQuarterComplete = !isCurrentQuarter && !isFutureQuarter;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color:
            isCurrentQuarter
                ? context.colors.secondaryContainer
                : context.colors.surfaceContainerHigh,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildQuarterColumn(context),
            _buildScoreColumn(
              context,
              type: ScoreColumnType.goals,
              quarterValue: teamGoals,
              runningTotal: runningGoals,
              previousRunning: previousRunningGoals,
              useTallyMode: useTallyMode,
              isQuarterComplete: isQuarterComplete,
            ),
            _buildScoreColumn(
              context,
              type: ScoreColumnType.behinds,
              quarterValue: teamBehinds,
              runningTotal: runningBehinds,
              previousRunning: previousRunningBehinds,
              useTallyMode: useTallyMode,
              isQuarterComplete: isQuarterComplete,
            ),
            _buildScoreColumn(
              context,
              type: ScoreColumnType.points,
              quarterValue: teamPoints,
              runningTotal: runningPoints,
              previousRunning: 0, // not used for points
              useTallyMode: useTallyMode,
              isQuarterComplete: isQuarterComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterColumn(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Align(
        alignment: const Alignment(-0.3, 0),
        child: Text(
          'Q${quarter + 1}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  /// unified builder for goals, behinds, and points columns
  Widget _buildScoreColumn(
    BuildContext context, {
    required ScoreColumnType type,
    required int quarterValue,
    required int runningTotal,
    required int previousRunning,
    required bool useTallyMode,
    required bool isQuarterComplete,
  }) {
    if (useTallyMode) {
      return _buildTallyColumn(
        context,
        quarterScore: quarterValue,
        runningTotal: runningTotal,
        useTally: type != ScoreColumnType.points,
        showRunningTotal: type == ScoreColumnType.points,
        rightPadding: type == ScoreColumnType.points ? 0.0 : 5.0,
      );
    }

    // Progressive/numbers mode
    if (type == ScoreColumnType.points) {
      return _buildProgressiveValueColumn(
        context,
        value: runningTotal,
        isQuarterComplete: isQuarterComplete,
      );
    }

    return _buildProgressiveSequenceColumn(
      context,
      count: quarterValue,
      startingNumber: previousRunning,
      isQuarterComplete: isQuarterComplete,
    );
  }

  /// builds a column with tally/number display and optional running total box
  Widget _buildTallyColumn(
    BuildContext context, {
    required int quarterScore,
    required int runningTotal,
    required bool useTally,
    bool showRunningTotal = true,
    double rightPadding = 4.0,
  }) {
    const runningTotalWidth = 28.0;

    return Expanded(
      child: SizedBox(
        height: double.infinity,
        child: Stack(
          children: [
            // content area - tally marks or quarter score text
            Positioned.fill(
              right:
                  showRunningTotal ? runningTotalWidth + rightPadding + 4.0 : 0,
              child:
                  isFutureQuarter
                      ? const SizedBox.shrink()
                      : TallyDisplay(
                        value: quarterScore,
                        textStyle: Theme.of(context).textTheme.labelMedium,
                        useTally: useTally,
                      ),
            ),
            // running total box - fixed position from right edge
            if (showRunningTotal)
              Positioned(
                right: rightPadding,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: runningTotalWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isFutureQuarter
                              ? ColorService.transparent
                              : context.colors.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        isFutureQuarter ? '' : runningTotal.toString(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// builds a column with progressive number sequence (for goals/behinds)
  Widget _buildProgressiveSequenceColumn(
    BuildContext context, {
    required int count,
    required int startingNumber,
    required bool isQuarterComplete,
  }) {
    return Expanded(
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child:
              isFutureQuarter
                  ? const SizedBox.shrink()
                  : ProgressiveDisplay(
                    count: count,
                    startingNumber: startingNumber,
                    isQuarterComplete: isQuarterComplete,
                    textStyle: Theme.of(context).textTheme.labelMedium,
                  ),
        ),
      ),
    );
  }

  /// builds a column showing a single value with optional underline (for
  /// points)
  Widget _buildProgressiveValueColumn(
    BuildContext context, {
    required int value,
    required bool isQuarterComplete,
  }) {
    return Expanded(
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child:
              isFutureQuarter
                  ? const SizedBox.shrink()
                  : ProgressiveNumber(
                    number: value,
                    decoration:
                        isQuarterComplete
                            ? NumberDecoration.underline
                            : NumberDecoration.none,
                    textStyle: Theme.of(context).textTheme.labelMedium,
                  ),
        ),
      ),
    );
  }
}
