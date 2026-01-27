// generates score worm chart data from game events

import 'dart:math';

import 'package:scorecard/models/score_worm.dart';
import 'package:scorecard/providers/game_record_provider.dart';

/// transforms game events into score worm visualisation data
class ScoreWormService {
  /// generates chart data from game events
  static ScoreWormData generateData({
    required List<GameEvent> events,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    double? liveGameProgress,
  }) {
    final quarterDurationMs = quarterMinutes * 60 * 1000;
    final quarterEndTimes = _getQuarterEndTimes(events, quarterDurationMs);

    final scoringEvents =
        events.where((e) => e.type == 'goal' || e.type == 'behind').toList()
          ..sort((a, b) {
            final quarterCompare = a.quarter.compareTo(b.quarter);
            if (quarterCompare != 0) return quarterCompare;
            return a.time.inMilliseconds.compareTo(b.time.inMilliseconds);
          });

    final points = <ScoreWormPoint>[];
    var homePoints = 0;
    var awayPoints = 0;
    var maxAbsDiff = 0;

    points.add(const ScoreWormPoint(x: 0, differential: 0));

    for (final event in scoringEvents) {
      final quarterEndMs = quarterEndTimes[event.quarter] ?? quarterDurationMs;
      final eventTimeMs = event.time.inMilliseconds;

      // clamp to quarter boundary for overtime
      final quarterProgress = min(eventTimeMs / quarterEndMs, 1);
      final x = (event.quarter - 1).toDouble() + quarterProgress;

      final oldDiff = homePoints - awayPoints;

      final pointsScored = event.type == 'goal' ? 6 : 1;
      if (event.team == homeTeam) {
        homePoints += pointsScored;
      } else if (event.team == awayTeam) {
        awayPoints += pointsScored;
      }

      final newDiff = homePoints - awayPoints;
      maxAbsDiff = max(maxAbsDiff, newDiff.abs());

      // stepped line: horizontal segment at old diff, then new diff at same x
      if (points.isNotEmpty && points.last.x < x) {
        points.add(ScoreWormPoint(x: x, differential: oldDiff));
      }
      points.add(ScoreWormPoint(x: x, differential: newDiff));
    }

    // extend to current progress for live games
    final progress = liveGameProgress ?? _calculateProgress(events);
    if (points.isNotEmpty && points.last.x < progress) {
      points.add(
        ScoreWormPoint(x: progress, differential: homePoints - awayPoints),
      );
    }

    // calculate quarter scores as running totals
    final homeQuarterScores = <int, QuarterScore>{};
    final awayQuarterScores = <int, QuarterScore>{};

    for (var q = 1; q <= 4; q++) {
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

  /// calculates "nice" y-axis max for clean tick intervals (20, 50, 100...)
  static int calculateNiceYAxisMax(int maxAbsDiff) {
    if (maxAbsDiff <= 20) return 20;

    final magnitude = (log(maxAbsDiff) / ln10).floor();
    final power = pow(10, magnitude).toInt();
    final normalised = maxAbsDiff / power;

    // round up to next nice number (1, 2, 5, 10)
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
    return result < 20 ? 20 : result;
  }

  /// generates 5 tick values: [max, max/2, 0, -max/2, -max]
  static List<int> generateTickValues(int yAxisMax) {
    final half = yAxisMax ~/ 2;
    return [yAxisMax, half, 0, -half, -yAxisMax];
  }

  /// quarter end times from clock_end events, defaults to quarterDurationMs
  static Map<int, int> _getQuarterEndTimes(
    List<GameEvent> events,
    int quarterDurationMs,
  ) {
    final endTimes = <int, int>{};

    for (final event in events) {
      if (event.type == 'clock_end') {
        endTimes[event.quarter] = max(
          event.time.inMilliseconds,
          quarterDurationMs,
        );
      }
    }

    for (var q = 1; q <= 4; q++) {
      endTimes.putIfAbsent(q, () => quarterDurationMs);
    }

    return endTimes;
  }

  /// current game progress (0.0 - 4.0) based on events
  static double _calculateProgress(List<GameEvent> events) {
    if (events.isEmpty) return 0;

    // Find highest quarter with events
    var maxQuarter = 1;
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

    // quarter in progress - live games override with actual progress
    return (maxQuarter - 1).toDouble();
  }

  /// running totals for both teams up to a specific quarter
  static Map<String, QuarterScore> _calculateRunningTotals(
    List<GameEvent> events,
    String homeTeam,
    String awayTeam,
    int upToQuarter,
  ) {
    var homeGoals = 0;
    var homeBehinds = 0;
    var awayGoals = 0;
    var awayBehinds = 0;

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
