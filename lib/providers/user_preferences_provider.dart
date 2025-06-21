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
    // Start loading preferences but don't block the UI
    _loadPreferencesAsync();
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

      _colorTheme = prefs.getString(_colorThemeKey) ?? 'adaptive';
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
      'orange',
      'amber',
      'yellow',
      'lime',
      'light_green',
      'cyan',
      'light_blue',
      'deep_purple',
      'brown',
      'blue_grey',
      'grey',
    };

    if (validThemes.contains(theme)) {
      return theme;
    } else {
      return 'adaptive'; // Default fallback
    }
  }

  /// Get color from theme name using Material Design 3 seed colors
  Color getThemeColor() {
    switch (_colorTheme) {
      case 'adaptive':
        return const Color(0xFF6750A4); // Material 3 baseline purple
      case 'blue':
        return const Color(0xFF1565C0); // Material 3 Blue seed
      case 'light_blue':
        return const Color(0xFF0277BD); // Material 3 Light Blue seed
      case 'indigo':
        return const Color(0xFF3F51B5); // Material 3 Indigo seed
      case 'deep_purple':
        return const Color(0xFF673AB7); // Material 3 Deep Purple seed
      case 'purple':
        return const Color(0xFF9C27B0); // Material 3 Purple seed
      case 'pink':
        return const Color(0xFFE91E63); // Material 3 Pink seed
      case 'red':
        return const Color(0xFFD32F2F); // Material 3 Red seed
      case 'deep_orange':
        return const Color(0xFFFF5722); // Material 3 Deep Orange seed
      case 'orange':
        return const Color(0xFFFF9800); // Material 3 Orange seed
      case 'amber':
        return const Color(0xFFFFC107); // Material 3 Amber seed
      case 'yellow':
        return const Color(0xFFFFEB3B); // Material 3 Yellow seed
      case 'lime':
        return const Color(0xFFCDDC39); // Material 3 Lime seed
      case 'light_green':
        return const Color(0xFF8BC34A); // Material 3 Light Green seed
      case 'green':
        return const Color(0xFF4CAF50); // Material 3 Green seed
      case 'teal':
        return const Color(0xFF009688); // Material 3 Teal seed
      case 'cyan':
        return const Color(0xFF00BCD4); // Material 3 Cyan seed
      case 'brown':
        return const Color(0xFF795548); // Material 3 Brown seed
      case 'blue_grey':
        return const Color(0xFF607D8B); // Material 3 Blue Grey seed
      case 'grey':
        return const Color(0xFF9E9E9E); // Material 3 Grey seed
      default:
        return const Color(0xFF1565C0); // Default to Material 3 Blue
    }
  }

  /// Get display name for color themes
  String getColorThemeDisplayName() {
    switch (_colorTheme) {
      case 'adaptive':
        return 'Adaptive (Device Colors)';
      case 'blue':
        return 'Ocean Blue';
      case 'light_blue':
        return 'Sky Blue';
      case 'indigo':
        return 'Midnight Indigo';
      case 'deep_purple':
        return 'Deep Purple';
      case 'purple':
        return 'Royal Purple';
      case 'pink':
        return 'Rose Pink';
      case 'red':
        return 'Ruby Red';
      case 'deep_orange':
        return 'Sunset Orange';
      case 'orange':
        return 'Vibrant Orange';
      case 'amber':
        return 'Golden Amber';
      case 'yellow':
        return 'Sunny Yellow';
      case 'lime':
        return 'Lime Green';
      case 'light_green':
        return 'Fresh Green';
      case 'green':
        return 'Forest Green';
      case 'teal':
        return 'Emerald Teal';
      case 'cyan':
        return 'Azure Cyan';
      case 'brown':
        return 'Earth Brown';
      case 'blue_grey':
        return 'Steel Blue';
      case 'grey':
        return 'Modern Grey';
      default:
        return 'Ocean Blue';
    }
  }
}
