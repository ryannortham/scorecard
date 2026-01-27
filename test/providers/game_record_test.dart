// Tests for GameEvent and GameRecord models

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/providers/game_record.dart';

void main() {
  group('GameEvent', () {
    group('constructor', () {
      test('should create goal event', () {
        final event = GameEvent(
          quarter: 2,
          time: const Duration(minutes: 15, seconds: 30),
          team: 'Richmond',
          type: 'goal',
        );

        expect(event.quarter, equals(2));
        expect(event.time.inMilliseconds, equals(930000));
        expect(event.team, equals('Richmond'));
        expect(event.type, equals('goal'));
      });

      test('should create behind event', () {
        final event = GameEvent(
          quarter: 1,
          time: const Duration(minutes: 5),
          team: 'Carlton',
          type: 'behind',
        );

        expect(event.type, equals('behind'));
      });

      test('should create clock_start event with empty team', () {
        final event = GameEvent(
          quarter: 1,
          time: Duration.zero,
          team: '',
          type: 'clock_start',
        );

        expect(event.type, equals('clock_start'));
        expect(event.team, isEmpty);
      });

      test('should create clock_end event', () {
        final event = GameEvent(
          quarter: 3,
          time: const Duration(minutes: 20),
          team: '',
          type: 'clock_end',
        );

        expect(event.type, equals('clock_end'));
        expect(event.quarter, equals(3));
      });

      test('should create clock_pause event', () {
        final event = GameEvent(
          quarter: 2,
          time: const Duration(minutes: 10, seconds: 45),
          team: '',
          type: 'clock_pause',
        );

        expect(event.type, equals('clock_pause'));
      });
    });

    group('toJson', () {
      test('should serialise goal event correctly', () {
        final event = GameEvent(
          quarter: 2,
          time: const Duration(minutes: 15, seconds: 30),
          team: 'Richmond',
          type: 'goal',
        );

        final json = event.toJson();

        expect(json['quarter'], equals(2));
        expect(json['timeMs'], equals(930000));
        expect(json['team'], equals('Richmond'));
        expect(json['type'], equals('goal'));
      });

      test('should serialise clock event with empty team', () {
        final event = GameEvent(
          quarter: 1,
          time: Duration.zero,
          team: '',
          type: 'clock_start',
        );

        final json = event.toJson();

        expect(json['team'], equals(''));
        expect(json['type'], equals('clock_start'));
      });
    });

    group('fromJson', () {
      test('should deserialise goal event', () {
        final json = {
          'quarter': 3,
          'timeMs': 600000,
          'team': 'Collingwood',
          'type': 'goal',
        };

        final event = GameEvent.fromJson(json);

        expect(event.quarter, equals(3));
        expect(event.time, equals(const Duration(minutes: 10)));
        expect(event.team, equals('Collingwood'));
        expect(event.type, equals('goal'));
      });

      test('should deserialise clock event', () {
        final json = {
          'quarter': 4,
          'timeMs': 1200000,
          'team': '',
          'type': 'clock_end',
        };

        final event = GameEvent.fromJson(json);

        expect(event.quarter, equals(4));
        expect(event.time, equals(const Duration(minutes: 20)));
        expect(event.team, isEmpty);
        expect(event.type, equals('clock_end'));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = GameEvent(
          quarter: 2,
          time: const Duration(minutes: 12, seconds: 45),
          team: 'Essendon',
          type: 'behind',
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
    group('constructor', () {
      test('should create game record with all fields', () {
        final record = GameRecord(
          id: 'game-123',
          date: DateTime(2024, 3, 15, 14, 30),
          homeTeam: 'Richmond',
          awayTeam: 'Carlton',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 12,
          homeBehinds: 8,
          awayGoals: 10,
          awayBehinds: 12,
        );

        expect(record.id, equals('game-123'));
        expect(record.date, equals(DateTime(2024, 3, 15, 14, 30)));
        expect(record.homeTeam, equals('Richmond'));
        expect(record.awayTeam, equals('Carlton'));
        expect(record.quarterMinutes, equals(20));
        expect(record.isCountdownTimer, isTrue);
        expect(record.events, isEmpty);
        expect(record.homeGoals, equals(12));
        expect(record.homeBehinds, equals(8));
        expect(record.awayGoals, equals(10));
        expect(record.awayBehinds, equals(12));
      });
    });

    group('homePoints', () {
      test('should calculate home points correctly', () {
        final record = GameRecord(
          id: 'game-1',
          date: DateTime.now(),
          homeTeam: 'Home',
          awayTeam: 'Away',
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

      test('should return 0 for no scores', () {
        final record = GameRecord(
          id: 'game-1',
          date: DateTime.now(),
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

        expect(record.homePoints, equals(0));
      });
    });

    group('awayPoints', () {
      test('should calculate away points correctly', () {
        final record = GameRecord(
          id: 'game-1',
          date: DateTime.now(),
          homeTeam: 'Home',
          awayTeam: 'Away',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [],
          homeGoals: 0,
          homeBehinds: 0,
          awayGoals: 8,
          awayBehinds: 10,
        );

        expect(record.awayPoints, equals(58)); // 8 * 6 + 10
      });
    });

    group('toJson', () {
      test('should serialise all fields correctly', () {
        final record = GameRecord(
          id: 'game-456',
          date: DateTime(2024, 6, 1, 19, 40),
          homeTeam: 'Geelong',
          awayTeam: 'Hawthorn',
          quarterMinutes: 25,
          isCountdownTimer: false,
          events: [
            GameEvent(
              quarter: 1,
              time: const Duration(minutes: 5),
              team: 'Geelong',
              type: 'goal',
            ),
          ],
          homeGoals: 15,
          homeBehinds: 10,
          awayGoals: 12,
          awayBehinds: 8,
        );

        final json = record.toJson();

        expect(json['id'], equals('game-456'));
        expect(json['date'], equals('2024-06-01T19:40:00.000'));
        expect(json['homeTeam'], equals('Geelong'));
        expect(json['awayTeam'], equals('Hawthorn'));
        expect(json['quarterMinutes'], equals(25));
        expect(json['isCountdownTimer'], isFalse);
        expect((json['events'] as List).length, equals(1));
        expect(json['homeGoals'], equals(15));
        expect(json['homeBehinds'], equals(10));
        expect(json['awayGoals'], equals(12));
        expect(json['awayBehinds'], equals(8));
      });

      test('should serialise events array', () {
        final record = GameRecord(
          id: 'game-1',
          date: DateTime(2024, 1, 1),
          homeTeam: 'Home',
          awayTeam: 'Away',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [
            GameEvent(
              quarter: 1,
              time: const Duration(minutes: 5),
              team: 'Home',
              type: 'goal',
            ),
            GameEvent(
              quarter: 1,
              time: const Duration(minutes: 10),
              team: 'Away',
              type: 'behind',
            ),
          ],
          homeGoals: 1,
          homeBehinds: 0,
          awayGoals: 0,
          awayBehinds: 1,
        );

        final json = record.toJson();
        final events = json['events'] as List;

        expect(events.length, equals(2));
        expect(events[0]['type'], equals('goal'));
        expect(events[1]['type'], equals('behind'));
      });
    });

    group('fromJson', () {
      test('should deserialise all fields correctly', () {
        final json = {
          'id': 'game-789',
          'date': '2024-07-15T18:00:00.000',
          'homeTeam': 'Sydney',
          'awayTeam': 'GWS',
          'quarterMinutes': 20,
          'isCountdownTimer': true,
          'events': <Map<String, dynamic>>[],
          'homeGoals': 11,
          'homeBehinds': 7,
          'awayGoals': 9,
          'awayBehinds': 11,
        };

        final record = GameRecord.fromJson(json);

        expect(record.id, equals('game-789'));
        expect(record.date, equals(DateTime(2024, 7, 15, 18, 0)));
        expect(record.homeTeam, equals('Sydney'));
        expect(record.awayTeam, equals('GWS'));
        expect(record.quarterMinutes, equals(20));
        expect(record.isCountdownTimer, isTrue);
        expect(record.events, isEmpty);
        expect(record.homeGoals, equals(11));
        expect(record.homeBehinds, equals(7));
        expect(record.awayGoals, equals(9));
        expect(record.awayBehinds, equals(11));
      });

      test('should deserialise events array', () {
        final json = {
          'id': 'game-1',
          'date': '2024-01-01T00:00:00.000',
          'homeTeam': 'Home',
          'awayTeam': 'Away',
          'quarterMinutes': 20,
          'isCountdownTimer': true,
          'events': [
            {'quarter': 2, 'timeMs': 300000, 'team': 'Home', 'type': 'goal'},
            {'quarter': 2, 'timeMs': 600000, 'team': 'Away', 'type': 'behind'},
          ],
          'homeGoals': 1,
          'homeBehinds': 0,
          'awayGoals': 0,
          'awayBehinds': 1,
        };

        final record = GameRecord.fromJson(json);

        expect(record.events.length, equals(2));
        expect(record.events[0].quarter, equals(2));
        expect(record.events[0].type, equals('goal'));
        expect(record.events[1].type, equals('behind'));
      });
    });

    group('round-trip serialisation', () {
      test('should preserve all data through JSON round-trip', () {
        final original = GameRecord(
          id: 'roundtrip-game',
          date: DateTime(2024, 5, 20, 15, 30),
          homeTeam: 'Melbourne',
          awayTeam: 'Brisbane',
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: [
            GameEvent(
              quarter: 1,
              time: const Duration(minutes: 5),
              team: 'Melbourne',
              type: 'goal',
            ),
            GameEvent(
              quarter: 2,
              time: const Duration(minutes: 10),
              team: 'Brisbane',
              type: 'behind',
            ),
          ],
          homeGoals: 14,
          homeBehinds: 9,
          awayGoals: 13,
          awayBehinds: 11,
        );

        final json = original.toJson();
        final restored = GameRecord.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.date, equals(original.date));
        expect(restored.homeTeam, equals(original.homeTeam));
        expect(restored.awayTeam, equals(original.awayTeam));
        expect(restored.quarterMinutes, equals(original.quarterMinutes));
        expect(restored.isCountdownTimer, equals(original.isCountdownTimer));
        expect(restored.events.length, equals(original.events.length));
        expect(restored.homeGoals, equals(original.homeGoals));
        expect(restored.homeBehinds, equals(original.homeBehinds));
        expect(restored.awayGoals, equals(original.awayGoals));
        expect(restored.awayBehinds, equals(original.awayBehinds));
      });
    });
  });
}
