// user preferences and settings management

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/repositories/preferences_repository.dart';
import 'package:scorecard/repositories/shared_prefs_preferences_repository.dart';
import 'package:scorecard/theme/colors.dart';

/// Manages app settings and game setup preferences via `PreferencesRepository`.
class PreferencesViewModel extends ChangeNotifier {
  /// Creates a PreferencesViewModel with an optional `PreferencesRepository`.
  ///
  /// If no repository is provided, defaults to
  /// `SharedPrefsPreferencesRepository`. Pass a mock repository for testing.
  PreferencesViewModel({PreferencesRepository? repository})
    : _repository = repository ?? SharedPrefsPreferencesRepository() {
    unawaited(_initializeProvider());
  }

  final PreferencesRepository _repository;

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
      // Check for legacy single favourite and migrate if needed
      final legacyFavorite = await _repository.loadLegacyFavoriteTeam();
      if (legacyFavorite != null && legacyFavorite.isNotEmpty) {
        // Migrate old single favourite to new list format
        _favoriteTeams = [legacyFavorite];
        await _savePreferences();
        await _repository.removeLegacyFavoriteTeam();
      } else {
        // Load from repository
        final data = await _repository.load();
        _favoriteTeams = List<String>.from(data.favoriteTeams);
        _themeMode = data.themeMode;
        _colorTheme = ColorService.validateTheme(
          data.colorTheme.isEmpty ? ColorService.defaultTheme : data.colorTheme,
          supportsDynamicColors: supportsDynamicColors,
        );
        _useTallys = data.useTallys;
        _quarterMinutes = data.quarterMinutes;
        _isCountdownTimer = data.isCountdownTimer;
      }

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
    final data = PreferencesData(
      favoriteTeams: _favoriteTeams,
      themeMode: _themeMode,
      colorTheme: _colorTheme,
      useTallys: _useTallys,
      quarterMinutes: _quarterMinutes,
      isCountdownTimer: _isCountdownTimer,
    );
    await _repository.save(data);
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
