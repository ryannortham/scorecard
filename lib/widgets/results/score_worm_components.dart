// score worm component widgets for team logos, axis labels, and chart area

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/score_worm.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/results/score_worm_painters.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

/// team logo widget for score worm
class ScoreWormTeamLogo extends StatelessWidget {
  const ScoreWormTeamLogo({required this.teamName, super.key});
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsViewModel>(
      builder: (context, teamsProvider, child) {
        final team = teamsProvider.findTeamByName(teamName);
        final logoUrl = team?.logoUrl32 ?? team?.logoUrl48 ?? team?.logoUrl;
        return TeamLogo(logoUrl: logoUrl);
      },
    );
  }
}

/// y-axis labels positioned at gridline heights
class ScoreWormYAxisLabels extends StatelessWidget {
  const ScoreWormYAxisLabels({required this.tickValues, super.key});
  final List<int> tickValues;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontSize: 10,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final positions = [0.0, 0.25, 0.5, 0.75, 1.0];

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(tickValues.length, (index) {
            final y = positions[index] * height;
            return Positioned(
              top: y - 6,
              left: 8,
              child: Text(tickValues[index].abs().toString(), style: textStyle),
            );
          }),
        );
      },
    );
  }
}

/// chart area with grid and worm line overlay
class ScoreWormChartArea extends StatelessWidget {
  const ScoreWormChartArea({
    required this.data,
    required this.colours,
    super.key,
  });
  final ScoreWormData data;
  final ScoreWormColours colours;

  @override
  Widget build(BuildContext context) {
    final gridColour = context.colors.outline.withValues(alpha: 0.2);
    final zeroLineColour = context.colors.outline.withValues(alpha: 0.5);
    final watermarkStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: context.colors.outline.withValues(alpha: 0.15),
      fontWeight: FontWeight.bold,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: GridPainter(
            gridColour: gridColour,
            zeroLineColour: zeroLineColour,
          ),
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Center(
                  child: Text('Q${index + 1}', style: watermarkStyle),
                ),
              );
            }),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: WormLinePainter(
              points: data.points,
              yAxisMax: data.yAxisMax,
              colours: colours,
            ),
          ),
        ),
      ],
    );
  }
}
