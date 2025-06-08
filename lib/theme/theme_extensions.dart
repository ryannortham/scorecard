import 'package:flutter/material.dart';

/// Extension methods for cleaner theme access
/// Reduces boilerplate Theme.of(context) calls throughout the app
extension ThemeExtensions on BuildContext {
  /// Quick access to theme data
  ThemeData get theme => Theme.of(this);

  /// Quick access to color scheme
  ColorScheme get colors => theme.colorScheme;

  /// Quick access to text theme
  TextTheme get textTheme => theme.textTheme;

  /// Quick access to common colors with semantic meaning
  Color get primaryColor => colors.primary;
  Color get secondaryColor => colors.secondary;
  Color get errorColor => colors.error;
  Color get surfaceColor => colors.surface;
  Color get onSurfaceColor => colors.onSurface;
  Color get onPrimaryColor => colors.onPrimary;

  /// Helper for disabled colors
  Color get disabledColor => onSurfaceColor.withValues(alpha: 0.38);
  Color get subtleColor => onSurfaceColor.withValues(alpha: 0.6);
}

/// Centralized text styles for consistent typography
class AppTextStyles {
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semiBold = FontWeight.w600;
  static const FontWeight _bold = FontWeight.w700;

  /// Team name styles
  static TextStyle teamName(BuildContext context, {bool isWinner = false}) {
    return context.textTheme.titleMedium?.copyWith(
          color: isWinner ? context.primaryColor : null,
          fontWeight: isWinner ? _semiBold : _medium,
        ) ??
        const TextStyle();
  }

  /// Score display styles
  static TextStyle scoreDisplay(BuildContext context, {bool isWinner = false}) {
    return context.textTheme.headlineLarge?.copyWith(
          color: isWinner ? context.primaryColor : null,
          fontWeight: _bold,
        ) ??
        const TextStyle();
  }

  /// Points display styles
  static TextStyle pointsDisplay(BuildContext context,
      {bool isWinner = false}) {
    return context.textTheme.titleLarge?.copyWith(
          color: isWinner ? context.primaryColor : null,
          fontWeight: isWinner ? _semiBold : null,
        ) ??
        const TextStyle();
  }

  /// Settings label styles
  static TextStyle settingsLabel(BuildContext context) {
    return context.textTheme.titleMedium ?? const TextStyle();
  }

  /// Subtitle styles
  static TextStyle subtitle(BuildContext context) {
    return context.textTheme.bodyMedium?.copyWith(
          color: context.subtleColor,
          fontWeight: _medium,
        ) ??
        const TextStyle();
  }
}

/// Centralized spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Common padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  /// Common margin values
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);

  /// Specific spacing widgets
  static const Widget gapXS = SizedBox(height: xs, width: xs);
  static const Widget gapSM = SizedBox(height: sm, width: sm);
  static const Widget gapMD = SizedBox(height: md, width: md);
  static const Widget gapLG = SizedBox(height: lg, width: lg);
  static const Widget gapXL = SizedBox(height: xl, width: xl);
}
