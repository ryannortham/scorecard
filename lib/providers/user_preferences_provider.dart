import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Unified provider for managing all user preferences and settings
/// Combines app settings and game setup preferences into a single cohesive provider
class UserPreferencesProvider extends ChangeNotifier {
  // App Settings
  String _favoriteTeam = '';
  ThemeMode _themeMode = ThemeMode.system;
  String _colorTheme = ''; // Will be set to default in constructor

  // Game Setup Preferences
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  // Loading state
  bool _loaded = false;
  bool? _dynamicColorsSupported; // Cache the result

  // SharedPreferences keys
  static const String _favoriteTeamKey = 'favorite_team';
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';
  static const String _quarterMinutesKey = 'game_setup_quarter_minutes';
  static const String _countdownTimerKey = 'game_setup_countdown_timer';

  // App Settings Getters
  String get favoriteTeam => _favoriteTeam;
  ThemeMode get themeMode => _themeMode;
  String get colorTheme => _validateColorTheme(_colorTheme);

  // Game Setup Preferences Getters
  int get quarterMinutes => _quarterMinutes;
  bool get isCountdownTimer => _isCountdownTimer;

  // Loading state
  bool get loaded => _loaded;

  // Dynamic color support status
  bool get supportsDynamicColors => _dynamicColorsSupported ?? false;

  UserPreferencesProvider() {
    // Start checking dynamic color support and loading preferences
    _initializeProvider();
  }

  /// Initialize the provider by checking dynamic color support and loading preferences
  Future<void> _initializeProvider() async {
    // First, check if device supports dynamic colors
    _dynamicColorsSupported = await _checkDynamicColorSupport();

    // Set default color theme to blue for consistency across all devices
    _colorTheme = 'blue';

    // Then load preferences
    await _loadPreferencesAsync();
  }

  /// Load all preferences from SharedPreferences (non-blocking)
  Future<void> _loadPreferencesAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load app settings
      _favoriteTeam = prefs.getString(_favoriteTeamKey) ?? '';

      final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );

      _colorTheme = prefs.getString(_colorThemeKey) ?? 'blue';
      _colorTheme = _validateColorTheme(_colorTheme);

      // Load game setup preferences
      _quarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
      _isCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;

      _loaded = true;
      notifyListeners();
    } catch (e) {
      // If loading fails, use defaults and mark as loaded
      _loaded = true;
      notifyListeners();
    }
  }

  /// Public method to manually reload preferences if needed
  Future<void> loadPreferences() async {
    await _loadPreferencesAsync();
  }

  /// Save all preferences to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save app settings
    await prefs.setString(_favoriteTeamKey, _favoriteTeam);
    await prefs.setString(_themeModeKey, _themeMode.name);
    await prefs.setString(_colorThemeKey, _colorTheme);

    // Save game setup preferences
    await prefs.setInt(_quarterMinutesKey, _quarterMinutes);
    await prefs.setBool(_countdownTimerKey, _isCountdownTimer);
  }

  // App Settings Setters
  Future<void> setFavoriteTeam(String team) async {
    _favoriteTeam = team;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setColorTheme(String theme) async {
    _colorTheme = _validateColorTheme(theme);
    await _savePreferences();
    notifyListeners();
  }

  // Game Setup Preferences Setters
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

  /// Validate color theme and return a valid one
  String _validateColorTheme(String theme) {
    // Check if device supports dynamic colors for dynamic theme
    final supportsDynamicColors = _dynamicColorsSupported ?? false;

    const validThemes = {'blue', 'green', 'purple', 'orange'};

    // Add dynamic to valid themes only if supported
    final allValidThemes = {
      if (supportsDynamicColors) 'dynamic',
      ...validThemes,
    };

    if (allValidThemes.contains(theme)) {
      return theme;
    } else {
      // If user had 'dynamic' but device doesn't support it, fall back to 'blue'
      if (theme == 'dynamic' && !supportsDynamicColors) {
        return 'blue';
      }
      // For other invalid themes, default to blue
      return 'blue';
    }
  }

  /// Async method to check if device supports dynamic colors
  Future<bool> _checkDynamicColorSupport() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidApiLevel();
      }
      return false; // iOS and other platforms don't support Material You
    } catch (e) {
      // Fallback if Platform check fails (e.g., in web builds)
      return false;
    }
  }

  /// Check if Android device is API level 31+ (Android 12+) for Material You support
  Future<bool> _checkAndroidApiLevel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Check if Android SDK version is 31 or higher (Android 12+)
        return androidInfo.version.sdkInt >= 31;
      }
      return false;
    } catch (e) {
      // If we can't determine the API level, err on the side of caution
      return false;
    }
  }

  /// Get color from theme name using Material Design 3 seed colors
  Color getThemeColor() {
    switch (_colorTheme) {
      case 'dynamic':
        // For dynamic theme, return Material 3 baseline for fallback
        // The actual dynamic colors are handled in main.dart via DynamicColorBuilder
        return const Color(0xFF6750A4); // Material 3 baseline purple
      case 'blue':
        return const Color(0xFF1565C0); // Material 3 Blue seed
      case 'green':
        return const Color(0xFF4CAF50); // Material 3 Green seed
      case 'purple':
        return const Color(0xFF9C27B0); // Material 3 Purple seed
      case 'orange':
        return const Color(0xFFFF9800); // Material 3 Orange seed
      default:
        return const Color(0xFF1565C0); // Default to Blue
    }
  }
}
