// SharedPreferences implementation of PreferencesRepository

import 'package:flutter/material.dart';
import 'package:scorecard/repositories/preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [PreferencesRepository].
class SharedPrefsPreferencesRepository implements PreferencesRepository {
  static const String _favoriteTeamsKey = 'favorite_teams';
  static const String _legacyFavoriteTeamKey = 'favorite_team';
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';
  static const String _useTallysKey = 'use_tallys';
  static const String _quarterMinutesKey = 'game_setup_quarter_minutes';
  static const String _countdownTimerKey = 'game_setup_countdown_timer';

  @override
  Future<PreferencesData> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeString = prefs.getString(_themeModeKey) ?? 'dark';
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.dark,
    );

    return PreferencesData(
      favoriteTeams: prefs.getStringList(_favoriteTeamsKey) ?? [],
      themeMode: themeMode,
      colorTheme: prefs.getString(_colorThemeKey) ?? '',
      useTallys: prefs.getBool(_useTallysKey) ?? false,
      quarterMinutes: prefs.getInt(_quarterMinutesKey) ?? 15,
      isCountdownTimer: prefs.getBool(_countdownTimerKey) ?? true,
    );
  }

  @override
  Future<void> save(PreferencesData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteTeamsKey, data.favoriteTeams);
    await prefs.setString(_themeModeKey, data.themeMode.name);
    await prefs.setString(_colorThemeKey, data.colorTheme);
    await prefs.setBool(_useTallysKey, data.useTallys);
    await prefs.setInt(_quarterMinutesKey, data.quarterMinutes);
    await prefs.setBool(_countdownTimerKey, data.isCountdownTimer);
  }

  @override
  Future<String?> loadLegacyFavoriteTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_legacyFavoriteTeamKey);
  }

  @override
  Future<void> removeLegacyFavoriteTeam() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyFavoriteTeamKey);
  }
}
