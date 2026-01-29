// Mock data generators for benchmark tests

import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/models/score.dart';

/// Generates a list of mock game summaries for benchmark testing.
///
/// Each game has unique team names and varied scores to simulate
/// realistic list rendering conditions.
List<GameSummary> generateMockGameSummaries(int count) {
  return List.generate(count, (i) {
    final homeGoals = 8 + (i % 10);
    final homeBehinds = 5 + (i % 8);
    final awayGoals = 6 + ((i + 3) % 12);
    final awayBehinds = 4 + ((i + 2) % 9);

    return GameSummary(
      id: 'game_$i',
      date: DateTime.now().subtract(Duration(days: i)),
      homeTeam: 'Home Team ${i + 1}',
      awayTeam: 'Away Team ${i + 1}',
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
    );
  });
}

/// Generates a list of mock teams for benchmark testing.
///
/// Teams have varied configurations to simulate realistic conditions.
List<Team> generateMockTeams(int count) {
  return List.generate(count, (i) {
    return Team(
      name: 'Team ${i + 1}',
      // Alternate between having and not having logos
      logoUrl: i % 3 == 0 ? 'https://example.com/logo_$i.png' : null,
    );
  });
}

/// Generates a map of team names to logo URLs for pre-fetching optimisation.
Map<String, String> generateTeamLogoMap(List<Team> teams) {
  return {
    for (final team in teams) team.name: team.logoUrl ?? '',
  };
}
