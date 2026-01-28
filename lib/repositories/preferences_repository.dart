// abstract interface for user preferences persistence

import 'package:flutter/material.dart';

/// Immutable data class for all user preferences.
@immutable
class PreferencesData {
  const PreferencesData({
    this.favoriteTeams = const [],
    this.themeMode = ThemeMode.dark,
    this.colorTheme = '',
    this.useTallys = false,
    this.quarterMinutes = 15,
    this.isCountdownTimer = true,
  });

  final List<String> favoriteTeams;
  final ThemeMode themeMode;
  final String colorTheme;
  final bool useTallys;
  final int quarterMinutes;
  final bool isCountdownTimer;

  PreferencesData copyWith({
    List<String>? favoriteTeams,
    ThemeMode? themeMode,
    String? colorTheme,
    bool? useTallys,
    int? quarterMinutes,
    bool? isCountdownTimer,
  }) {
    return PreferencesData(
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      themeMode: themeMode ?? this.themeMode,
      colorTheme: colorTheme ?? this.colorTheme,
      useTallys: useTallys ?? this.useTallys,
      quarterMinutes: quarterMinutes ?? this.quarterMinutes,
      isCountdownTimer: isCountdownTimer ?? this.isCountdownTimer,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreferencesData) return false;
    return _listEquals(favoriteTeams, other.favoriteTeams) &&
        themeMode == other.themeMode &&
        colorTheme == other.colorTheme &&
        useTallys == other.useTallys &&
        quarterMinutes == other.quarterMinutes &&
        isCountdownTimer == other.isCountdownTimer;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(favoriteTeams),
    themeMode,
    colorTheme,
    useTallys,
    quarterMinutes,
    isCountdownTimer,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Repository interface for user preferences persistence.
///
/// Abstracts storage implementation to enable testing and
/// potential future storage backends.
abstract class PreferencesRepository {
  /// Loads all user preferences.
  Future<PreferencesData> load();

  /// Saves all user preferences.
  Future<void> save(PreferencesData data);

  /// Loads legacy single favourite team for migration.
  /// Returns null if no legacy data exists.
  Future<String?> loadLegacyFavoriteTeam();

  /// Removes legacy favourite team after migration.
  Future<void> removeLegacyFavoriteTeam();
}
