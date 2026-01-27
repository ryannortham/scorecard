// tests for game state service - quarter navigation and state management

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';

void main() {
  group('GameViewModel', () {
    late GameViewModel service;

    setUp(() {
      service =
          GameViewModel()..configureGame(
            homeTeam: 'Richmond',
            awayTeam: 'Carlton',
            gameDate: DateTime(2026, 1, 27),
            quarterMinutes: 15,
            isCountdownTimer: true,
          );
    });

    group('goToPreviousQuarter', () {
      group('basic navigation', () {
        test('should return false when in Q1', () {
          expect(service.selectedQuarter, 1);

          final result = service.goToPreviousQuarter();

          expect(result, false);
          expect(service.selectedQuarter, 1);
        });

        test('should return true and move to previous quarter from Q2', () {
          service.setSelectedQuarter(2);
          expect(service.selectedQuarter, 2);

          final result = service.goToPreviousQuarter();

          expect(result, true);
          expect(service.selectedQuarter, 1);
        });

        test('should return true and move to previous quarter from Q3', () {
          service.setSelectedQuarter(3);

          final result = service.goToPreviousQuarter();

          expect(result, true);
          expect(service.selectedQuarter, 2);
        });

        test('should return true and move to previous quarter from Q4', () {
          service.setSelectedQuarter(4);

          final result = service.goToPreviousQuarter();

          expect(result, true);
          expect(service.selectedQuarter, 3);
        });

        test('should navigate back multiple times until Q1', () {
          service.setSelectedQuarter(4);

          expect(service.goToPreviousQuarter(), true);
          expect(service.selectedQuarter, 3);

          expect(service.goToPreviousQuarter(), true);
          expect(service.selectedQuarter, 2);

          expect(service.goToPreviousQuarter(), true);
          expect(service.selectedQuarter, 1);

          expect(service.goToPreviousQuarter(), false);
          expect(service.selectedQuarter, 1);
        });
      });

      group('clock_end event removal', () {
        test('should remove clock_end event for target quarter', () {
          // Simulate ending Q1 and advancing to Q2
          service
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2);

          // Verify clock_end exists
          expect(
            service.gameEvents.any(
              (e) => e.quarter == 1 && e.type == 'clock_end',
            ),
            true,
          );

          // Go back to Q1
          service.goToPreviousQuarter();

          // clock_end for Q1 should be removed
          expect(
            service.gameEvents.any(
              (e) => e.quarter == 1 && e.type == 'clock_end',
            ),
            false,
          );
        });

        test('should not remove clock_end for other quarters', () {
          // End Q1 and Q2, advance to Q3
          service
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..recordQuarterEnd(2)
            ..setSelectedQuarter(3);

          // Verify both clock_end events exist
          expect(
            service.gameEvents.where((e) => e.type == 'clock_end').length,
            2,
          );

          // Go back to Q2
          service.goToPreviousQuarter();

          // Only Q2's clock_end should be removed, Q1's should remain
          expect(
            service.gameEvents.any(
              (e) => e.quarter == 1 && e.type == 'clock_end',
            ),
            true,
          );
          expect(
            service.gameEvents.any(
              (e) => e.quarter == 2 && e.type == 'clock_end',
            ),
            false,
          );
        });

        test('should handle missing clock_end gracefully', () {
          // Set quarter to 2 without recording clock_end for Q1
          service.setSelectedQuarter(2);

          // Should not throw, should still navigate
          expect(() => service.goToPreviousQuarter(), returnsNormally);
          expect(service.selectedQuarter, 1);
        });
      });

      group('timer restoration (countdown mode)', () {
        test('should restore timer to quarter end time', () {
          // Configure countdown timer (15 min = 900000 ms)
          // Simulate running timer for 5 minutes (300000 ms elapsed)
          // In countdown: timerRawTime = 900000 - 300000 = 600000
          service
            ..configureTimer(
              isCountdownMode: true,
              quarterMaxTime: 15 * 60 * 1000,
            )
            ..setTimerRawTime(600000)
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..resetTimer();

          // Timer should now be at full 15 minutes (Q2 start)
          expect(service.timerRawTime, 900000);

          // Go back to Q1
          service.goToPreviousQuarter();

          // Timer should be restored to 600000 (where Q1 ended)
          expect(service.timerRawTime, 600000);
        });

        test('should fall back to full quarter when no clock_end', () {
          // Set to Q2 without ending Q1 properly
          service
            ..configureTimer(
              isCountdownMode: true,
              quarterMaxTime: 15 * 60 * 1000,
            )
            ..setSelectedQuarter(2)
            ..setTimerRawTime(500000)
            ..goToPreviousQuarter();

          // Should reset to full quarter time
          expect(service.timerRawTime, 900000);
        });
      });

      group('timer restoration (count-up mode)', () {
        test('should restore timer to quarter end time in count-up mode', () {
          // Configure count-up timer
          // Simulate running timer for 5 minutes (300000 ms elapsed)
          // In count-up: timerRawTime = 300000
          service
            ..configureTimer(
              isCountdownMode: false,
              quarterMaxTime: 15 * 60 * 1000,
            )
            ..setTimerRawTime(300000)
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..resetTimer();

          // Timer should now be at 0 (Q2 start in count-up)
          expect(service.timerRawTime, 0);

          // Go back to Q1
          service.goToPreviousQuarter();

          // Timer should be restored to 300000 (where Q1 ended)
          expect(service.timerRawTime, 300000);
        });
      });

      group('state management', () {
        test('should stop timer if running', () {
          service
            ..setSelectedQuarter(2)
            ..setTimerRunning(isRunning: true);
          expect(service.isTimerRunning, true);

          service.goToPreviousQuarter();

          expect(service.isTimerRunning, false);
        });

        test('should preserve scoring events when going back', () {
          // Add some goals in Q1
          service
            ..updateScore(isHomeTeam: true, isGoal: true, newCount: 1)
            ..updateScore(isHomeTeam: true, isGoal: true, newCount: 2)
            ..updateScore(isHomeTeam: false, isGoal: false, newCount: 1);

          final eventCountBefore =
              service.gameEvents.where((e) => e.type != 'clock_end').length;

          // End Q1, go to Q2
          service
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..goToPreviousQuarter();

          // Scoring events should still be there
          final eventCountAfter =
              service.gameEvents.where((e) => e.type != 'clock_end').length;
          expect(eventCountAfter, eventCountBefore);

          // Scores should be preserved
          expect(service.homeGoals, 2);
          expect(service.awayBehinds, 1);
        });

        test('should notify listeners when going back', () {
          service.setSelectedQuarter(2);

          var notified = false;
          service
            ..addListener(() {
              notified = true;
            })
            ..goToPreviousQuarter();

          expect(notified, true);
        });
      });

      group('full round-trip scenario', () {
        test('should allow going back, making corrections, and returning', () {
          // Q1: Score some goals, end Q1
          // Q2: Score more, end Q2
          service
            ..updateScore(isHomeTeam: true, isGoal: true, newCount: 1)
            ..updateScore(isHomeTeam: true, isGoal: true, newCount: 2)
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..resetTimer()
            ..updateScore(isHomeTeam: false, isGoal: true, newCount: 1)
            ..recordQuarterEnd(2)
            ..setSelectedQuarter(3)
            ..resetTimer()
            // Realise mistake in Q1 - need to go back
            ..goToPreviousQuarter() // Now in Q2
            ..goToPreviousQuarter(); // Now in Q1

          expect(service.selectedQuarter, 1);

          // Make correction - add a behind that was missed
          // Re-end Q1 and return to Q2
          // Q2's clock_end was also removed, need to re-record it
          service
            ..updateScore(isHomeTeam: true, isGoal: false, newCount: 1)
            ..recordQuarterEnd(1)
            ..setSelectedQuarter(2)
            ..recordQuarterEnd(2)
            ..setSelectedQuarter(3);

          expect(service.selectedQuarter, 3);
          expect(service.homeGoals, 2);
          expect(service.homeBehinds, 1);
          expect(service.awayGoals, 1);
        });
      });
    });
  });
}
