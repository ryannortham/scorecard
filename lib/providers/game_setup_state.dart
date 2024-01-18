import 'package:flutter/material.dart';

class GameSetupState extends ChangeNotifier {
  // Define your form fields here as private variables
  String _homeTeam = '';
  String _awayTeam = '';

  // Create getters for the fields
  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;

  // Create methods to update the fields and notify listeners
  void updateHomeTeam(String team) {
    _homeTeam = team;
    notifyListeners();
  }

  void updateAwayTeam(String team) {
    _awayTeam = team;
    notifyListeners();
  }
}
