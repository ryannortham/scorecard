// SharedPreferences implementation of TeamRepository

import 'dart:convert';

import 'package:scorecard/models/score.dart';
import 'package:scorecard/repositories/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [TeamRepository].
class SharedPrefsTeamRepository implements TeamRepository {
  static const String _teamsKey = 'teams';
  static const String _legacyTeamNamesKey = 'teamNames';

  @override
  Future<List<Team>> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsJson = prefs.getStringList(_teamsKey);

    if (teamsJson == null) {
      return [];
    }

    return teamsJson
        .map(
          (jsonString) =>
              Team.fromJson(jsonDecode(jsonString) as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> saveTeams(List<Team> teams) async {
    final prefs = await SharedPreferences.getInstance();
    final teamsJson = teams.map((team) => jsonEncode(team.toJson())).toList();
    await prefs.setStringList(_teamsKey, teamsJson);
  }

  @override
  Future<List<String>?> loadLegacyTeamNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_legacyTeamNamesKey);
  }

  @override
  Future<void> removeLegacyTeamNames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTeamNamesKey);
  }
}
