import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';

/// Service for analyzing game data and providing computed properties
class GameAnalysisService {
  /// Determines if the game is complete based on timer events
  static bool isGameComplete(GameRecord game) {
    if (game.events.isEmpty) return false;
    return game.events.any((e) => e.quarter == 4 && e.type == 'clock_end');
  }

  /// Gets the current quarter based on the latest events
  static int getCurrentQuarter(GameRecord game) {
    if (game.events.isEmpty) return 1;
    return game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
  }

  /// Determines if the trophy icon should be shown (game complete and favorite team won)
  static bool shouldShowTrophyIcon(
    GameRecord game,
    UserPreferencesProvider userPrefs,
  ) {
    // Game must be complete
    if (!isGameComplete(game)) return false;

    // Must have a favorite team set
    if (userPrefs.favoriteTeam.isEmpty) return false;

    // Check if favorite team won
    final homePoints = game.homePoints;
    final awayPoints = game.awayPoints;

    if (homePoints == awayPoints) return false; // No winner in a tie

    final favoriteIsHome = game.homeTeam == userPrefs.favoriteTeam;
    final favoriteIsAway = game.awayTeam == userPrefs.favoriteTeam;

    // Favorite team must be playing in this game
    if (!favoriteIsHome && !favoriteIsAway) return false;

    // Check if favorite team won
    if (favoriteIsHome && homePoints > awayPoints) return true;
    if (favoriteIsAway && awayPoints > homePoints) return true;

    return false;
  }

  /// Calculates running totals for a team up to a specific quarter
  static Map<String, int> calculateRunningTotals(
    List<GameEvent> events,
    String teamName,
    int upToQuarter,
  ) {
    int goals = 0;
    int behinds = 0;

    for (int q = 1; q <= upToQuarter; q++) {
      final quarterEvents =
          events
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

  /// Gets events for a specific quarter and team
  static Map<String, List<GameEvent>> getEventsByQuarter(
    List<GameEvent> events,
    String teamName,
    int quarter,
  ) {
    final quarterEvents =
        events
            .where(
              (event) => event.quarter == quarter && event.team == teamName,
            )
            .toList();
    return {'team': quarterEvents};
  }

  /// Builds the title for in-progress games using static game data
  static String buildStaticGameTitle(GameRecord game) {
    // Find the current quarter from events
    int currentQuarter = 1;
    if (game.events.isNotEmpty) {
      // Get the highest quarter with events, but not if it has a clock_end
      final activeQuarters =
          game.events
              .where((e) => e.type != 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      final endedQuarters =
          game.events
              .where((e) => e.type == 'clock_end')
              .map((e) => e.quarter)
              .toSet();

      if (activeQuarters.isNotEmpty) {
        currentQuarter = activeQuarters.reduce((a, b) => a > b ? a : b);
        // If this quarter has ended, we're in the next quarter
        if (endedQuarters.contains(currentQuarter) && currentQuarter < 4) {
          currentQuarter++;
        }
      }
    }

    // Calculate elapsed time in current quarter
    Duration elapsedTime = Duration.zero;
    if (game.events.isNotEmpty) {
      // Find the latest timer events for the current quarter
      final quarterEvents =
          game.events.where((e) => e.quarter == currentQuarter).toList();

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
    final timeStr =
        '${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return 'In Progress: Q$currentQuarter $timeStr';
  }
}
