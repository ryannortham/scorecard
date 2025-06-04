import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  int _defaultQuarterMinutes = 15;
  bool _defaultIsCountdownTimer = true;
  String _favoriteTeam = '';
  ThemeMode _themeMode = ThemeMode.system;
  String _colorTheme = 'adaptive';
  bool _loaded = false;

  static const String _quarterMinutesKey = 'default_quarter_minutes';
  static const String _countdownTimerKey = 'default_countdown_timer';
  static const String _favoriteTeamKey = 'favorite_team';
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';

  int get defaultQuarterMinutes => _defaultQuarterMinutes;
  bool get defaultIsCountdownTimer => _defaultIsCountdownTimer;
  String get favoriteTeam => _favoriteTeam;
  ThemeMode get themeMode => _themeMode;
  String get colorTheme => _colorTheme;
  bool get loaded => _loaded;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultQuarterMinutes = prefs.getInt(_quarterMinutesKey) ?? 15;
    _defaultIsCountdownTimer = prefs.getBool(_countdownTimerKey) ?? true;
    _favoriteTeam = prefs.getString(_favoriteTeamKey) ?? '';

    // Load theme settings
    final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.system,
    );
    _colorTheme = prefs.getString(_colorThemeKey) ?? 'adaptive';

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quarterMinutesKey, _defaultQuarterMinutes);
    await prefs.setBool(_countdownTimerKey, _defaultIsCountdownTimer);
    await prefs.setString(_favoriteTeamKey, _favoriteTeam);
    await prefs.setString(_themeModeKey, _themeMode.name);
    await prefs.setString(_colorThemeKey, _colorTheme);
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

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setColorTheme(String theme) async {
    _colorTheme = theme;
    await _saveSettings();
    notifyListeners();
  }

  // Helper method to get color from theme name using Material Design 3 recommended colors
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

  // Helper method to get display name for color themes
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
