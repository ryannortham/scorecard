import 'package:flutter/material.dart';

/// Centralized service for managing all color values in the application
/// This service provides consistent color definitions and theme-related utilities
class ColorService {
  ColorService._();

  // Private constructor to prevent instantiation
  static final ColorService _instance = ColorService._();

  /// Get the singleton instance of ColorService
  static ColorService get instance => _instance;

  /// Theme color definitions using Material Design 3 seed colors
  /// These are the primary colors used to generate color schemes
  static const Map<String, Color> _themeColors = {
    'blue': Color.fromRGBO(0, 145, 234, 1),
    'green': Color.fromRGBO(21, 183, 109, 1),
    'purple': Color.fromRGBO(128, 100, 244, 1),
    'orange': Color.fromRGBO(255, 158, 0, 1),
    'pink': Color.fromRGBO(238, 33, 114, 1),
  };

  /// Default theme when no specific theme is selected or for fallback
  static const String defaultTheme = 'blue';

  /// Get all available theme color names
  static List<String> get availableThemes => _themeColors.keys.toList();

  /// Get a theme color by name
  /// Returns the default blue color if the theme name is not found
  static Color getThemeColor(String themeName) {
    return _themeColors[themeName] ?? _themeColors[defaultTheme]!;
  }

  /// Get theme color with fallback for dynamic theme
  /// For dynamic theme, returns the default blue color as fallback
  static Color getThemeColorWithDynamicFallback(String themeName) {
    if (themeName == 'dynamic') {
      // For dynamic theme, return Material 3 baseline for fallback
      // The actual dynamic colors are handled in main.dart via DynamicColorBuilder
      return _themeColors[defaultTheme]!;
    }
    return getThemeColor(themeName);
  }

  /// Get color options for theme selection UI
  /// Includes dynamic option only if device supports it
  static List<Map<String, dynamic>> getColorOptions({
    required bool supportsDynamicColors,
  }) {
    final options = <Map<String, dynamic>>[];

    // Add dynamic option if supported
    if (supportsDynamicColors) {
      options.add({
        'value': 'dynamic',
        'label': 'Dynamic',
        'color': _themeColors[defaultTheme]!, // Fallback color for display
      });
    }

    // Add all theme colors
    for (final entry in _themeColors.entries) {
      options.add({
        'value': entry.key,
        'label': _capitalize(entry.key),
        'color': entry.value,
      });
    }

    return options;
  }

  /// Validate if a theme name is valid
  static bool isValidTheme(String themeName) {
    return themeName == 'dynamic' || _themeColors.containsKey(themeName);
  }

  /// Get a validated theme name with fallback
  static String validateTheme(
    String themeName, {
    required bool supportsDynamicColors,
  }) {
    // Check if device supports dynamic colors for dynamic theme
    if (themeName == 'dynamic' && !supportsDynamicColors) {
      return defaultTheme;
    }

    // Check if theme exists
    if (isValidTheme(themeName)) {
      return themeName;
    }

    // Fallback to default
    return defaultTheme;
  }

  /// Utility method to capitalize the first letter of a string
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Common semantic colors that should be used instead of hardcoded values
  static const Color transparent = Colors.transparent;

  /// Create a color with specified alpha value
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  /// Create a semi-transparent version of a color
  static Color semiTransparent(Color color, [double alpha = 0.5]) {
    return color.withValues(alpha: alpha);
  }

  /// Check if the current theme is using dynamic colors
  static bool _isDynamicTheme(BuildContext context) {
    try {
      final brightness = Theme.of(context).brightness;
      final colorScheme = Theme.of(context).colorScheme;

      // Check if this looks like a dynamic color scheme by comparing with seed-based schemes
      final isKnownSeedColor = _themeColors.values.any((color) {
        final seedScheme = ColorScheme.fromSeed(
          seedColor: color,
          brightness: brightness,
        );
        return seedScheme.primary == colorScheme.primary;
      });

      return !isKnownSeedColor;
    } catch (e) {
      return false;
    }
  }

  /// Generate Material 3 compliant surface colors for dynamic themes
  /// Uses proper tonal values according to Material 3 specification
  static Map<String, Color> _generateDynamicSurfaceColors(
    ColorScheme colorScheme,
  ) {
    final surface = colorScheme.surface;
    final primary = colorScheme.primary;
    final brightness = colorScheme.brightness;

    // Material 3 tonal values for surface variants
    // Light mode: surface containers are slightly darker than base surface
    // Dark mode: surface containers are slightly lighter than base surface
    final isLight = brightness == Brightness.light;

    // Base tonal step for Material 3 surface variants
    final step =
        isLight
            ? -0.05
            : 0.05; // Negative for light (darker), positive for dark (lighter)

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

  /// Adjust surface tone with Material 3 compliant method
  static Color _adjustSurfaceTone(
    Color surface,
    double adjustment,
    Color primary,
  ) {
    final hsl = HSLColor.fromColor(surface);
    final adjustedLightness = (hsl.lightness + adjustment).clamp(0.0, 1.0);

    // Blend with primary color for Material 3 surface tinting
    final adjusted = hsl.withLightness(adjustedLightness).toColor();
    return Color.lerp(adjusted, primary, 0.02) ?? adjusted;
  }
}

/// Extension on BuildContext to provide easy access to theme colors
/// Usage: context.colors.primary, context.colors.surfaceContainer, etc.
extension ThemeColors on BuildContext {
  /// Access to all theme colors through a simple colors property
  AppColors get colors => AppColors._(this);
}

/// Public class that holds all color getters
class AppColors {
  const AppColors._(this._context);
  final BuildContext _context;

  ColorScheme get _colorScheme => Theme.of(_context).colorScheme;

  // Primary colors
  Color get primary => _colorScheme.primary;
  Color get onPrimary => _colorScheme.onPrimary;
  Color get primaryContainer => _colorScheme.primaryContainer;
  Color get onPrimaryContainer => _colorScheme.onPrimaryContainer;

  // Secondary colors
  Color get secondary => _colorScheme.secondary;
  Color get onSecondary => _colorScheme.onSecondary;
  Color get secondaryContainer => _colorScheme.secondaryContainer;
  Color get onSecondaryContainer => _colorScheme.onSecondaryContainer;

  // Tertiary colors
  Color get tertiary => _colorScheme.tertiary;
  Color get onTertiary => _colorScheme.onTertiary;
  Color get tertiaryContainer => _colorScheme.tertiaryContainer;
  Color get onTertiaryContainer => _colorScheme.onTertiaryContainer;

  // Surface colors with Material 3 compliant dynamic color support
  Color get surface {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surface']!;
    }
    return _colorScheme.surface;
  }

  Color get onSurface => _colorScheme.onSurface;
  Color get onSurfaceVariant => _colorScheme.onSurfaceVariant;

  Color get surfaceContainer {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceContainer']!;
    }
    return _colorScheme.surfaceContainer;
  }

  Color get surfaceContainerHigh {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceContainerHigh']!;
    }
    return _colorScheme.surfaceContainerHigh;
  }

  Color get surfaceContainerHighest {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceContainerHighest']!;
    }
    return _colorScheme.surfaceContainerHighest;
  }

  Color get surfaceContainerLow {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceContainerLow']!;
    }
    return _colorScheme.surfaceContainerLow;
  }

  Color get surfaceContainerLowest {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceContainerLowest']!;
    }
    return _colorScheme.surfaceContainerLowest;
  }

  Color get surfaceDim {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceDim']!;
    }
    return _colorScheme.surfaceDim;
  }

  Color get surfaceBright {
    if (ColorService._isDynamicTheme(_context)) {
      final dynamicColors = ColorService._generateDynamicSurfaceColors(
        _colorScheme,
      );
      return dynamicColors['surfaceBright']!;
    }
    return _colorScheme.surfaceBright;
  }

  // Error colors
  Color get error => _colorScheme.error;
  Color get onError => _colorScheme.onError;

  // Outline
  Color get outline => _colorScheme.outline;

  // Background (Material 3 uses surface)
  Color get background => surface;
}
