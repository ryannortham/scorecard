// Tests for score worm data service

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/score_worm_data_service.dart';

void main() {
  group('ScoreWormDataService', () {
    group('calculateNiceYAxisMax', () {
      test('should return 20 for values 20 or less', () {
        expect(ScoreWormDataService.calculateNiceYAxisMax(0), equals(20));
        expect(ScoreWormDataService.calculateNiceYAxisMax(10), equals(20));
        expect(ScoreWormDataService.calculateNiceYAxisMax(15), equals(20));
        expect(ScoreWormDataService.calculateNiceYAxisMax(20), equals(20));
      });

      test('should round up to nice numbers for values above 20', () {
        expect(ScoreWormDataService.calculateNiceYAxisMax(21), equals(50));
        expect(ScoreWormDataService.calculateNiceYAxisMax(25), equals(50));
        expect(ScoreWormDataService.calculateNiceYAxisMax(45), equals(50));
        expect(ScoreWormDataService.calculateNiceYAxisMax(50), equals(50));
      });

      test('should handle larger values', () {
        expect(ScoreWormDataService.calculateNiceYAxisMax(51), equals(100));
        expect(ScoreWormDataService.calculateNiceYAxisMax(75), equals(100));
        expect(ScoreWormDataService.calculateNiceYAxisMax(100), equals(100));
      });

      test('should handle AFL-typical differentials', () {
        // Typical AFL blowout might be 100+ points
        expect(ScoreWormDataService.calculateNiceYAxisMax(120), equals(200));
        expect(ScoreWormDataService.calculateNiceYAxisMax(150), equals(200));
      });
    });

    group('generateTickValues', () {
      test('should generate symmetric tick values', () {
        final ticks = ScoreWormDataService.generateTickValues(20);

        expect(ticks, equals([20, 10, 0, -10, -20]));
      });

      test('should handle larger y-axis max', () {
        final ticks = ScoreWormDataService.generateTickValues(100);

        expect(ticks, equals([100, 50, 0, -50, -100]));
      });

      test('should handle odd numbers (integer division)', () {
        final ticks = ScoreWormDataService.generateTickValues(50);

        expect(ticks, equals([50, 25, 0, -25, -50]));
      });
    });

    group('generateData', () {
      test('should handle empty events', () {
        final data = ScoreWormDataService.generateData(
          events: [],
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        expect(data.points.length, equals(1));
        expect(data.points.first.x, equals(0));
        expect(data.points.first.differential, equals(0));
        expect(data.yAxisMax, equals(20));
      });

      test('should generate points for home team goals', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 10),
            team: 'Home FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Should have origin + 2 goals worth of points
        expect(data.points.length, greaterThan(1));
        // After two home goals, differential should be +12
        expect(data.points.last.differential, equals(12));
      });

      test('should generate points for away team goals', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Away FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // After one away goal, differential should be -6
        expect(data.points.last.differential, equals(-6));
      });

      test('should handle mixed scoring', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 10),
            team: 'Away FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 15),
            team: 'Home FC',
            type: 'behind',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Home: 6 + 1 = 7, Away: 6, diff = +1
        expect(data.points.last.differential, equals(1));
      });

      test('should calculate quarter scores correctly', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 10),
            team: 'Home FC',
            type: 'behind',
          ),
          GameEvent(
            quarter: 2,
            time: const Duration(minutes: 5),
            team: 'Away FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Q1: Home 1.1, Away 0.0
        expect(data.homeQuarterScores[1]!.goals, equals(1));
        expect(data.homeQuarterScores[1]!.behinds, equals(1));
        expect(data.awayQuarterScores[1]!.goals, equals(0));

        // Q2 running total: Home 1.1, Away 1.0
        expect(data.homeQuarterScores[2]!.goals, equals(1));
        expect(data.awayQuarterScores[2]!.goals, equals(1));
      });

      test('should calculate x position based on quarter and time', () {
        final events = [
          GameEvent(
            quarter: 2,
            time: const Duration(minutes: 10),
            team: 'Home FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Quarter 2, 10 minutes in (halfway through quarter)
        // x = (2-1) + (10/20) = 1.5
        final scoringPoint = data.points.firstWhere((p) => p.differential != 0);
        expect(scoringPoint.x, closeTo(1.5, 0.01));
      });

      test('should sort events by quarter then time', () {
        // Events deliberately out of order
        final events = [
          GameEvent(
            quarter: 2,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 15),
            team: 'Away FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Verify x positions are in ascending order
        for (int i = 1; i < data.points.length; i++) {
          expect(data.points[i].x, greaterThanOrEqualTo(data.points[i - 1].x));
        }
      });

      test('should handle behinds correctly', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'behind',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 10),
            team: 'Away FC',
            type: 'behind',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Home: 1, Away: 1, diff = 0
        expect(data.points.last.differential, equals(0));
      });

      test('should extend line for live games', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
          liveGameProgress: 2.5, // Halfway through Q3
        );

        // Line should extend to 2.5
        expect(data.points.last.x, equals(2.5));
        expect(data.points.last.differential, equals(6));
      });

      test('should calculate y-axis max based on max differential', () {
        // Create events that produce a 30-point differential
        final events = <GameEvent>[];
        for (int i = 0; i < 5; i++) {
          events.add(
            GameEvent(
              quarter: 1,
              time: Duration(minutes: i + 1),
              team: 'Home FC',
              type: 'goal',
            ),
          );
        }

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // 5 goals = 30 points, should round to 50
        expect(data.yAxisMax, equals(50));
      });

      test('should handle clock events without affecting score', () {
        final events = [
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 0),
            team: '',
            type: 'clock_start',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 5),
            team: 'Home FC',
            type: 'goal',
          ),
          GameEvent(
            quarter: 1,
            time: const Duration(minutes: 20),
            team: '',
            type: 'clock_end',
          ),
        ];

        final data = ScoreWormDataService.generateData(
          events: events,
          homeTeam: 'Home FC',
          awayTeam: 'Away FC',
          quarterMinutes: 20,
        );

        // Should only have points for origin and the goal
        expect(data.points.last.differential, equals(6));
      });
    });
  });
}
