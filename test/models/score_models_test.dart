// Tests for Team, ScoreData, TeamScore, and ScoreComparator models

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/playhq_models.dart';
import 'package:scorecard/models/score_models.dart';

void main() {
  group('Team', () {
    group('constructor', () {
      test('should create team with name only', () {
        const team = Team(name: 'Richmond');

        expect(team.name, equals('Richmond'));
        expect(team.logoUrl, isNull);
        expect(team.logoUrl32, isNull);
        expect(team.logoUrl48, isNull);
        expect(team.logoUrlLarge, isNull);
        expect(team.address, isNull);
        expect(team.playHQId, isNull);
        expect(team.routingCode, isNull);
      });

      test('should create team with all optional fields', () {
        final address = Address(
          id: 'addr-1',
          line1: '123 Punt Road',
          suburb: 'Richmond',
          postcode: '3121',
          state: 'VIC',
          country: 'Australia',
        );

        final team = Team(
          name: 'Richmond',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          logoUrl48: 'https://example.com/logo48.png',
          logoUrlLarge: 'https://example.com/logo-large.png',
          address: address,
          playHQId: 'playhq-123',
          routingCode: 'VIC-001',
        );

        expect(team.name, equals('Richmond'));
        expect(team.logoUrl, equals('https://example.com/logo.png'));
        expect(team.logoUrl32, equals('https://example.com/logo32.png'));
        expect(team.logoUrl48, equals('https://example.com/logo48.png'));
        expect(team.logoUrlLarge, equals('https://example.com/logo-large.png'));
        expect(team.address, equals(address));
        expect(team.playHQId, equals('playhq-123'));
        expect(team.routingCode, equals('VIC-001'));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        const original = Team(name: 'Richmond');
        final copied = original.copyWith(name: 'Carlton');

        expect(copied.name, equals('Carlton'));
        expect(original.name, equals('Richmond'));
      });

      test('should preserve unchanged fields', () {
        const original = Team(
          name: 'Richmond',
          logoUrl: 'https://example.com/logo.png',
          playHQId: 'id-123',
        );
        final copied = original.copyWith(name: 'Carlton');

        expect(copied.logoUrl, equals('https://example.com/logo.png'));
        expect(copied.playHQId, equals('id-123'));
      });

      test('should copy with new address', () {
        const original = Team(name: 'Richmond');
        final newAddress = Address(
          id: 'addr-1',
          line1: '456 New Road',
          suburb: 'Carlton',
          postcode: '3053',
          state: 'VIC',
          country: 'Australia',
        );

        final copied = original.copyWith(address: newAddress);

        expect(copied.address, equals(newAddress));
      });
    });

    group('toJson', () {
      test('should serialise team with all fields', () {
        final team = Team(
          name: 'Richmond',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          logoUrl48: 'https://example.com/logo48.png',
          logoUrlLarge: 'https://example.com/logo-large.png',
          address: Address(
            id: 'addr-1',
            line1: '123 Punt Road',
            suburb: 'Richmond',
            postcode: '3121',
            state: 'VIC',
            country: 'Australia',
          ),
          playHQId: 'playhq-123',
          routingCode: 'VIC-001',
        );

        final json = team.toJson();

        expect(json['name'], equals('Richmond'));
        expect(json['logoUrl'], equals('https://example.com/logo.png'));
        expect(json['logoUrl32'], equals('https://example.com/logo32.png'));
        expect(json['playHQId'], equals('playhq-123'));
        expect(json['routingCode'], equals('VIC-001'));
        expect(json['address'], isNotNull);
      });

      test('should serialise null fields as null', () {
        const team = Team(name: 'Richmond');

        final json = team.toJson();

        expect(json['logoUrl'], isNull);
        expect(json['address'], isNull);
        expect(json['playHQId'], isNull);
      });
    });

    group('fromJson', () {
      test('should deserialise team with all fields', () {
        final json = {
          'name': 'Richmond',
          'logoUrl': 'https://example.com/logo.png',
          'logoUrl32': 'https://example.com/logo32.png',
          'logoUrl48': 'https://example.com/logo48.png',
          'logoUrlLarge': 'https://example.com/logo-large.png',
          'address': {
            'id': 'addr-1',
            'line1': '123 Punt Road',
            'suburb': 'Richmond',
            'postcode': '3121',
            'state': 'VIC',
            'country': 'Australia',
          },
          'playHQId': 'playhq-123',
          'routingCode': 'VIC-001',
        };

        final team = Team.fromJson(json);

        expect(team.name, equals('Richmond'));
        expect(team.logoUrl, equals('https://example.com/logo.png'));
        expect(team.address, isNotNull);
        expect(team.address!.suburb, equals('Richmond'));
        expect(team.playHQId, equals('playhq-123'));
      });

      test('should handle missing optional fields', () {
        final json = {'name': 'Carlton'};

        final team = Team.fromJson(json);

        expect(team.name, equals('Carlton'));
        expect(team.logoUrl, isNull);
        expect(team.address, isNull);
        expect(team.playHQId, isNull);
      });

      test('should default name to empty string if missing', () {
        final json = <String, dynamic>{};

        final team = Team.fromJson(json);

        expect(team.name, equals(''));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const team1 = Team(name: 'Richmond', playHQId: 'id-123');
        const team2 = Team(name: 'Richmond', playHQId: 'id-123');

        expect(team1, equals(team2));
      });

      test('should not be equal when name differs', () {
        const team1 = Team(name: 'Richmond');
        const team2 = Team(name: 'Carlton');

        expect(team1, isNot(equals(team2)));
      });

      test('should not be equal when optional field differs', () {
        const team1 = Team(name: 'Richmond', playHQId: 'id-123');
        const team2 = Team(name: 'Richmond', playHQId: 'id-456');

        expect(team1, isNot(equals(team2)));
      });

      test('should have same hashCode for equal teams', () {
        const team1 = Team(name: 'Richmond', playHQId: 'id-123');
        const team2 = Team(name: 'Richmond', playHQId: 'id-123');

        expect(team1.hashCode, equals(team2.hashCode));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = Team(
          name: 'Richmond',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          logoUrl48: 'https://example.com/logo48.png',
          logoUrlLarge: 'https://example.com/logo-large.png',
          address: Address(
            id: 'addr-1',
            line1: '123 Punt Road',
            suburb: 'Richmond',
            postcode: '3121',
            state: 'VIC',
            country: 'Australia',
          ),
          playHQId: 'playhq-123',
          routingCode: 'VIC-001',
        );

        final json = original.toJson();
        final restored = Team.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });

  group('ScoreData', () {
    group('constructor', () {
      test('should create score data and calculate points', () {
        const score = ScoreData(goals: 10, behinds: 8);

        expect(score.goals, equals(10));
        expect(score.behinds, equals(8));
        expect(score.points, equals(68)); // 10 * 6 + 8
      });

      test('should handle zero goals', () {
        const score = ScoreData(goals: 0, behinds: 5);

        expect(score.points, equals(5));
      });

      test('should handle zero behinds', () {
        const score = ScoreData(goals: 5, behinds: 0);

        expect(score.points, equals(30));
      });

      test('should handle zero score', () {
        const score = ScoreData(goals: 0, behinds: 0);

        expect(score.points, equals(0));
      });
    });

    group('copyWith', () {
      test('should copy with new goals', () {
        const original = ScoreData(goals: 5, behinds: 3);
        final copied = original.copyWith(goals: 10);

        expect(copied.goals, equals(10));
        expect(copied.behinds, equals(3)); // Preserved
        expect(copied.points, equals(63)); // Recalculated: 10 * 6 + 3
      });

      test('should copy with new behinds', () {
        const original = ScoreData(goals: 5, behinds: 3);
        final copied = original.copyWith(behinds: 10);

        expect(copied.goals, equals(5)); // Preserved
        expect(copied.behinds, equals(10));
        expect(copied.points, equals(40)); // 5 * 6 + 10
      });
    });

    group('equality', () {
      test('should be equal when goals and behinds match', () {
        const score1 = ScoreData(goals: 5, behinds: 3);
        const score2 = ScoreData(goals: 5, behinds: 3);

        expect(score1, equals(score2));
      });

      test('should not be equal when goals differ', () {
        const score1 = ScoreData(goals: 5, behinds: 3);
        const score2 = ScoreData(goals: 6, behinds: 3);

        expect(score1, isNot(equals(score2)));
      });

      test('should not be equal when behinds differ', () {
        const score1 = ScoreData(goals: 5, behinds: 3);
        const score2 = ScoreData(goals: 5, behinds: 4);

        expect(score1, isNot(equals(score2)));
      });

      test('should have same hashCode for equal scores', () {
        const score1 = ScoreData(goals: 5, behinds: 3);
        const score2 = ScoreData(goals: 5, behinds: 3);

        expect(score1.hashCode, equals(score2.hashCode));
      });
    });

    group('toString', () {
      test('should format as goals.behinds (points)', () {
        const score = ScoreData(goals: 10, behinds: 8);

        expect(score.toString(), equals('10.8 (68)'));
      });

      test('should format zero score correctly', () {
        const score = ScoreData(goals: 0, behinds: 0);

        expect(score.toString(), equals('0.0 (0)'));
      });
    });
  });

  group('TeamScore', () {
    group('constructor', () {
      test('should create team score with defaults', () {
        const teamScore = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
        );

        expect(teamScore.name, equals('Richmond'));
        expect(teamScore.score.goals, equals(10));
        expect(teamScore.isWinner, isFalse);
      });

      test('should create team score with isWinner true', () {
        const teamScore = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
          isWinner: true,
        );

        expect(teamScore.isWinner, isTrue);
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        const original = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
        );
        final copied = original.copyWith(name: 'Carlton');

        expect(copied.name, equals('Carlton'));
        expect(copied.score, equals(original.score));
        expect(copied.isWinner, equals(original.isWinner));
      });

      test('should copy with isWinner', () {
        const original = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
          isWinner: false,
        );
        final copied = original.copyWith(isWinner: true);

        expect(copied.isWinner, isTrue);
        expect(copied.name, equals(original.name));
      });

      test('should copy with new score', () {
        const original = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
        );
        final copied = original.copyWith(
          score: const ScoreData(goals: 15, behinds: 8),
        );

        expect(copied.score.goals, equals(15));
        expect(copied.score.behinds, equals(8));
      });
    });
  });

  group('ScoreComparator', () {
    group('isWinner', () {
      test('should return true when team1 has more points', () {
        const score1 = ScoreData(goals: 10, behinds: 5); // 65 points
        const score2 = ScoreData(goals: 8, behinds: 8); // 56 points

        expect(ScoreComparator.isWinner(score1, score2), isTrue);
      });

      test('should return false when team1 has fewer points', () {
        const score1 = ScoreData(goals: 8, behinds: 5); // 53 points
        const score2 = ScoreData(goals: 10, behinds: 8); // 68 points

        expect(ScoreComparator.isWinner(score1, score2), isFalse);
      });

      test('should return false when scores are equal', () {
        const score1 = ScoreData(goals: 10, behinds: 5); // 65 points
        const score2 = ScoreData(goals: 10, behinds: 5); // 65 points

        expect(ScoreComparator.isWinner(score1, score2), isFalse);
      });
    });

    group('isDraw', () {
      test('should return true when points are equal', () {
        const score1 = ScoreData(goals: 10, behinds: 5); // 65 points
        const score2 = ScoreData(goals: 10, behinds: 5); // 65 points

        expect(ScoreComparator.isDraw(score1, score2), isTrue);
      });

      test(
        'should return true with different goals/behinds but same points',
        () {
          const score1 = ScoreData(goals: 10, behinds: 6); // 66 points
          const score2 = ScoreData(goals: 11, behinds: 0); // 66 points

          expect(ScoreComparator.isDraw(score1, score2), isTrue);
        },
      );

      test('should return false when points differ', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 10, behinds: 6);

        expect(ScoreComparator.isDraw(score1, score2), isFalse);
      });
    });

    group('pointsDifference', () {
      test('should calculate positive difference', () {
        const winner = ScoreData(goals: 15, behinds: 10); // 100 points
        const loser = ScoreData(goals: 10, behinds: 8); // 68 points

        expect(ScoreComparator.pointsDifference(winner, loser), equals(32));
      });

      test('should return 0 for draw', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 10, behinds: 5);

        expect(ScoreComparator.pointsDifference(score1, score2), equals(0));
      });

      test('should return negative when order is wrong', () {
        const loser = ScoreData(goals: 10, behinds: 5); // 65 points
        const winner = ScoreData(goals: 15, behinds: 8); // 98 points

        // Note: If loser is passed as first argument, difference is negative
        expect(ScoreComparator.pointsDifference(loser, winner), equals(-33));
      });
    });

    group('determineWinner', () {
      test('should mark team1 as winner when team1 has more points', () {
        const team1 = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 15, behinds: 10), // 100 points
        );
        const team2 = TeamScore(
          name: 'Carlton',
          score: ScoreData(goals: 10, behinds: 8), // 68 points
        );

        final result = ScoreComparator.determineWinner(team1, team2);

        expect(result.name, equals('Richmond'));
        expect(result.isWinner, isTrue);
      });

      test('should mark team2 as winner when team2 has more points', () {
        const team1 = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5), // 65 points
        );
        const team2 = TeamScore(
          name: 'Carlton',
          score: ScoreData(goals: 15, behinds: 10), // 100 points
        );

        final result = ScoreComparator.determineWinner(team1, team2);

        expect(result.name, equals('Carlton'));
        expect(result.isWinner, isTrue);
      });

      test('should return team1 without winner flag on draw', () {
        const team1 = TeamScore(
          name: 'Richmond',
          score: ScoreData(goals: 10, behinds: 5),
        );
        const team2 = TeamScore(
          name: 'Carlton',
          score: ScoreData(goals: 10, behinds: 5),
        );

        final result = ScoreComparator.determineWinner(team1, team2);

        expect(result.name, equals('Richmond'));
        expect(result.isWinner, isFalse);
      });
    });
  });
}
