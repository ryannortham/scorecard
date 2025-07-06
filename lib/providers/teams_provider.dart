import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorecard/models/score_models.dart';

class TeamsProvider extends ChangeNotifier {
  List<Team> _teams = [];
  bool _loaded = false;

  List<Team> get teams => _teams;
  List<String> get teamNames => _teams.map((team) => team.name).toList();
  bool get loaded => _loaded;

  TeamsProvider() {
    loadTeams();
  }

  Future<void> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to load new format (teams with logos)
    final teamsJson = prefs.getStringList('teams');
    if (teamsJson != null) {
      _teams =
          teamsJson
              .map((jsonString) => Team.fromJson(jsonDecode(jsonString)))
              .toList();
    } else {
      // Fallback to old format (just team names) for backward compatibility
      final teamNames = prefs.getStringList('teamNames') ?? [];
      _teams = teamNames.map((name) => Team(name: name)).toList();
      // Migrate to new format
      if (teamNames.isNotEmpty) {
        await _saveTeams();
        await prefs.remove('teamNames'); // Clean up old format
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsJson = _teams.map((team) => jsonEncode(team.toJson())).toList();
    await prefs.setStringList('teams', teamsJson);
  }

  Future<void> addTeam(
    String name, {
    String? logoUrl,
    String? logoUrl32,
    String? logoUrl48,
    String? logoUrlLarge,
  }) async {
    final team = Team(
      name: name,
      logoUrl: logoUrl,
      logoUrl32: logoUrl32,
      logoUrl48: logoUrl48,
      logoUrlLarge: logoUrlLarge,
    );
    _teams.add(team);
    await _saveTeams();
    notifyListeners();
  }

  Future<void> editTeam(
    int index,
    String newName, {
    String? logoUrl,
    String? logoUrl32,
    String? logoUrl48,
    String? logoUrlLarge,
  }) async {
    if (index >= 0 && index < _teams.length) {
      _teams[index] = _teams[index].copyWith(
        name: newName,
        logoUrl: logoUrl,
        logoUrl32: logoUrl32,
        logoUrl48: logoUrl48,
        logoUrlLarge: logoUrlLarge,
      );
      await _saveTeams();
      notifyListeners();
    }
  }

  Future<void> deleteTeam(int index) async {
    if (index >= 0 && index < _teams.length) {
      _teams.removeAt(index);
      await _saveTeams();
      notifyListeners();
    }
  }

  /// Find team by name
  Team? findTeamByName(String name) {
    try {
      return _teams.firstWhere((team) => team.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Check if team name already exists
  bool hasTeamWithName(String name) {
    return _teams.any((team) => team.name == name);
  }
}
