import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing game setup preferences that are stored locally
/// and recalled for subsequent game setups
class GameSetupPreferencesProvider extends ChangeNotifier {
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;
  bool _loaded = false;

  static const String _quarterMinutesKey = 'game_setup_quarter_minutes';
  static const String _countdownTimerKey = 'game_setup_countdown_timer';

  int get quarterMinutes => _quarterMinutes;
  bool get isCountdownTimer => _isCountdownTimer;
  bool get loaded => _loaded;

  GameSetupPreferencesProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _quarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
    _isCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;

    _loaded = true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quarterMinutesKey, _quarterMinutes);
    await prefs.setBool(_countdownTimerKey, _isCountdownTimer);
  }

  Future<void> setQuarterMinutes(int minutes) async {
    _quarterMinutes = minutes;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setIsCountdownTimer(bool isCountdown) async {
    _isCountdownTimer = isCountdown;
    await _savePreferences();
    notifyListeners();
  }
}
