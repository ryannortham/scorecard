import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/widgets/scoring/progressive_display.dart';
import 'package:scorecard/widgets/scoring/tally_display.dart';

/// A single row displaying quarter score data
class ScoreTableRow extends StatelessWidget {
  final int quarter; // 0-based quarter index
  final List<GameEvent> quarterEvents;
  final bool isCurrentQuarter;
  final bool isFutureQuarter;
  final int previousRunningGoals;
  final int previousRunningBehinds;
  final int runningGoals;
  final int runningBehinds;
  final int runningPoints;

  const ScoreTableRow({
    super.key,
    required this.quarter,
    required this.quarterEvents,
    required this.isCurrentQuarter,
    required this.isFutureQuarter,
    required this.previousRunningGoals,
    required this.previousRunningBehinds,
    required this.runningGoals,
    required this.runningBehinds,
    required this.runningPoints,
  });

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<UserPreferencesProvider>(context);
    final useTallyMode = userPreferences.useTallys;

    final teamGoals = quarterEvents.where((e) => e.type == 'goal').length;
    final teamBehinds = quarterEvents.where((e) => e.type == 'behind').length;
    final teamPoints = teamGoals * 6 + teamBehinds;

    // quarter is complete if it's not current and not future
    final isQuarterComplete = !isCurrentQuarter && !isFutureQuarter;

    return Container(
      height: 32.0,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
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
            _buildGoalsColumn(
              context,
              teamGoals,
              useTallyMode,
              isQuarterComplete,
            ),
            _buildBehindsColumn(
              context,
              teamBehinds,
              useTallyMode,
              isQuarterComplete,
            ),
            _buildPointsColumn(context, teamPoints, useTallyMode),
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

  Widget _buildGoalsColumn(
    BuildContext context,
    int teamGoals,
    bool useTallyMode,
    bool isQuarterComplete,
  ) {
    if (useTallyMode) {
      return _buildTallyColumn(
        context,
        teamGoals,
        runningGoals,
        useTally: true,
        rightPadding: 5.0,
      );
    }
    return _buildProgressiveColumn(
      context,
      teamGoals,
      previousRunningGoals,
      isQuarterComplete,
    );
  }

  Widget _buildBehindsColumn(
    BuildContext context,
    int teamBehinds,
    bool useTallyMode,
    bool isQuarterComplete,
  ) {
    if (useTallyMode) {
      return _buildTallyColumn(
        context,
        teamBehinds,
        runningBehinds,
        useTally: true,
        rightPadding: 5.0,
      );
    }
    return _buildProgressiveColumn(
      context,
      teamBehinds,
      previousRunningBehinds,
      isQuarterComplete,
    );
  }

  Widget _buildPointsColumn(
    BuildContext context,
    int teamPoints,
    bool useTallyMode,
  ) {
    // points always use tally column style (number display with running total)
    return _buildTallyColumn(
      context,
      teamPoints,
      runningPoints,
      useTally: false,
      showRunningTotal: useTallyMode,
      rightPadding: 0.0, // less padding to align with other columns
    );
  }

  /// Builds a column with tally/number display and optional running total
  Widget _buildTallyColumn(
    BuildContext context,
    int quarterScore,
    int runningTotal, {
    required bool useTally,
    bool showRunningTotal = true,
    double rightPadding = 4.0,
  }) {
    const runningTotalWidth = 28.0;
    final runningTotalRightPadding = rightPadding;

    return Expanded(
      child: SizedBox(
        height: double.infinity,
        child: Stack(
          children: [
            // content area - tally marks or quarter score text
            Positioned.fill(
              right:
                  showRunningTotal
                      ? runningTotalWidth + runningTotalRightPadding + 4.0
                      : 0,
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
                right: runningTotalRightPadding,
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
                      borderRadius: BorderRadius.circular(4.0),
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

  /// Builds a column with progressive number display (no running total)
  Widget _buildProgressiveColumn(
    BuildContext context,
    int count,
    int startingNumber,
    bool isQuarterComplete,
  ) {
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
}
