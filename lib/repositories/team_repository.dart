// abstract interface for team persistence operations

import 'package:scorecard/models/score.dart';

/// Repository interface for team data persistence.
///
/// Abstracts storage implementation to enable testing and
/// potential future storage backends.
abstract class TeamRepository {
  /// Loads all saved teams.
  Future<List<Team>> loadTeams();

  /// Saves the complete list of teams, replacing any existing data.
  Future<void> saveTeams(List<Team> teams);

  /// Loads legacy team names for migration (pre-Team object format).
  /// Returns null if no legacy data exists.
  Future<List<String>?> loadLegacyTeamNames();

  /// Removes legacy team names after migration.
  Future<void> removeLegacyTeamNames();
}
