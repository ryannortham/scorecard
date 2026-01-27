// tests for score worm service - chart data generation

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/services/score_worm_service.dart';

void main() {
  const homeTeam = 'Richmond';
  const awayTeam = 'Carlton';
  const quarterMinutes = 20;

  /// helper to create a game event
  GameEvent createEvent({
    required int quarter,
    required int timeMs,
    required String team,
    required String type,
  }) {
    return GameEvent(
      quarter: quarter,
      time: Duration(milliseconds: timeMs),
      team: team,
      type: type,
    );
  }

  group('ScoreWormService.generateData', () {
    group('empty events', () {
      test('should return single point at origin for empty events', () {
        final data = ScoreWormService.generateData(
          events: [],
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.length, equals(1));
        expect(data.points.first.x, equals(0.0));
        expect(data.points.first.differential, equals(0));
      });

      test('should return default yAxisMax of 20 for empty events', () {
        final data = ScoreWormService.generateData(
          events: [],
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.yAxisMax, equals(20));
      });

      test('should return zero quarter scores for empty events', () {
        final data = ScoreWormService.generateData(
          events: [],
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        for (var q = 1; q <= 4; q++) {
          expect(data.homeQuarterScores[q]!.goals, equals(0));
          expect(data.homeQuarterScores[q]!.behinds, equals(0));
          expect(data.awayQuarterScores[q]!.goals, equals(0));
          expect(data.awayQuarterScores[q]!.behinds, equals(0));
        }
      });
    });

    group('single scoring events', () {
      test('should produce +6 differential for single home goal', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        // Should have origin + stepped line (horizontal + vertical)
        expect(data.points.length, greaterThanOrEqualTo(2));
        expect(data.points.last.differential, equals(6));
      });

      test('should produce -6 differential for single away goal', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: awayTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.last.differential, equals(-6));
      });

      test('should produce +1 differential for single home behind', () {
        final events = [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: homeTeam,
            type: 'behind',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.last.differential, equals(1));
      });

      test('should produce -1 differential for single away behind', () {
        final events = [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: awayTeam,
            type: 'behind',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.last.differential, equals(-1));
      });
    });

    group('multiple scoring events', () {
      test('should accumulate differentials correctly', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(quarter: 1, timeMs: 120000, team: awayTeam, type: 'goal'),
          createEvent(
            quarter: 1,
            timeMs: 180000,
            team: homeTeam,
            type: 'behind',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        // Home: 6 + 1 = 7, Away: 6, Diff: +1
        expect(data.points.last.differential, equals(1));
      });

      test('should handle tied game (differential = 0)', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(quarter: 1, timeMs: 120000, team: awayTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.last.differential, equals(0));
      });
    });

    group('quarter positioning', () {
      test('should position Q1 events between 0.0 and 1.0', () {
        final events = [
          createEvent(
            quarter: 1,
            timeMs: 600000, // 10 minutes = halfway through 20 min quarter
            team: homeTeam,
            type: 'goal',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        final scoringPoints = data.points.where((p) => p.differential != 0);
        for (final point in scoringPoints) {
          expect(point.x, greaterThanOrEqualTo(0.0));
          expect(point.x, lessThanOrEqualTo(1.0));
        }
      });

      test('should position Q2 events between 1.0 and 2.0', () {
        final events = [
          createEvent(quarter: 2, timeMs: 600000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        final scoringPoints = data.points.where((p) => p.differential != 0);
        for (final point in scoringPoints) {
          expect(point.x, greaterThanOrEqualTo(1.0));
          expect(point.x, lessThanOrEqualTo(2.0));
        }
      });

      test('should position Q3 events between 2.0 and 3.0', () {
        final events = [
          createEvent(quarter: 3, timeMs: 600000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        final scoringPoints = data.points.where((p) => p.differential != 0);
        for (final point in scoringPoints) {
          expect(point.x, greaterThanOrEqualTo(2.0));
          expect(point.x, lessThanOrEqualTo(3.0));
        }
      });

      test('should position Q4 events between 3.0 and 4.0', () {
        final events = [
          createEvent(quarter: 4, timeMs: 600000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        final scoringPoints = data.points.where((p) => p.differential != 0);
        for (final point in scoringPoints) {
          expect(point.x, greaterThanOrEqualTo(3.0));
          expect(point.x, lessThanOrEqualTo(4.0));
        }
      });
    });

    group('quarter scores (running totals)', () {
      test('should calculate Q1 totals correctly', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: homeTeam,
            type: 'behind',
          ),
          createEvent(quarter: 1, timeMs: 180000, team: awayTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.homeQuarterScores[1]!.goals, equals(1));
        expect(data.homeQuarterScores[1]!.behinds, equals(1));
        expect(data.awayQuarterScores[1]!.goals, equals(1));
        expect(data.awayQuarterScores[1]!.behinds, equals(0));
      });

      test('should accumulate totals across quarters', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(quarter: 2, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(
            quarter: 3,
            timeMs: 60000,
            team: homeTeam,
            type: 'behind',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        // Q1: 1 goal
        expect(data.homeQuarterScores[1]!.goals, equals(1));

        // Q2: 1 + 1 = 2 goals (running total)
        expect(data.homeQuarterScores[2]!.goals, equals(2));

        // Q3: 2 goals + 1 behind
        expect(data.homeQuarterScores[3]!.goals, equals(2));
        expect(data.homeQuarterScores[3]!.behinds, equals(1));
      });
    });

    group('ignores non-scoring events', () {
      test('should ignore clock_start events', () {
        final events = [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.points.last.differential, equals(6));
        expect(data.homeQuarterScores[1]!.goals, equals(1));
      });

      test('should ignore clock_pause events', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: '',
            type: 'clock_pause',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.homeQuarterScores[1]!.goals, equals(1));
      });

      test('should ignore clock_end events for scoring', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        expect(data.homeQuarterScores[1]!.goals, equals(1));
      });
    });

    group('unknown team handling', () {
      test('should ignore events from unknown teams', () {
        final events = [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Unknown Team',
            type: 'goal',
          ),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        // Differential should remain 0 as team is unknown
        expect(data.points.last.differential, equals(0));
      });
    });

    group('live game progress', () {
      test('should extend line to liveGameProgress when provided', () {
        final events = [
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
          liveGameProgress: 2.5, // Halfway through Q3
        );

        expect(data.points.last.x, equals(2.5));
      });
    });

    group('event sorting', () {
      test('should sort events by quarter then time', () {
        // Add events out of order
        final events = [
          createEvent(quarter: 2, timeMs: 60000, team: homeTeam, type: 'goal'),
          createEvent(quarter: 1, timeMs: 120000, team: awayTeam, type: 'goal'),
          createEvent(quarter: 1, timeMs: 60000, team: homeTeam, type: 'goal'),
        ];

        final data = ScoreWormService.generateData(
          events: events,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          quarterMinutes: quarterMinutes,
        );

        // Should process in order: Q1@60s (home+6), Q1@120s (away-6), Q2@60s (home+6)
        // Final: Home 12, Away 6, Diff = +6
        expect(data.points.last.differential, equals(6));
      });
    });
  });

  group('ScoreWormService.calculateNiceYAxisMax', () {
    test('should return 20 for maxAbsDiff <= 20', () {
      expect(ScoreWormService.calculateNiceYAxisMax(0), equals(20));
      expect(ScoreWormService.calculateNiceYAxisMax(10), equals(20));
      expect(ScoreWormService.calculateNiceYAxisMax(20), equals(20));
    });

    test('should return 50 for maxAbsDiff in range 21-50', () {
      expect(ScoreWormService.calculateNiceYAxisMax(21), equals(50));
      expect(ScoreWormService.calculateNiceYAxisMax(35), equals(50));
      expect(ScoreWormService.calculateNiceYAxisMax(50), equals(50));
    });

    test('should return 100 for maxAbsDiff in range 51-100', () {
      expect(ScoreWormService.calculateNiceYAxisMax(51), equals(100));
      expect(ScoreWormService.calculateNiceYAxisMax(75), equals(100));
      expect(ScoreWormService.calculateNiceYAxisMax(100), equals(100));
    });

    test('should scale to next nice number for large values', () {
      expect(ScoreWormService.calculateNiceYAxisMax(101), equals(200));
      expect(ScoreWormService.calculateNiceYAxisMax(150), equals(200));
      expect(ScoreWormService.calculateNiceYAxisMax(201), equals(500));
    });
  });

  group('ScoreWormService.generateTickValues', () {
    test('should generate 5 symmetric tick values', () {
      final ticks = ScoreWormService.generateTickValues(20);

      expect(ticks.length, equals(5));
      expect(ticks, equals([20, 10, 0, -10, -20]));
    });

    test('should generate correct ticks for yAxisMax 50', () {
      final ticks = ScoreWormService.generateTickValues(50);

      expect(ticks, equals([50, 25, 0, -25, -50]));
    });

    test('should generate correct ticks for yAxisMax 100', () {
      final ticks = ScoreWormService.generateTickValues(100);

      expect(ticks, equals([100, 50, 0, -50, -100]));
    });
  });
}
