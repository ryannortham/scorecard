// mock implementation of TeamRepository for testing

import 'package:scorecard/models/score.dart';
import 'package:scorecard/repositories/team_repository.dart';

/// In-memory mock implementation of [TeamRepository] for testing.
class MockTeamRepository implements TeamRepository {
  MockTeamRepository({
    List<Team>? initialTeams,
    List<String>? legacyTeamNames,
  }) : _teams = initialTeams ?? [],
       _legacyTeamNames = legacyTeamNames;

  List<Team> _teams;
  List<String>? _legacyTeamNames;

  /// Tracks all save operations for verification in tests.
  final List<List<Team>> saveHistory = [];

  /// Number of times loadTeams was called.
  int loadTeamsCallCount = 0;

  @override
  Future<List<Team>> loadTeams() async {
    loadTeamsCallCount++;
    return List<Team>.from(_teams);
  }

  @override
  Future<void> saveTeams(List<Team> teams) async {
    _teams = List<Team>.from(teams);
    saveHistory.add(List<Team>.from(teams));
  }

  @override
  Future<List<String>?> loadLegacyTeamNames() async {
    return _legacyTeamNames;
  }

  @override
  Future<void> removeLegacyTeamNames() async {
    _legacyTeamNames = null;
  }

  /// Returns the current teams (for test verification).
  List<Team> get currentTeams => List<Team>.from(_teams);
}
