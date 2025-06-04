import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  int _defaultQuarterMinutes = 15;
  bool _defaultIsCountdownTimer = true;
  String _favoriteTeam = '';
  bool _loaded = false;

  static const String _quarterMinutesKey = 'default_quarter_minutes';
  static const String _countdownTimerKey = 'default_countdown_timer';
  static const String _favoriteTeamKey = 'favorite_team';

  int get defaultQuarterMinutes => _defaultQuarterMinutes;
  bool get defaultIsCountdownTimer => _defaultIsCountdownTimer;
  String get favoriteTeam => _favoriteTeam;
  bool get loaded => _loaded;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultQuarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
    _defaultIsCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;
    _favoriteTeam = prefs.getString(_favoriteTeamKey) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quarterMinutesKey, _defaultQuarterMinutes);
    await prefs.setBool(_countdownTimerKey, _defaultIsCountdownTimer);
    await prefs.setString(_favoriteTeamKey, _favoriteTeam);
  }

  Future<void> setDefaultQuarterMinutes(int minutes) async {
    _defaultQuarterMinutes = minutes;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setDefaultIsCountdownTimer(bool isCountdown) async {
    _defaultIsCountdownTimer = isCountdown;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFavoriteTeam(String team) async {
    _favoriteTeam = team;
    await _saveSettings();
    notifyListeners();
  }
}
