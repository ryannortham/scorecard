import 'package:flutter/material.dart';
import '../color_service.dart';

/// Service for handling all app icon assets including tally marks and football icons
class AssetIconService {
  /// Maximum value for a single tally icon
  static const int _maxTallyValue = 5;

  // Tally Icon Methods

  /// Gets tally icon paths for a given number
  /// Returns empty list for zero/negative values
  static List<String> getTallyIconPaths(int value) {
    if (value <= 0) return [];

    final List<String> icons = [];
    int remaining = value;

    // Add tally5 icons for groups of 5
    while (remaining >= _maxTallyValue) {
      icons.add('assets/tally/tally$_maxTallyValue.ico');
      remaining -= _maxTallyValue;
    }

    // Add remainder
    if (remaining > 0) {
      icons.add('assets/tally/tally$remaining.ico');
    }

    return icons;
  }

  /// Gets total number of tally icons needed
  static int getTallyIconCount(int value) {
    if (value <= 0) return 0;
    return (value / _maxTallyValue).ceil();
  }

  /// Gets all available tally icon paths
  static List<String> getAllTallyIconPaths() {
    return List.generate(
      _maxTallyValue,
      (index) => 'assets/tally/tally${index + 1}.ico',
    );
  }

  // Football Icon Methods

  /// Path to the football icon asset
  static const String footballIconPath = 'assets/icon/football.png';

  /// Creates a football icon widget with theming support
  static Widget createFootballIcon({
    double size = 24.0,
    Color? color,
    BuildContext? context,
  }) {
    return FootballIcon(size: size, color: color, context: context);
  }
}

/// A widget that displays a football icon using a PNG asset
/// The icon adapts to the app theme through color filtering
class FootballIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final BuildContext? context;

  const FootballIcon({super.key, this.size = 24.0, this.color, this.context});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (this.context ?? context).colors.onSurface;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      child: Image.asset(
        AssetIconService.footballIconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if asset fails to load
          return Icon(Icons.sports_football, size: size, color: iconColor);
        },
      ),
    );
  }
}
