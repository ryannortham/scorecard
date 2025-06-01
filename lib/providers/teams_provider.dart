import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamsProvider extends ChangeNotifier {
  List<String> _teams = [];
  bool _loaded = false;

  List<String> get teams => _teams;
  bool get loaded => _loaded;

  TeamsProvider() {
    loadTeams();
  }

  Future<void> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    _teams = prefs.getStringList('teamNames') ?? [];
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveTeams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('teamNames', _teams);
  }

  Future<void> addTeam(String name) async {
    _teams.add(name);
    await _saveTeams();
    notifyListeners();
  }

  Future<void> editTeam(int index, String newName) async {
    _teams[index] = newName;
    await _saveTeams();
    notifyListeners();
  }

  Future<void> deleteTeam(int index) async {
    _teams.removeAt(index);
    await _saveTeams();
    notifyListeners();
  }
}
