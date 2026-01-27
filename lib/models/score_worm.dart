// score worm chart data models

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';

/// single point on the score worm chart
class ScoreWormPoint {
  const ScoreWormPoint({required this.x, required this.differential});

  /// normalised game position (0.0 - 4.0)
  final double x;

  /// home points minus away points (positive = home leading)
  final int differential;
}

/// quarter score summary as running total
class QuarterScore {
  const QuarterScore({required this.goals, required this.behinds});
  final int goals;
  final int behinds;

  int get points => goals * 6 + behinds;
  String get display => '$goals.$behinds';

  static const zero = QuarterScore(goals: 0, behinds: 0);
}

/// worm line colours based on score differential
class ScoreWormColours {
  const ScoreWormColours({
    required this.homeLeadingColour,
    required this.awayLeadingColour,
    required this.neutralColour,
  });

  factory ScoreWormColours.fromTheme(AppColors colors) => ScoreWormColours(
    homeLeadingColour: colors.primary,
    awayLeadingColour: colors.tertiary,
    neutralColour: colors.onSurface,
  );
  final Color homeLeadingColour;
  final Color awayLeadingColour;
  final Color neutralColour; // for y = 0 (tied scores)
}

/// complete data for rendering the score worm
class ScoreWormData {
  const ScoreWormData({
    required this.points,
    required this.homeQuarterScores,
    required this.awayQuarterScores,
    required this.yAxisMax,
  });
  final List<ScoreWormPoint> points;
  final Map<int, QuarterScore>
  homeQuarterScores; // quarter (1-4) to running total
  final Map<int, QuarterScore> awayQuarterScores;
  final int yAxisMax; // calculated via nice numbers algorithm
}
