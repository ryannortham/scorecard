// tests for game record models (GameEvent, GameRecord)

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/providers/game_record_provider.dart';

void main() {
  group('GameEvent', () {
    group('constructor', () {
      test('should create event with required fields', () {
        final event = GameEvent(
          quarter: 1,
          time: const Duration(milliseconds: 60000),
          team: 'Richmond',
          type: 'goal',
        );

        expect(event.quarter, equals(1));
        expect(event.time, equals(const Duration(milliseconds: 60000)));
        expect(event.team, equals('Richmond'));
        expect(event.type, equals('goal'));
      });

      test('should allow empty team for clock events', () {
        final event = GameEvent(
          quarter: 1,
          time: const Duration(),
          team: '',
          type: 'clock_start',
        );

        expect(event.team, equals(''));
        expect(event.type, equals('clock_start'));
      });
    });

    group('fromJson', () {
      test('should parse goal event from JSON', () {
        final json = {
          'quarter': 2,
          'timeMs': 120000,
          'team': 'Carlton',
          'type': 'goal',
        };

        final event = GameEvent.fromJson(json);

        expect(event.quarter, equals(2));
        expect(event.time, equals(const Duration(milliseconds: 120000)));
        expect(event.team, equals('Carlton'));
        expect(event.type, equals('goal'));
      });

      test('should parse behind event from JSON', () {
        final json = {
          'quarter': 3,
          'timeMs': 180000,
          'team': 'Essendon',
          'type': 'behind',
        };

        final event = GameEvent.fromJson(json);

        expect(event.type, equals('behind'));
      });

      test('should parse clock_start event from JSON', () {
        final json = {
          'quarter': 1,
          'timeMs': 0,
          'team': '',
          'type': 'clock_start',
        };

        final event = GameEvent.fromJson(json);

        expect(event.type, equals('clock_start'));
        expect(event.team, equals(''));
      });

      test('should parse clock_pause event from JSON', () {
        final json = {
          'quarter': 1,
          'timeMs': 300000,
          'team': '',
          'type': 'clock_pause',
        };

        final event = GameEvent.fromJson(json);

        expect(event.type, equals('clock_pause'));
      });

      test('should parse clock_end event from JSON', () {
        final json = {
          'quarter': 4,
          'timeMs': 1200000,
          'team': '',
          'type': 'clock_end',
        };

        final event = GameEvent.fromJson(json);

        expect(event.quarter, equals(4));
        expect(event.type, equals('clock_end'));
      });
    });

    group('toJson', () {
      test('should serialise event to JSON', () {
        final event = GameEvent(
          quarter: 2,
          time: const Duration(milliseconds: 90000),
          team: 'Hawthorn',
          type: 'goal',
        );

        final json = event.toJson();

        expect(json['quarter'], equals(2));
        expect(json['timeMs'], equals(90000));
        expect(json['team'], equals('Hawthorn'));
        expect(json['type'], equals('goal'));
      });

      test('should store time as milliseconds', () {
        final event = GameEvent(
          quarter: 1,
          time: const Duration(minutes: 5, seconds: 30),
          team: 'Geelong',
          type: 'behind',
        );

        final json = event.toJson();

        expect(json['timeMs'], equals(330000)); // 5.5 minutes in ms
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = GameEvent(
          quarter: 3,
          time: const Duration(milliseconds: 456789),
          team: 'Melbourne',
          type: 'goal',
        );

        final json = original.toJson();
        final restored = GameEvent.fromJson(json);

        expect(restored.quarter, equals(original.quarter));
        expect(restored.time, equals(original.time));
        expect(restored.team, equals(original.team));
        expect(restored.type, equals(original.type));
      });

      test('should handle clock event round-trip', () {
        final original = GameEvent(
          quarter: 4,
          time: const Duration(milliseconds: 1200000),
          team: '',
          type: 'clock_end',
        );

        final json = original.toJson();
        final restored = GameEvent.fromJson(json);

        expect(restored.quarter, equals(original.quarter));
        expect(restored.time, equals(original.time));
        expect(restored.team, equals(original.team));
        expect(restored.type, equals(original.type));
      });
    });
  });

  group('GameRecord', () {
    late DateTime testDate;
    late List<GameEvent> testEvents;

    setUp(() {
      testDate = DateTime(2024, 6, 15, 14, 30);
      testEvents = [
        GameEvent(
          quarter: 1,
          time: const Duration(milliseconds: 60000),
          team: 'Richmond',
          type: 'goal',
        ),
        GameEvent(
          quarter: 1,
          time: const Duration(milliseconds: 120000),
          team: 'Carlton',
          type: 'behind',
        ),
      ];
    });

    group('constructor', () {
      test('should create record with all required fields', () {
        final record = GameRecord(
          id: 'game-123',
          date: testDate,
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: testEvents,
          homeGoals: 10,
          homeBehinds: 5,
          awayGoals: 8,
          awayBehinds: 12,
        );

        expect(record.id, equals('game-123'));
        expect(record.date, equals(testDate));
        expect(record.homeTeam, equals('Richmond'));
        expect(record.awayTeam, equals('Carlton'));
        expect(record.quarterMinutes, equals(20));
        expect(record.isCountdownTimer, isTrue);
        expect(record.events.length, equals(2));
        expect(record.homeGoals, equals(10));
        expect(record.homeBehinds, equals(5));
        expect(record.awayGoals, equals(8));
        expect(record.awayBehinds, equals(12));
      });
    });

    group('computed properties', () {
      test('should calculate homePoints correctly', () {
        final record = GameRecord(
          id: 'game-123',
          date: testDate,
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 10,
          homeBehinds: 5,
          awayGoals: 0,
          awayBehinds: 0,
        );

        expect(record.homePoints, equals(65)); // 10 * 6 + 5
      });

      test('should calculate awayPoints correctly', () {
        final record = GameRecord(
          id: 'game-123',
          date: testDate,
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 0,
          homeBehinds: 0,
          awayGoals: 8,
          awayBehinds: 12,
        );

        expect(record.awayPoints, equals(60)); // 8 * 6 + 12
      });

      test('should return 0 points for zero scores', () {
        final record = GameRecord(
          id: 'game-123',
          date: testDate,
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 0,
          homeBehinds: 0,
          awayGoals: 0,
          awayBehinds: 0,
        );

        expect(record.homePoints, equals(0));
        expect(record.awayPoints, equals(0));
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'id': 'game-456',
          'date': '2024-06-15T14:30:00.000',
          'homeTeam': 'Essendon',
          'awayTeam': 'Collingwood',
          'quarterMinutes': 25,
          'isCountdownTimer': false,
          'events': [
            {'quarter': 1, 'timeMs': 60000, 'team': 'Essendon', 'type': 'goal'},
          ],
          'homeGoals': 15,
          'homeBehinds': 10,
          'awayGoals': 12,
          'awayBehinds': 8,
        };

        final record = GameRecord.fromJson(json);

        expect(record.id, equals('game-456'));
        expect(record.date.year, equals(2024));
        expect(record.date.month, equals(6));
        expect(record.date.day, equals(15));
        expect(record.homeTeam, equals('Essendon'));
        expect(record.awayTeam, equals('Collingwood'));
        expect(record.quarterMinutes, equals(25));
        expect(record.isCountdownTimer, isFalse);
        expect(record.events.length, equals(1));
        expect(record.homeGoals, equals(15));
        expect(record.homeBehinds, equals(10));
        expect(record.awayGoals, equals(12));
        expect(record.awayBehinds, equals(8));
      });

      test('should parse JSON with empty events list', () {
        final json = {
          'id': 'game-789',
          'date': '2024-01-01T10:00:00.000',
          'homeTeam': 'Home',
          'awayTeam': 'Away',
          'quarterMinutes': 20,
          'isCountdownTimer': true,
          'events': <Map<String, dynamic>>[],
          'homeGoals': 0,
          'homeBehinds': 0,
          'awayGoals': 0,
          'awayBehinds': 0,
        };

        final record = GameRecord.fromJson(json);

        expect(record.events, isEmpty);
      });

      test('should parse date as ISO8601 string', () {
        final json = {
          'id': 'game-123',
          'date': '2024-12-25T09:15:30.123',
          'homeTeam': 'Home',
          'awayTeam': 'Away',
          'quarterMinutes': 20,
          'isCountdownTimer': true,
          'events': <Map<String, dynamic>>[],
          'homeGoals': 0,
          'homeBehinds': 0,
          'awayGoals': 0,
          'awayBehinds': 0,
        };

        final record = GameRecord.fromJson(json);

        expect(record.date.year, equals(2024));
        expect(record.date.month, equals(12));
        expect(record.date.day, equals(25));
        expect(record.date.hour, equals(9));
        expect(record.date.minute, equals(15));
        expect(record.date.second, equals(30));
      });
    });

    group('toJson', () {
      test('should serialise to JSON correctly', () {
        final record = GameRecord(
          id: 'game-123',
          date: DateTime(2024, 6, 15, 14, 30),
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [
            GameEvent(
              quarter: 1,
              time: const Duration(milliseconds: 60000),
              team: 'Richmond',
              type: 'goal',
            ),
          ],
          homeGoals: 10,
          homeBehinds: 5,
          awayGoals: 8,
          awayBehinds: 12,
        );

        final json = record.toJson();

        expect(json['id'], equals('game-123'));
        expect(json['date'], contains('2024-06-15'));
        expect(json['homeTeam'], equals('Richmond'));
        expect(json['awayTeam'], equals('Carlton'));
        expect(json['quarterMinutes'], equals(20));
        expect(json['isCountdownTimer'], isTrue);
        expect((json['events'] as List).length, equals(1));
        expect(json['homeGoals'], equals(10));
        expect(json['homeBehinds'], equals(5));
        expect(json['awayGoals'], equals(8));
        expect(json['awayBehinds'], equals(12));
      });

      test('should serialise date as ISO8601 string', () {
        final record = GameRecord(
          id: 'game-123',
          date: DateTime(2024, 12, 25, 9, 15, 30, 123),
          homeTeam: 'Home',
          awayTeam: 'Away',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 0,
          homeBehinds: 0,
          awayGoals: 0,
          awayBehinds: 0,
        );

        final json = record.toJson();

        expect(json['date'], contains('2024-12-25'));
        expect(json['date'], contains('09:15:30'));
      });

      test('should serialise nested events correctly', () {
        final record = GameRecord(
          id: 'game-123',
          date: testDate,
          homeTeam: 'Home',
          awayTeam: 'Away',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [
            GameEvent(
              quarter: 2,
              time: const Duration(milliseconds: 90000),
              team: 'Home',
              type: 'behind',
            ),
          ],
          homeGoals: 0,
          homeBehinds: 1,
          awayGoals: 0,
          awayBehinds: 0,
        );

        final json = record.toJson();
        final eventJson =
            (json['events'] as List).first as Map<String, dynamic>;

        expect(eventJson['quarter'], equals(2));
        expect(eventJson['timeMs'], equals(90000));
        expect(eventJson['team'], equals('Home'));
        expect(eventJson['type'], equals('behind'));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = GameRecord(
          id: 'game-roundtrip',
          date: DateTime(2024, 6, 15, 14, 30, 45, 123),
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 25,
          isCountdownTimer: false,
          events: [
            GameEvent(
              quarter: 1,
              time: const Duration(milliseconds: 60000),
              team: 'Richmond',
              type: 'goal',
            ),
            GameEvent(
              quarter: 2,
              time: const Duration(milliseconds: 120000),
              team: 'Carlton',
              type: 'behind',
            ),
            GameEvent(
              quarter: 4,
              time: const Duration(milliseconds: 1200000),
              team: '',
              type: 'clock_end',
            ),
          ],
          homeGoals: 15,
          homeBehinds: 8,
          awayGoals: 12,
          awayBehinds: 10,
        );

        final json = original.toJson();
        final restored = GameRecord.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.homeTeam, equals(original.homeTeam));
        expect(restored.awayTeam, equals(original.awayTeam));
        expect(restored.quarterMinutes, equals(original.quarterMinutes));
        expect(restored.isCountdownTimer, equals(original.isCountdownTimer));
        expect(restored.events.length, equals(original.events.length));
        expect(restored.homeGoals, equals(original.homeGoals));
        expect(restored.homeBehinds, equals(original.homeBehinds));
        expect(restored.awayGoals, equals(original.awayGoals));
        expect(restored.awayBehinds, equals(original.awayBehinds));
        expect(restored.homePoints, equals(original.homePoints));
        expect(restored.awayPoints, equals(original.awayPoints));
      });

      test('should handle empty events list through round-trip', () {
        final original = GameRecord(
          id: 'game-empty',
          date: DateTime(2024),
          homeTeam: 'Home',
          awayTeam: 'Away',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 0,
          homeBehinds: 0,
          awayGoals: 0,
          awayBehinds: 0,
        );

        final json = original.toJson();
        final restored = GameRecord.fromJson(json);

        expect(restored.events, isEmpty);
      });
    });
  });
}
