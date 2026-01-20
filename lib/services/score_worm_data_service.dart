import 'dart:math';

import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/color_service.dart';

/// A single point on the score worm chart
class ScoreWormPoint {
  /// normalised game position (0.0 - 4.0)
  final double x;

  /// home points minus away points (positive = home leading)
  final int differential;

  const ScoreWormPoint({required this.x, required this.differential});
}

/// Quarter score summary (running total)
class QuarterScore {
  final int goals;
  final int behinds;

  const QuarterScore({required this.goals, required this.behinds});

  int get points => goals * 6 + behinds;
  String get display => '$goals.$behinds';

  static const zero = QuarterScore(goals: 0, behinds: 0);
}

/// Colours for the worm line
class ScoreWormColours {
  final Color homeLeadingColour;
  final Color awayLeadingColour;

  /// for y = 0 (tied scores)
  final Color neutralColour;

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
}

/// Complete data for rendering the score worm
class ScoreWormData {
  final List<ScoreWormPoint> points;

  /// quarter (1-4) to running total
  final Map<int, QuarterScore> homeQuarterScores;
  final Map<int, QuarterScore> awayQuarterScores;

  /// calculated via nice numbers algorithm
  final int yAxisMax;

  const ScoreWormData({
    required this.points,
    required this.homeQuarterScores,
    required this.awayQuarterScores,
    required this.yAxisMax,
  });
}

/// Service for generating score worm chart data from game events
class ScoreWormDataService {
  /// generate chart data from game events
  static ScoreWormData generateData({
    required List<GameEvent> events,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    double? liveGameProgress, // For live games: current position 0.0-4.0
  }) {
    final quarterDurationMs = quarterMinutes * 60 * 1000;

    // Get actual quarter end times from clock_end events
    final quarterEndTimes = _getQuarterEndTimes(events, quarterDurationMs);

    // Filter and sort scoring events
    final scoringEvents =
        events.where((e) => e.type == 'goal' || e.type == 'behind').toList()
          ..sort((a, b) {
            final quarterCompare = a.quarter.compareTo(b.quarter);
            if (quarterCompare != 0) return quarterCompare;
            return a.time.inMilliseconds.compareTo(b.time.inMilliseconds);
          });

    // Build points list for stepped line
    final points = <ScoreWormPoint>[];
    int homePoints = 0;
    int awayPoints = 0;
    int maxAbsDiff = 0;

    // Start at origin
    points.add(const ScoreWormPoint(x: 0, differential: 0));

    for (final event in scoringEvents) {
      final quarterEndMs = quarterEndTimes[event.quarter] ?? quarterDurationMs;
      final eventTimeMs = event.time.inMilliseconds;

      // Calculate X position, clamping to quarter boundary for overtime
      final quarterProgress = min(eventTimeMs / quarterEndMs, 1.0);
      final x = (event.quarter - 1) + quarterProgress;

      final oldDiff = homePoints - awayPoints;

      // Update score
      final pointsScored = event.type == 'goal' ? 6 : 1;
      if (event.team == homeTeam) {
        homePoints += pointsScored;
      } else if (event.team == awayTeam) {
        awayPoints += pointsScored;
      }

      final newDiff = homePoints - awayPoints;
      maxAbsDiff = max(maxAbsDiff, newDiff.abs());

      // Stepped line: horizontal segment at old diff, then new diff at same X
      // Only add horizontal if we've moved along X
      if (points.isNotEmpty && points.last.x < x) {
        points.add(ScoreWormPoint(x: x, differential: oldDiff));
      }
      points.add(ScoreWormPoint(x: x, differential: newDiff));
    }

    // For live games, extend to current progress
    final progress = liveGameProgress ?? _calculateProgress(events);
    if (points.isNotEmpty && points.last.x < progress) {
      points.add(
        ScoreWormPoint(x: progress, differential: homePoints - awayPoints),
      );
    }

    // Calculate quarter scores (running totals)
    final homeQuarterScores = <int, QuarterScore>{};
    final awayQuarterScores = <int, QuarterScore>{};

    for (int q = 1; q <= 4; q++) {
      final totals = _calculateRunningTotals(events, homeTeam, awayTeam, q);
      homeQuarterScores[q] = totals['home']!;
      awayQuarterScores[q] = totals['away']!;
    }

    return ScoreWormData(
      points: points,
      homeQuarterScores: homeQuarterScores,
      awayQuarterScores: awayQuarterScores,
      yAxisMax: calculateNiceYAxisMax(maxAbsDiff),
    );
  }

  /// calculates a "nice" y-axis maximum for clean tick intervals (20, 50, 100, etc.)
  static int calculateNiceYAxisMax(int maxAbsDiff) {
    if (maxAbsDiff <= 20) return 20;

    // Find the order of magnitude
    final magnitude = (log(maxAbsDiff) / ln10).floor();
    final power = pow(10, magnitude).toInt();

    // Normalise to 1-10 range
    final normalised = maxAbsDiff / power;

    // Round up to next "nice" number (1, 2, 5, 10)
    int niceMultiplier;
    if (normalised <= 1) {
      niceMultiplier = 1;
    } else if (normalised <= 2) {
      niceMultiplier = 2;
    } else if (normalised <= 5) {
      niceMultiplier = 5;
    } else {
      niceMultiplier = 10;
    }

    final result = niceMultiplier * power;
    return result < 20 ? 20 : result; // Minimum 20
  }

  /// generates 5 tick values for the y-axis: [max, max/2, 0, -max/2, -max]
  static List<int> generateTickValues(int yAxisMax) {
    final half = yAxisMax ~/ 2;
    return [yAxisMax, half, 0, -half, -yAxisMax];
  }

  /// get quarter end times from clock_end events, fallback to quarterDurationMs
  static Map<int, int> _getQuarterEndTimes(
    List<GameEvent> events,
    int quarterDurationMs,
  ) {
    final endTimes = <int, int>{};

    for (final event in events) {
      if (event.type == 'clock_end') {
        // Use actual end time, but don't exceed quarter duration for normalisation
        endTimes[event.quarter] = max(
          event.time.inMilliseconds,
          quarterDurationMs,
        );
      }
    }

    // Fill in defaults for quarters without clock_end events
    for (int q = 1; q <= 4; q++) {
      endTimes.putIfAbsent(q, () => quarterDurationMs);
    }

    return endTimes;
  }

  /// calculate current game progress (0.0 - 4.0) based on events
  static double _calculateProgress(List<GameEvent> events) {
    if (events.isEmpty) return 0.0;

    // Find highest quarter with events
    int maxQuarter = 1;
    for (final event in events) {
      if (event.quarter > maxQuarter) {
        maxQuarter = event.quarter;
      }
    }

    // Check if that quarter has ended
    final hasEnded = events.any(
      (e) => e.quarter == maxQuarter && e.type == 'clock_end',
    );

    if (hasEnded) {
      return maxQuarter.toDouble();
    }

    // Quarter in progress - return quarter start
    // (Live games will override this with actual progress)
    return (maxQuarter - 1).toDouble();
  }

  /// calculate running totals for both teams up to a specific quarter
  static Map<String, QuarterScore> _calculateRunningTotals(
    List<GameEvent> events,
    String homeTeam,
    String awayTeam,
    int upToQuarter,
  ) {
    int homeGoals = 0;
    int homeBehinds = 0;
    int awayGoals = 0;
    int awayBehinds = 0;

    for (final event in events) {
      if (event.quarter > upToQuarter) continue;
      if (event.type != 'goal' && event.type != 'behind') continue;

      if (event.team == homeTeam) {
        if (event.type == 'goal') {
          homeGoals++;
        } else {
          homeBehinds++;
        }
      } else if (event.team == awayTeam) {
        if (event.type == 'goal') {
          awayGoals++;
        } else {
          awayBehinds++;
        }
      }
    }

    return {
      'home': QuarterScore(goals: homeGoals, behinds: homeBehinds),
      'away': QuarterScore(goals: awayGoals, behinds: awayBehinds),
    };
  }
}
