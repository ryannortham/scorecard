// centralised design system constants

/// spacing constants for consistent padding and margins
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// border radius constants for consistent rounded corners
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 32;
}

/// animation duration constants for consistent motion
class AppDurations {
  AppDurations._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  // snackbar durations
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarMedium = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 4);
}

/// game-specific constants
class AppGameConstants {
  AppGameConstants._();

  static const int pointsPerGoal = 6;
  static const int pointsPerBehind = 1;
  static const int quartersPerGame = 4;
}
