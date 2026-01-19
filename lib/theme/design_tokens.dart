/// Centralised design system constants for the Score Card application.
///
/// These tokens ensure consistent spacing, radii, and durations across the app.
library;

/// Spacing constants for consistent padding and margins.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// Border radius constants for consistent rounded corners.
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 32.0;
}

/// Animation duration constants for consistent motion.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
}
