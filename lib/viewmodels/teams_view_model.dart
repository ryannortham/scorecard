// manages saved teams with persistence

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/repositories/shared_prefs_team_repository.dart';
import 'package:scorecard/repositories/team_repository.dart';

/// Manages team data with persistence via [TeamRepository].
class TeamsViewModel extends ChangeNotifier {
  /// Creates a TeamsViewModel with an optional [TeamRepository].
  ///
  /// If no repository is provided, defaults to [SharedPrefsTeamRepository].
  /// Pass a mock repository for testing.
  TeamsViewModel({TeamRepository? repository})
    : _repository = repository ?? SharedPrefsTeamRepository() {
    unawaited(loadTeams());
  }

  final TeamRepository _repository;
  List<Team> _teams = [];
  bool _loaded = false;

  List<Team> get teams => _teams;
  List<String> get teamNames => _teams.map((team) => team.name).toList();
  bool get loaded => _loaded;

  Future<void> loadTeams() async {
    _teams = await _repository.loadTeams();

    if (_teams.isEmpty) {
      // Migrate from old format if present
      final legacyNames = await _repository.loadLegacyTeamNames();
      if (legacyNames != null && legacyNames.isNotEmpty) {
        _teams = legacyNames.map((name) => Team(name: name)).toList();
        await _repository.saveTeams(_teams);
        await _repository.removeLegacyTeamNames();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveTeams() async {
    await _repository.saveTeams(_teams);
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
