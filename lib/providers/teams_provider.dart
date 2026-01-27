// manages saved teams with persistence

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/models/score.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamsProvider extends ChangeNotifier {
  TeamsProvider() {
    unawaited(loadTeams());
  }
  List<Team> _teams = [];
  bool _loaded = false;

  List<Team> get teams => _teams;
  List<String> get teamNames => _teams.map((team) => team.name).toList();
  bool get loaded => _loaded;

  Future<void> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsJson = prefs.getStringList('teams');

    if (teamsJson != null) {
      _teams =
          teamsJson
              .map(
                (jsonString) => Team.fromJson(
                  jsonDecode(jsonString) as Map<String, dynamic>,
                ),
              )
              .toList();
    } else {
      // migrate from old format if present
      final teamNames = prefs.getStringList('teamNames') ?? [];
      _teams = teamNames.map((name) => Team(name: name)).toList();
      if (teamNames.isNotEmpty) {
        await _saveTeams();
        await prefs.remove('teamNames');
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
    Address? address,
    String? playHQId,
    String? routingCode,
  }) async {
    final team = Team(
      name: name,
      logoUrl: logoUrl,
      logoUrl32: logoUrl32,
      logoUrl48: logoUrl48,
      logoUrlLarge: logoUrlLarge,
      address: address,
      playHQId: playHQId,
      routingCode: routingCode,
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
    Address? address,
    String? playHQId,
    String? routingCode,
  }) async {
    if (index >= 0 && index < _teams.length) {
      _teams[index] = _teams[index].copyWith(
        name: newName,
        logoUrl: logoUrl,
        logoUrl32: logoUrl32,
        logoUrl48: logoUrl48,
        logoUrlLarge: logoUrlLarge,
        address: address,
        playHQId: playHQId,
        routingCode: routingCode,
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

  Team? findTeamByName(String name) {
    return _teams.cast<Team?>().firstWhere(
      (team) => team?.name == name,
      orElse: () => null,
    );
  }

  bool hasTeamWithName(String name) {
    return _teams.any((team) => team.name == name);
  }
}
