// game record analysis extension methods

import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';

/// analysis methods for game records
extension GameRecordAnalysis on GameRecord {
  /// whether the game has completed all quarters
  bool get isComplete {
    if (events.isEmpty) return false;
    return events.any((e) => e.quarter == 4 && e.type == 'clock_end');
  }

  /// gets the current quarter from events
  int get currentQuarter {
    if (events.isEmpty) return 1;
    return events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
  }

  /// whether trophy should show for favourite team win
  bool shouldShowTrophy(UserPreferencesProvider userPrefs) {
    // Game must be complete
    if (!isComplete) return false;

    // Must have favourite teams set
    if (userPrefs.favoriteTeams.isEmpty) return false;

    // Check if there's a winner (no ties)
    if (homePoints == awayPoints) return false;

    final favouriteIsHome = userPrefs.favoriteTeams.contains(homeTeam);
    final favouriteIsAway = userPrefs.favoriteTeams.contains(awayTeam);

    // Favourite team must be playing in this game
    if (!favouriteIsHome && !favouriteIsAway) return false;

    // Check if any favourite team won
    if (favouriteIsHome && homePoints > awayPoints) return true;
    if (favouriteIsAway && awayPoints > homePoints) return true;

    return false;
  }

  /// calculates running totals for a team up to a specific quarter
  Map<String, int> calculateRunningTotals(
    String teamName,
    int upToQuarter, [
    List<GameEvent>? eventsList,
  ]) {
    final effectiveEvents = eventsList ?? events;
    var goals = 0;
    var behinds = 0;

    for (var q = 1; q <= upToQuarter; q++) {
      final quarterEvents =
          effectiveEvents
              .where((event) => event.quarter == q && event.team == teamName)
              .toList();

      for (final event in quarterEvents) {
        if (event.type == 'goal') {
          goals++;
        } else if (event.type == 'behind') {
          behinds++;
        }
      }
    }

    return {
      'goals': goals,
      'behinds': behinds,
      'points': (goals * 6) + behinds,
    };
  }

  /// gets events for a specific quarter and team
  Map<String, List<GameEvent>> getEventsByQuarter(
    String teamName,
    int quarter, [
    List<GameEvent>? eventsList,
  ]) {
    final effectiveEvents = eventsList ?? events;
    final quarterEvents =
        effectiveEvents
            .where(
              (event) => event.quarter == quarter && event.team == teamName,
            )
            .toList();
    return {'team': quarterEvents};
  }

  /// builds title string for in-progress games
  String get inProgressTitle {
    // Find the current quarter from events
    var currentQ = 1;
    if (events.isNotEmpty) {
      // Get the highest quarter with events, but not if it has a clock_end
      final activeQuarters =
          events
              .where((e) => e.type != 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      final endedQuarters =
          events
              .where((e) => e.type == 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      if (activeQuarters.isNotEmpty) {
        currentQ = activeQuarters.reduce((a, b) => a > b ? a : b);
        // If this quarter has ended, we're in the next quarter
        if (endedQuarters.contains(currentQ) && currentQ < 4) {
          currentQ++;
        }
      }
    }

    // Calculate elapsed time in current quarter
    var elapsedTime = Duration.zero;
    if (events.isNotEmpty) {
      // Find the latest timer events for the current quarter
      final quarterEvents = events.where((e) => e.quarter == currentQ).toList();

      if (quarterEvents.isNotEmpty) {
        // Find the last timer event (clock_start, clock_pause, etc.)
        final timerEvents =
            quarterEvents.where((e) => e.type.startsWith('clock_')).toList();

        if (timerEvents.isNotEmpty) {
          // Use the time from the latest event as the current elapsed time
          elapsedTime = timerEvents.last.time;
        }
      }
    }

    // Format the time similar to how it's done in the timer display
    final totalMinutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;
    final minutesStr = totalMinutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    final timeStr = '$minutesStr:$secondsStr';

    return 'In Progress: Q$currentQ $timeStr';
  }
}
