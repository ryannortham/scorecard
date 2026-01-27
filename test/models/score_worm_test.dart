// tests for score worm chart data models

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/services/score_worm_data_service.dart';

void main() {
  group('ScoreWormPoint', () {
    test('should create point with x position and differential', () {
      const point = ScoreWormPoint(x: 1.5, differential: 12);

      expect(point.x, equals(1.5));
      expect(point.differential, equals(12));
    });

    test('should allow negative differential (away leading)', () {
      const point = ScoreWormPoint(x: 2.0, differential: -18);

      expect(point.differential, equals(-18));
    });

    test('should allow zero differential (tied)', () {
      const point = ScoreWormPoint(x: 0.0, differential: 0);

      expect(point.differential, equals(0));
    });

    test('should allow x values from 0 to 4', () {
      const pointStart = ScoreWormPoint(x: 0.0, differential: 0);
      const pointEnd = ScoreWormPoint(x: 4.0, differential: 24);

      expect(pointStart.x, equals(0.0));
      expect(pointEnd.x, equals(4.0));
    });
  });

  group('QuarterScore', () {
    group('points calculation', () {
      test('should calculate points as goals * 6 + behinds', () {
        const score = QuarterScore(goals: 5, behinds: 3);

        expect(score.points, equals(33)); // 5 * 6 + 3
      });

      test('should return 0 for zero goals and behinds', () {
        const score = QuarterScore(goals: 0, behinds: 0);

        expect(score.points, equals(0));
      });

      test('should calculate with only goals', () {
        const score = QuarterScore(goals: 10, behinds: 0);

        expect(score.points, equals(60));
      });

      test('should calculate with only behinds', () {
        const score = QuarterScore(goals: 0, behinds: 8);

        expect(score.points, equals(8));
      });
    });

    group('display formatting', () {
      test('should format as goals.behinds', () {
        const score = QuarterScore(goals: 5, behinds: 3);

        expect(score.display, equals('5.3'));
      });

      test('should format zero score correctly', () {
        const score = QuarterScore(goals: 0, behinds: 0);

        expect(score.display, equals('0.0'));
      });

      test('should format high scores correctly', () {
        const score = QuarterScore(goals: 25, behinds: 15);

        expect(score.display, equals('25.15'));
      });
    });

    group('zero constant', () {
      test('QuarterScore.zero should have zero goals and behinds', () {
        expect(QuarterScore.zero.goals, equals(0));
        expect(QuarterScore.zero.behinds, equals(0));
        expect(QuarterScore.zero.points, equals(0));
        expect(QuarterScore.zero.display, equals('0.0'));
      });
    });
  });

  group('ScoreWormData', () {
    test('should create with all required fields', () {
      final points = [
        const ScoreWormPoint(x: 0, differential: 0),
        const ScoreWormPoint(x: 1.0, differential: 12),
        const ScoreWormPoint(x: 2.0, differential: 6),
      ];
      final homeQuarterScores = {
        1: const QuarterScore(goals: 2, behinds: 0),
        2: const QuarterScore(goals: 3, behinds: 1),
      };
      final awayQuarterScores = {
        1: const QuarterScore(goals: 1, behinds: 0),
        2: const QuarterScore(goals: 2, behinds: 1),
      };

      final data = ScoreWormData(
        points: points,
        homeQuarterScores: homeQuarterScores,
        awayQuarterScores: awayQuarterScores,
        yAxisMax: 20,
      );

      expect(data.points.length, equals(3));
      expect(data.homeQuarterScores[1]!.goals, equals(2));
      expect(data.awayQuarterScores[2]!.behinds, equals(1));
      expect(data.yAxisMax, equals(20));
    });

    test('should store quarter scores as running totals', () {
      final data = ScoreWormData(
        points: [const ScoreWormPoint(x: 0, differential: 0)],
        homeQuarterScores: {
          1: const QuarterScore(goals: 3, behinds: 2),
          2: const QuarterScore(goals: 6, behinds: 4), // Running total
          3: const QuarterScore(goals: 9, behinds: 5),
          4: const QuarterScore(goals: 12, behinds: 8),
        },
        awayQuarterScores: {
          1: const QuarterScore(goals: 2, behinds: 1),
          2: const QuarterScore(goals: 4, behinds: 3),
          3: const QuarterScore(goals: 7, behinds: 4),
          4: const QuarterScore(goals: 10, behinds: 6),
        },
        yAxisMax: 50,
      );

      // Q1 totals
      expect(data.homeQuarterScores[1]!.points, equals(20)); // 3*6 + 2
      expect(data.awayQuarterScores[1]!.points, equals(13)); // 2*6 + 1

      // Q4 (final) totals
      expect(data.homeQuarterScores[4]!.points, equals(80)); // 12*6 + 8
      expect(data.awayQuarterScores[4]!.points, equals(66)); // 10*6 + 6
    });

    test('should handle empty points list', () {
      final data = ScoreWormData(
        points: [],
        homeQuarterScores: {},
        awayQuarterScores: {},
        yAxisMax: 20,
      );

      expect(data.points, isEmpty);
    });
  });

  // Note: ScoreWormColours.fromTheme requires AppColors which depends on
  // Flutter widgets and theme context. Those tests would require widget
  // testing infrastructure.
  //
  // ScoreWormColours is a simple data class that holds Color values.
  // The factory constructor fromTheme() is tested implicitly through
  // widget tests that render the score worm chart.
}
