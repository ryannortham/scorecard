// centralised colour management and theming

import 'package:flutter/material.dart';

/// manages theme colours and colour scheme utilities
class ColorService {
  ColorService._();

  // one ui colour system based on samsung guidelines
  static const Color _oneUiBlue = Color(0xFF0381FE);
  static const Color _oneUiGreen = Color(0xFF15B76D);
  static const Color _oneUiPurple = Color(0xFF8064F4);
  static const Color _oneUiOrange = Color(0xFFFF9E00);
  static const Color _oneUiPink = Color(0xFFEE2172);

  static const Map<String, Color> _themeColors = {
    'blue': _oneUiBlue,
    'green': _oneUiGreen,
    'purple': _oneUiPurple,
    'orange': _oneUiOrange,
    'pink': _oneUiPink,
  };

  static const String _defaultThemeKey = 'blue';

  static String get defaultTheme => _defaultThemeKey;
  static Color get defaultColor => _oneUiBlue;
  static List<String> get availableThemes => _themeColors.keys.toList();

  static Color getThemeColor(String themeName) {
    return _themeColors[themeName] ?? defaultColor;
  }

  static Color getThemeColorWithDynamicFallback(String themeName) {
    if (themeName == 'dynamic') {
      return defaultColor;
    }
    return getThemeColor(themeName);
  }

  static List<Map<String, dynamic>> getColorOptions({
    required bool supportsDynamicColors,
  }) {
    final options = <Map<String, dynamic>>[];

    if (supportsDynamicColors) {
      options.add({
        'value': 'dynamic',
        'label': 'Dynamic',
        'color': defaultColor,
      });
    }

    for (final entry in _themeColors.entries) {
      options.add({
        'value': entry.key,
        'label': _capitalize(entry.key),
        'color': entry.value,
      });
    }

    return options;
  }

  static bool isValidTheme(String themeName) {
    return themeName == 'dynamic' || _themeColors.containsKey(themeName);
  }

  static String validateTheme(
    String themeName, {
    required bool supportsDynamicColors,
  }) {
    if (themeName == 'dynamic' && !supportsDynamicColors) {
      return defaultTheme;
    }

    if (isValidTheme(themeName)) {
      return themeName;
    }

    return defaultTheme;
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static const Color transparent = Colors.transparent;

  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  static Color semiTransparent(Color color, [double alpha = 0.5]) {
    return color.withValues(alpha: alpha);
  }

  /// detects if current theme uses dynamic colours
  static bool _isDynamicTheme(BuildContext context) {
    try {
      if (!context.mounted) return false;

      final theme = Theme.of(context);
      final brightness = theme.brightness;
      final colorScheme = theme.colorScheme;

      final isKnownSeedColor = _themeColors.values.any((color) {
        try {
          final seedScheme = ColorScheme.fromSeed(
            seedColor: color,
            brightness: brightness,
          );
          return seedScheme.primary == colorScheme.primary;
        } on Exception {
          return false;
        }
      });

      return !isKnownSeedColor;
    } on Exception {
      return false;
    }
  }

  /// generates material 3 surface colours for dynamic themes
  static Map<String, Color> _generateDynamicSurfaceColors(
    ColorScheme colorScheme,
  ) {
    final surface = colorScheme.surface;
    final primary = colorScheme.primary;
    final brightness = colorScheme.brightness;

    final isLight = brightness == Brightness.light;
    final step = isLight ? -0.05 : 0.05;

    return {
      'surface': surface,
      'surfaceContainer': _adjustSurfaceTone(surface, step * 1.0, primary),
      'surfaceContainerLow': _adjustSurfaceTone(surface, step * 0.5, primary),
      'surfaceContainerLowest': _adjustSurfaceTone(
        surface,
        step * 0.2,
        primary,
      ),
      'surfaceContainerHigh': _adjustSurfaceTone(surface, step * 1.5, primary),
      'surfaceContainerHighest': _adjustSurfaceTone(
        surface,
        step * 2.0,
        primary,
      ),
      'surfaceDim': _adjustSurfaceTone(
        surface,
        isLight ? -0.1 : -0.05,
        primary,
      ),
      'surfaceBright': _adjustSurfaceTone(
        surface,
        isLight ? 0.05 : 0.1,
        primary,
      ),
    };
  }

  /// adjusts surface tone with primary tint
  static Color _adjustSurfaceTone(
    Color surface,
    double adjustment,
    Color primary,
  ) {
    final hsl = HSLColor.fromColor(surface);
    final adjustedLightness = (hsl.lightness + adjustment).clamp(0.0, 1.0);

    final adjusted = hsl.withLightness(adjustedLightness).toColor();
    return Color.lerp(adjusted, primary, 0.02) ?? adjusted;
  }
}

/// provides easy access to theme colours via context
extension ThemeColors on BuildContext {
  /// access to all theme colours
  AppColors get colors => AppColors._(this);
}

/// colour getters for theme access
class AppColors {
  AppColors._(this._context);
  final BuildContext _context;

  ColorScheme? get _colorScheme {
    try {
      if (!_context.mounted) return null;
      return Theme.of(_context).colorScheme;
    } on Exception {
      return null;
    }
  }

  /// material 3 fallback colours
  static const Color _fallbackSurface = Color(0xFFFFFBFE);
  static const Color _fallbackOnSurface = Color(0xFF1C1B1F);
  static const Color _fallbackOnSurfaceVariant = Color(0xFF49454F);
  static const Color _fallbackError = Color(0xFFBA1A1A);
  static const Color _fallbackOnError = Color(0xFFFFFFFF);
  static const Color _fallbackOutline = Color(0xFF79747E);

  Color get primary => _colorScheme?.primary ?? ColorService.defaultColor;
  Color get onPrimary => _colorScheme?.onPrimary ?? Colors.white;
  Color get primaryContainer =>
      _colorScheme?.primaryContainer ?? const Color(0xFFE1E2FF);
  Color get onPrimaryContainer =>
      _colorScheme?.onPrimaryContainer ?? const Color(0xFF001A41);

  Color get secondary => _colorScheme?.secondary ?? const Color(0xFF575E71);
  Color get onSecondary => _colorScheme?.onSecondary ?? Colors.white;
  Color get secondaryContainer =>
      _colorScheme?.secondaryContainer ?? const Color(0xFFDBE2F9);
  Color get onSecondaryContainer =>
      _colorScheme?.onSecondaryContainer ?? const Color(0xFF141B2C);

  Color get tertiary => _colorScheme?.tertiary ?? const Color(0xFF715573);
  Color get onTertiary => _colorScheme?.onTertiary ?? Colors.white;
  Color get tertiaryContainer =>
      _colorScheme?.tertiaryContainer ?? const Color(0xFFFDD7FC);
  Color get onTertiaryContainer =>
      _colorScheme?.onTertiaryContainer ?? const Color(0xFF29132D);

  // cache for dynamic surface colours
  Map<String, Color>? _cachedDynamicSurfaceColors;
  ColorScheme? _lastColorScheme;

  /// gets dynamic surface colours with caching
  Map<String, Color> get _dynamicSurfaceColors {
    final currentScheme = _colorScheme;
    if (currentScheme == null) return <String, Color>{};

    // regenerate only if colour scheme changed
    if (_cachedDynamicSurfaceColors == null ||
        _lastColorScheme != currentScheme) {
      _cachedDynamicSurfaceColors = ColorService._generateDynamicSurfaceColors(
        currentScheme,
      );
      _lastColorScheme = currentScheme;
    }

    return _cachedDynamicSurfaceColors!;
  }

  /// gets surface colour with dynamic theme handling
  Color _getSurfaceColor(String key) {
    final scheme = _colorScheme;
    if (scheme == null) return _fallbackSurface;

    try {
      if (ColorService._isDynamicTheme(_context)) {
        final dynamicColors = _dynamicSurfaceColors;
        return dynamicColors[key] ?? scheme.surface;
      }

      switch (key) {
        case 'surface':
          return scheme.surface;
        case 'surfaceContainer':
          return scheme.surfaceContainer;
        case 'surfaceContainerHigh':
          return scheme.surfaceContainerHigh;
        case 'surfaceContainerHighest':
          return scheme.surfaceContainerHighest;
        case 'surfaceContainerLow':
          return scheme.surfaceContainerLow;
        case 'surfaceContainerLowest':
          return scheme.surfaceContainerLowest;
        case 'surfaceDim':
          return scheme.surfaceDim;
        case 'surfaceBright':
          return scheme.surfaceBright;
        default:
          return scheme.surface;
      }
    } on Exception {
      return scheme.surface;
    }
  }

  Color get surface => _getSurfaceColor('surface');
  Color get surfaceVariant =>
      _colorScheme?.surfaceContainerHighest ?? const Color(0xFFE7E0EC);
  Color get onSurface => _colorScheme?.onSurface ?? _fallbackOnSurface;
  Color get onSurfaceVariant =>
      _colorScheme?.onSurfaceVariant ?? _fallbackOnSurfaceVariant;
  Color get surfaceContainer => _getSurfaceColor('surfaceContainer');
  Color get surfaceContainerHigh => _getSurfaceColor('surfaceContainerHigh');
  Color get surfaceContainerHighest =>
      _getSurfaceColor('surfaceContainerHighest');
  Color get surfaceContainerLow => _getSurfaceColor('surfaceContainerLow');
  Color get surfaceContainerLowest =>
      _getSurfaceColor('surfaceContainerLowest');
  Color get surfaceDim => _getSurfaceColor('surfaceDim');
  Color get surfaceBright => _getSurfaceColor('surfaceBright');

  Color get error => _colorScheme?.error ?? _fallbackError;
  Color get onError => _colorScheme?.onError ?? _fallbackOnError;
  Color get outline => _colorScheme?.outline ?? _fallbackOutline;
  Color get background => surface;
}
