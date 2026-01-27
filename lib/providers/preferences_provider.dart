// user preferences and settings management

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// manages app settings and game setup preferences
class UserPreferencesProvider extends ChangeNotifier {
  UserPreferencesProvider() {
    unawaited(_initializeProvider());
  }

  // app settings
  List<String> _favoriteTeams = [];
  ThemeMode _themeMode = ThemeMode.system;
  String _colorTheme = '';
  bool _useTallys = true;

  // game setup preferences
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  // loading state
  bool _loaded = false;
  bool? _dynamicColorsSupported;

  // shared preferences keys
  static const String _favoriteTeamsKey = 'favorite_teams';
  static const String _legacyFavoriteTeamKey = 'favorite_team'; // For migration
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';
  static const String _useTallysKey = 'use_tallys';
  static const String _quarterMinutesKey = 'game_setup_quarter_minutes';
  static const String _countdownTimerKey = 'game_setup_countdown_timer';

  // app settings getters
  List<String> get favoriteTeams => List.unmodifiable(_favoriteTeams);
  ThemeMode get themeMode => _themeMode;
  String get colorTheme => ColorService.validateTheme(
    _colorTheme,
    supportsDynamicColors: supportsDynamicColors,
  );
  bool get useTallys => _useTallys;

  // game setup preferences getters
  int get quarterMinutes => _quarterMinutes;
  bool get isCountdownTimer => _isCountdownTimer;

  // loading state
  bool get loaded => _loaded;

  // dynamic colour support status
  bool get supportsDynamicColors => _dynamicColorsSupported ?? false;

  Future<void> _initializeProvider() async {
    _dynamicColorsSupported = await _checkDynamicColorSupport();
    _colorTheme = ColorService.defaultTheme;
    await _loadPreferencesAsync();
  }

  Future<void> _loadPreferencesAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Migrate from legacy single favourite to multiple favourites
      final legacyFavorite = prefs.getString(_legacyFavoriteTeamKey);
      if (legacyFavorite != null && legacyFavorite.isNotEmpty) {
        // Migrate old single favourite to new list format
        _favoriteTeams = [legacyFavorite];
        // Save in new format and remove old key
        await prefs.setStringList(_favoriteTeamsKey, _favoriteTeams);
        await prefs.remove(_legacyFavoriteTeamKey);
      } else {
        // Load from new format
        _favoriteTeams = prefs.getStringList(_favoriteTeamsKey) ?? [];
      }

      final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );

      _colorTheme =
          prefs.getString(_colorThemeKey) ?? ColorService.defaultTheme;
      _colorTheme = ColorService.validateTheme(
        _colorTheme,
        supportsDynamicColors: supportsDynamicColors,
      );

      _useTallys = prefs.getBool(_useTallysKey) ?? true;
      _quarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
      _isCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;

      _loaded = true;
      notifyListeners();
    } on Exception {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> loadPreferences() async {
    await _loadPreferencesAsync();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteTeamsKey, _favoriteTeams);
    await prefs.setString(_themeModeKey, _themeMode.name);
    await prefs.setString(_colorThemeKey, _colorTheme);
    await prefs.setBool(_useTallysKey, _useTallys);
    await prefs.setInt(_quarterMinutesKey, _quarterMinutes);
    await prefs.setBool(_countdownTimerKey, _isCountdownTimer);
  }

  // app settings setters

  /// checks if a team is in the favourites list
  bool isFavoriteTeam(String team) {
    return _favoriteTeams.contains(team);
  }

  /// adds a team to favourites
  Future<void> addFavoriteTeam(String team) async {
    if (!_favoriteTeams.contains(team)) {
      _favoriteTeams.add(team);
      await _savePreferences();
      notifyListeners();
    }
  }

  /// removes a team from favourites
  Future<void> removeFavoriteTeam(String team) async {
    if (_favoriteTeams.remove(team)) {
      await _savePreferences();
      notifyListeners();
    }
  }

  /// toggles a team's favourite status
  Future<void> toggleFavoriteTeam(String team) async {
    if (_favoriteTeams.contains(team)) {
      await removeFavoriteTeam(team);
    } else {
      await addFavoriteTeam(team);
    }
  }

  /// gets the first favourite team for pre-selection in game setup
  /// returns null if no favourites exist
  String? getDefaultFavoriteTeam() {
    return _favoriteTeams.isEmpty ? null : _favoriteTeams.first;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setColorTheme(String theme) async {
    _colorTheme = ColorService.validateTheme(
      theme,
      supportsDynamicColors: supportsDynamicColors,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setUseTallys({required bool value}) async {
    _useTallys = value;
    await _savePreferences();
    notifyListeners();
  }

  // game setup preferences setters
  Future<void> setQuarterMinutes(int minutes) async {
    _quarterMinutes = minutes;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setIsCountdownTimer({required bool value}) async {
    _isCountdownTimer = value;
    await _savePreferences();
    notifyListeners();
  }

  Color getThemeColor() {
    return ColorService.getThemeColorWithDynamicFallback(_colorTheme);
  }

  Future<bool> _checkDynamicColorSupport() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidApiLevel();
      }
      return false;
    } on Exception {
      return false;
    }
  }

  /// checks for android 12+ (api 31+) which supports material you
  Future<bool> _checkAndroidApiLevel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 31;
      }
      return false;
    } on Exception {
      return false;
    }
  }
}
