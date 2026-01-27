// tests for score models (Team, ScoreData, TeamScore)

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/models/score.dart';

void main() {
  group('ScoreData', () {
    group('points calculation', () {
      test('should calculate points as goals * 6 + behinds', () {
        const score = ScoreData(goals: 10, behinds: 5);
        expect(score.points, equals(65));
      });

      test('should return 0 points for zero goals and behinds', () {
        const score = ScoreData(goals: 0, behinds: 0);
        expect(score.points, equals(0));
      });

      test('should calculate points with only goals', () {
        const score = ScoreData(goals: 5, behinds: 0);
        expect(score.points, equals(30));
      });

      test('should calculate points with only behinds', () {
        const score = ScoreData(goals: 0, behinds: 6);
        expect(score.points, equals(6));
      });

      test('should handle large scores', () {
        const score = ScoreData(goals: 25, behinds: 15);
        expect(score.points, equals(165));
      });
    });

    group('toString', () {
      test('should format as goals.behinds (points)', () {
        const score = ScoreData(goals: 10, behinds: 5);
        expect(score.toString(), equals('10.5 (65)'));
      });

      test('should format zero score correctly', () {
        const score = ScoreData(goals: 0, behinds: 0);
        expect(score.toString(), equals('0.0 (0)'));
      });
    });

    group('equality', () {
      test('should be equal when goals and behinds match', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 10, behinds: 5);
        expect(score1, equals(score2));
      });

      test('should not be equal when goals differ', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 11, behinds: 5);
        expect(score1, isNot(equals(score2)));
      });

      test('should not be equal when behinds differ', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 10, behinds: 6);
        expect(score1, isNot(equals(score2)));
      });

      test('should have same hashCode for equal objects', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 10, behinds: 5);
        expect(score1.hashCode, equals(score2.hashCode));
      });
    });

    group('copyWith', () {
      test('should copy with new goals', () {
        const original = ScoreData(goals: 10, behinds: 5);
        final copied = original.copyWith(goals: 15);
        expect(copied.goals, equals(15));
        expect(copied.behinds, equals(5));
        expect(copied.points, equals(95));
      });

      test('should copy with new behinds', () {
        const original = ScoreData(goals: 10, behinds: 5);
        final copied = original.copyWith(behinds: 10);
        expect(copied.goals, equals(10));
        expect(copied.behinds, equals(10));
        expect(copied.points, equals(70));
      });

      test('should copy with both new values', () {
        const original = ScoreData(goals: 10, behinds: 5);
        final copied = original.copyWith(goals: 20, behinds: 10);
        expect(copied.goals, equals(20));
        expect(copied.behinds, equals(10));
        expect(copied.points, equals(130));
      });

      test('should return identical values when no parameters passed', () {
        const original = ScoreData(goals: 10, behinds: 5);
        final copied = original.copyWith();
        expect(copied.goals, equals(original.goals));
        expect(copied.behinds, equals(original.behinds));
        expect(copied.points, equals(original.points));
      });
    });
  });

  group('Team', () {
    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'name': 'Richmond',
          'logoUrl': 'https://example.com/logo.png',
          'logoUrl32': 'https://example.com/logo32.png',
          'logoUrl48': 'https://example.com/logo48.png',
          'logoUrlLarge': 'https://example.com/logo-large.png',
          'playHQId': 'abc123',
          'routingCode': 'VIC-123',
          'address': {
            'id': 'addr1',
            'line1': '123 Punt Road',
            'suburb': 'Richmond',
            'postcode': '3121',
            'state': 'VIC',
            'country': 'Australia',
          },
        };

        final team = Team.fromJson(json);

        expect(team.name, equals('Richmond'));
        expect(team.logoUrl, equals('https://example.com/logo.png'));
        expect(team.logoUrl32, equals('https://example.com/logo32.png'));
        expect(team.logoUrl48, equals('https://example.com/logo48.png'));
        expect(team.logoUrlLarge, equals('https://example.com/logo-large.png'));
        expect(team.playHQId, equals('abc123'));
        expect(team.routingCode, equals('VIC-123'));
        expect(team.address, isNotNull);
        expect(team.address!.line1, equals('123 Punt Road'));
      });

      test('should parse minimal JSON with only name', () {
        final json = {'name': 'Collingwood'};

        final team = Team.fromJson(json);

        expect(team.name, equals('Collingwood'));
        expect(team.logoUrl, isNull);
        expect(team.logoUrl32, isNull);
        expect(team.logoUrl48, isNull);
        expect(team.logoUrlLarge, isNull);
        expect(team.playHQId, isNull);
        expect(team.routingCode, isNull);
        expect(team.address, isNull);
      });

      test('should default name to empty string when missing', () {
        final json = <String, dynamic>{};

        final team = Team.fromJson(json);

        expect(team.name, equals(''));
      });

      test('should parse JSON with null address', () {
        final json = {'name': 'Essendon', 'address': null};

        final team = Team.fromJson(json);

        expect(team.name, equals('Essendon'));
        expect(team.address, isNull);
      });
    });

    group('toJson', () {
      test('should serialise to JSON correctly', () {
        const team = Team(
          name: 'Carlton',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          logoUrl48: 'https://example.com/logo48.png',
          logoUrlLarge: 'https://example.com/logo-large.png',
          playHQId: 'xyz789',
          routingCode: 'VIC-456',
        );

        final json = team.toJson();

        expect(json['name'], equals('Carlton'));
        expect(json['logoUrl'], equals('https://example.com/logo.png'));
        expect(json['logoUrl32'], equals('https://example.com/logo32.png'));
        expect(json['logoUrl48'], equals('https://example.com/logo48.png'));
        expect(
          json['logoUrlLarge'],
          equals('https://example.com/logo-large.png'),
        );
        expect(json['playHQId'], equals('xyz789'));
        expect(json['routingCode'], equals('VIC-456'));
      });

      test('should include null values in JSON', () {
        const team = Team(name: 'Hawthorn');

        final json = team.toJson();

        expect(json['name'], equals('Hawthorn'));
        expect(json.containsKey('logoUrl'), isTrue);
        expect(json['logoUrl'], isNull);
      });

      test('should serialise address when present', () {
        const address = Address(
          id: 'addr1',
          line1: '123 Street',
          suburb: 'Melbourne',
          postcode: '3000',
          state: 'VIC',
          country: 'Australia',
        );
        const team = Team(name: 'Melbourne', address: address);

        final json = team.toJson();

        expect(json['address'], isNotNull);
        expect(json['address']['line1'], equals('123 Street'));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        const address = Address(
          id: 'addr1',
          line1: '123 Street',
          suburb: 'Suburb',
          postcode: '3000',
          state: 'VIC',
          country: 'Australia',
        );
        const original = Team(
          name: 'Geelong',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          logoUrl48: 'https://example.com/logo48.png',
          logoUrlLarge: 'https://example.com/logo-large.png',
          playHQId: 'id123',
          routingCode: 'VIC-789',
          address: address,
        );

        final json = original.toJson();
        final restored = Team.fromJson(json);

        expect(restored, equals(original));
      });

      test('should handle minimal team through round-trip', () {
        const original = Team(name: 'St Kilda');

        final json = original.toJson();
        final restored = Team.fromJson(json);

        expect(restored.name, equals(original.name));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        const original = Team(name: 'Original', logoUrl: 'url');
        final copied = original.copyWith(name: 'New Name');

        expect(copied.name, equals('New Name'));
        expect(copied.logoUrl, equals('url'));
      });

      test('should copy with new logoUrl', () {
        const original = Team(name: 'Team', logoUrl: 'old-url');
        final copied = original.copyWith(logoUrl: 'new-url');

        expect(copied.name, equals('Team'));
        expect(copied.logoUrl, equals('new-url'));
      });

      test('should preserve all fields when no parameters passed', () {
        const address = Address(
          id: 'addr1',
          line1: '123 Street',
          suburb: 'Suburb',
          postcode: '3000',
          state: 'VIC',
          country: 'Australia',
        );
        const original = Team(
          name: 'Team',
          logoUrl: 'url',
          logoUrl32: 'url32',
          logoUrl48: 'url48',
          logoUrlLarge: 'urlLarge',
          playHQId: 'id',
          routingCode: 'code',
          address: address,
        );

        final copied = original.copyWith();

        expect(copied, equals(original));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const team1 = Team(name: 'Team', logoUrl: 'url', playHQId: 'id');
        const team2 = Team(name: 'Team', logoUrl: 'url', playHQId: 'id');

        expect(team1, equals(team2));
      });

      test('should not be equal when name differs', () {
        const team1 = Team(name: 'Team1');
        const team2 = Team(name: 'Team2');

        expect(team1, isNot(equals(team2)));
      });

      test('should have same hashCode for equal teams', () {
        const team1 = Team(name: 'Team', logoUrl: 'url');
        const team2 = Team(name: 'Team', logoUrl: 'url');

        expect(team1.hashCode, equals(team2.hashCode));
      });
    });
  });

  group('TeamScore', () {
    test('should create with required fields', () {
      const score = ScoreData(goals: 10, behinds: 5);
      const teamScore = TeamScore(name: 'Richmond', score: score);

      expect(teamScore.name, equals('Richmond'));
      expect(teamScore.score, equals(score));
      expect(teamScore.isWinner, isFalse);
    });

    test('should create with isWinner flag', () {
      const score = ScoreData(goals: 15, behinds: 8);
      const teamScore = TeamScore(
        name: 'Carlton',
        score: score,
        isWinner: true,
      );

      expect(teamScore.isWinner, isTrue);
    });

    group('copyWith', () {
      test('should copy with new name', () {
        const score = ScoreData(goals: 10, behinds: 5);
        const original = TeamScore(name: 'Original', score: score);
        final copied = original.copyWith(name: 'New Name');

        expect(copied.name, equals('New Name'));
        expect(copied.score, equals(score));
      });

      test('should copy with new score', () {
        const score1 = ScoreData(goals: 10, behinds: 5);
        const score2 = ScoreData(goals: 15, behinds: 8);
        const original = TeamScore(name: 'Team', score: score1);
        final copied = original.copyWith(score: score2);

        expect(copied.name, equals('Team'));
        expect(copied.score, equals(score2));
      });

      test('should copy with new isWinner', () {
        const score = ScoreData(goals: 10, behinds: 5);
        const original = TeamScore(name: 'Team', score: score);
        final copied = original.copyWith(isWinner: true);

        expect(copied.isWinner, isTrue);
      });
    });
  });
}
