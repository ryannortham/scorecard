// tests for game record extension methods

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/extensions/game_record_extensions.dart';
import 'package:scorecard/providers/game_record_provider.dart';

void main() {
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

  /// helper to create a game record with specified events
  GameRecord createGameRecord({
    List<GameEvent>? events,
    int homeGoals = 0,
    int homeBehinds = 0,
    int awayGoals = 0,
    int awayBehinds = 0,
    String homeTeam = 'Richmond',
    String awayTeam = 'Carlton',
  }) {
    return GameRecord(
      id: 'test-game',
      date: DateTime(2024, 6, 15),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      quarterMinutes: 20,
      isCountdownTimer: true,
      events: events ?? [],
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
    );
  }

  group('GameRecordAnalysis.isComplete', () {
    test('should return false for empty events', () {
      final record = createGameRecord(events: []);

      expect(record.isComplete, isFalse);
    });

    test('should return false when only Q1-Q3 have events', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
          createEvent(quarter: 2, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 2, timeMs: 1200000, team: '', type: 'clock_end'),
          createEvent(quarter: 3, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 3, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
      );

      expect(record.isComplete, isFalse);
    });

    test('should return false when Q4 has events but no clock_end', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 4, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 4,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      expect(record.isComplete, isFalse);
    });

    test('should return true when Q4 has clock_end event', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 4, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 4, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
      );

      expect(record.isComplete, isTrue);
    });

    test('should return true when game is complete with full events', () {
      final record = createGameRecord(
        events: [
          // Q1
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
          // Q2
          createEvent(quarter: 2, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 2, timeMs: 1200000, team: '', type: 'clock_end'),
          // Q3
          createEvent(quarter: 3, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 3, timeMs: 1200000, team: '', type: 'clock_end'),
          // Q4
          createEvent(quarter: 4, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 4, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
        homeGoals: 10,
        homeBehinds: 5,
      );

      expect(record.isComplete, isTrue);
    });
  });

  group('GameRecordAnalysis.currentQuarter', () {
    test('should return 1 for empty events', () {
      final record = createGameRecord(events: []);

      expect(record.currentQuarter, equals(1));
    });

    test('should return 1 when events only in Q1', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      expect(record.currentQuarter, equals(1));
    });

    test('should return highest quarter from events', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(quarter: 2, timeMs: 60000, team: 'Carlton', type: 'goal'),
          createEvent(
            quarter: 3,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      expect(record.currentQuarter, equals(3));
    });

    test('should return 4 when Q4 has events', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(quarter: 4, timeMs: 0, team: '', type: 'clock_start'),
        ],
      );

      expect(record.currentQuarter, equals(4));
    });
  });

  group('GameRecordAnalysis.calculateRunningTotals', () {
    test('should return zeros for empty events', () {
      final record = createGameRecord(events: []);

      final totals = record.calculateRunningTotals('Richmond', 1);

      expect(totals['goals'], equals(0));
      expect(totals['behinds'], equals(0));
      expect(totals['points'], equals(0));
    });

    test('should calculate Q1 totals correctly', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: 'Richmond',
            type: 'behind',
          ),
          createEvent(
            quarter: 1,
            timeMs: 180000,
            team: 'Carlton',
            type: 'goal',
          ),
        ],
      );

      final richmondTotals = record.calculateRunningTotals('Richmond', 1);

      expect(richmondTotals['goals'], equals(1));
      expect(richmondTotals['behinds'], equals(1));
      expect(richmondTotals['points'], equals(7)); // 1*6 + 1
    });

    test('should exclude events from other teams', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: 'Carlton',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 180000,
            team: 'Carlton',
            type: 'goal',
          ),
        ],
      );

      final richmondTotals = record.calculateRunningTotals('Richmond', 1);
      final carltonTotals = record.calculateRunningTotals('Carlton', 1);

      expect(richmondTotals['goals'], equals(1));
      expect(carltonTotals['goals'], equals(2));
    });

    test('should accumulate totals across quarters', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 2,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 3,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      final q1Totals = record.calculateRunningTotals('Richmond', 1);
      final q2Totals = record.calculateRunningTotals('Richmond', 2);
      final q3Totals = record.calculateRunningTotals('Richmond', 3);

      expect(q1Totals['goals'], equals(1));
      expect(q2Totals['goals'], equals(2));
      expect(q3Totals['goals'], equals(3));
    });

    test('should only include events up to specified quarter', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 2,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 3,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 4,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      final q2Totals = record.calculateRunningTotals('Richmond', 2);

      expect(q2Totals['goals'], equals(2)); // Only Q1 + Q2
    });

    test('should ignore clock events', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: '',
            type: 'clock_pause',
          ),
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
      );

      final totals = record.calculateRunningTotals('Richmond', 1);

      expect(totals['goals'], equals(1));
    });

    test('should use provided eventsList when specified', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      // Override with different events
      final customEvents = [
        createEvent(quarter: 1, timeMs: 60000, team: 'Richmond', type: 'goal'),
        createEvent(quarter: 1, timeMs: 120000, team: 'Richmond', type: 'goal'),
      ];

      final totals = record.calculateRunningTotals('Richmond', 1, customEvents);

      expect(totals['goals'], equals(2)); // Uses custom events
    });
  });

  group('GameRecordAnalysis.getEventsByQuarter', () {
    test('should return events for specified quarter and team', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 120000,
            team: 'Richmond',
            type: 'behind',
          ),
          createEvent(
            quarter: 2,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
          createEvent(
            quarter: 1,
            timeMs: 180000,
            team: 'Carlton',
            type: 'goal',
          ),
        ],
      );

      final result = record.getEventsByQuarter('Richmond', 1);

      expect(result['team']!.length, equals(2));
      expect(result['team']![0].type, equals('goal'));
      expect(result['team']![1].type, equals('behind'));
    });

    test('should return empty list when no matching events', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 60000,
            team: 'Richmond',
            type: 'goal',
          ),
        ],
      );

      final result = record.getEventsByQuarter('Carlton', 2);

      expect(result['team'], isEmpty);
    });

    test('should use provided eventsList when specified', () {
      final record = createGameRecord(events: []);

      final customEvents = [
        createEvent(quarter: 1, timeMs: 60000, team: 'Richmond', type: 'goal'),
        createEvent(quarter: 1, timeMs: 120000, team: 'Richmond', type: 'goal'),
      ];

      final result = record.getEventsByQuarter('Richmond', 1, customEvents);

      expect(result['team']!.length, equals(2));
    });
  });

  group('GameRecordAnalysis.inProgressTitle', () {
    test('should return "In Progress: Q1 00:00" for empty events', () {
      final record = createGameRecord(events: []);

      expect(record.inProgressTitle, equals('In Progress: Q1 00:00'));
    });

    test('should show correct quarter and time for Q1 in progress', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 1,
            timeMs: 330000,
            team: '',
            type: 'clock_pause',
          ),
        ],
      );

      expect(record.inProgressTitle, equals('In Progress: Q1 05:30'));
    });

    test('should show Q2 when Q1 has ended', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
      );

      // Q1 ended, should show Q2 with 00:00
      expect(record.inProgressTitle, equals('In Progress: Q2 00:00'));
    });

    test('should show correct time when Q2 is in progress', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 1, timeMs: 1200000, team: '', type: 'clock_end'),
          createEvent(quarter: 2, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(
            quarter: 2,
            timeMs: 600000,
            team: '',
            type: 'clock_pause',
          ),
        ],
      );

      expect(record.inProgressTitle, equals('In Progress: Q2 10:00'));
    });

    test('should format minutes with leading zero', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 30000, // 30 seconds
            team: '',
            type: 'clock_pause',
          ),
        ],
      );

      expect(record.inProgressTitle, equals('In Progress: Q1 00:30'));
    });

    test('should format seconds with leading zero', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 65000, // 1 minute 5 seconds
            team: '',
            type: 'clock_pause',
          ),
        ],
      );

      expect(record.inProgressTitle, equals('In Progress: Q1 01:05'));
    });

    test('should handle double-digit minutes', () {
      final record = createGameRecord(
        events: [
          createEvent(
            quarter: 1,
            timeMs: 900000, // 15 minutes
            team: '',
            type: 'clock_pause',
          ),
        ],
      );

      expect(record.inProgressTitle, equals('In Progress: Q1 15:00'));
    });

    test('should not increment quarter beyond Q4', () {
      final record = createGameRecord(
        events: [
          createEvent(quarter: 4, timeMs: 0, team: '', type: 'clock_start'),
          createEvent(quarter: 4, timeMs: 1200000, team: '', type: 'clock_end'),
        ],
      );

      // Q4 ended - this is actually a complete game, but if called
      // the title should still show Q4
      expect(record.inProgressTitle, contains('Q4'));
    });
  });

  // Note: shouldShowTrophy tests require mocking UserPreferencesProvider
  // which depends on SharedPreferences. These would be better as integration
  // tests or with a proper mocking framework like mocktail.
  //
  // The logic tested includes:
  // - Game must be complete (Q4 clock_end present)
  // - Must have favourite teams set
  // - No ties allowed (homePoints != awayPoints)
  // - Favourite team must be playing
  // - Favourite team must have won
}
