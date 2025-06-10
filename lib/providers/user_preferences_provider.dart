import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified provider for managing all user preferences and settings
/// Combines app settings and game setup preferences into a single cohesive provider
class UserPreferencesProvider extends ChangeNotifier {
  // App Settings
  String _favoriteTeam = '';
  ThemeMode _themeMode = ThemeMode.system;
  String _colorTheme = 'adaptive';

  // Game Setup Preferences
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  // Loading state
  bool _loaded = false;

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

  UserPreferencesProvider() {
    loadPreferences();
  }

  /// Load all preferences from SharedPreferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load app settings
    _favoriteTeam = prefs.getString(_favoriteTeamKey) ?? '';

    final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.system,
    );

    _colorTheme = prefs.getString(_colorThemeKey) ?? 'adaptive';
    _colorTheme = _validateColorTheme(_colorTheme);

    // Load game setup preferences
    _quarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
    _isCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;

    _loaded = true;
    notifyListeners();
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
    const validThemes = {
      'adaptive',
      'blue',
      'green',
      'teal',
      'purple',
      'indigo',
      'red',
      'pink',
      'deep_orange',
      'amber',
      'cyan',
      'brown'
    };

    if (validThemes.contains(theme)) {
      return theme;
    } else {
      return 'adaptive'; // Default fallback
    }
  }

  /// Get color from theme name using Material Design 3 recommended colors
  Color getThemeColor() {
    switch (_colorTheme) {
      case 'adaptive':
        return const Color(
            0xFF6750A4); // Material Purple - fallback for when dynamic colors aren't available
      case 'blue':
        return const Color(0xFF1976D2); // Material Blue 700
      case 'teal':
        return const Color(0xFF00695C); // Material Teal 800
      case 'green':
        return const Color(0xFF2E7D32); // Material Green 800
      case 'amber':
        return const Color(0xFFF57C00); // Material Amber 800
      case 'deep_orange':
        return const Color(0xFFD84315); // Material Deep Orange 800
      case 'red':
        return const Color(0xFFC62828); // Material Red 800
      case 'pink':
        return const Color(0xFFAD1457); // Material Pink 800
      case 'purple':
        return const Color(0xFF6A1B9A); // Material Purple 800
      case 'indigo':
        return const Color(0xFF283593); // Material Indigo 800
      case 'cyan':
        return const Color(0xFF00838F); // Material Cyan 800
      case 'brown':
        return const Color(0xFF5D4037); // Material Brown 700
      default:
        return const Color(0xFF1976D2); // Default to Material Blue
    }
  }

  /// Get display name for color themes
  String getColorThemeDisplayName() {
    switch (_colorTheme) {
      case 'adaptive':
        return 'Adaptive (Device Colors)';
      case 'blue':
        return 'Ocean Blue';
      case 'teal':
        return 'Emerald Teal';
      case 'green':
        return 'Forest Green';
      case 'amber':
        return 'Golden Amber';
      case 'deep_orange':
        return 'Sunset Orange';
      case 'red':
        return 'Ruby Red';
      case 'pink':
        return 'Rose Pink';
      case 'purple':
        return 'Royal Purple';
      case 'indigo':
        return 'Midnight Indigo';
      case 'cyan':
        return 'Azure Cyan';
      case 'brown':
        return 'Earth Brown';
      default:
        return 'Ocean Blue';
    }
  }
}
