// mock implementation of PreferencesRepository for testing

import 'package:scorecard/repositories/preferences_repository.dart';

/// In-memory mock implementation of [PreferencesRepository] for testing.
class MockPreferencesRepository implements PreferencesRepository {
  MockPreferencesRepository({
    PreferencesData? initialData,
    String? legacyFavoriteTeam,
  }) : _data = initialData ?? const PreferencesData(),
       _legacyFavoriteTeam = legacyFavoriteTeam;

  PreferencesData _data;
  String? _legacyFavoriteTeam;

  /// Tracks all save operations for verification in tests.
  final List<PreferencesData> saveHistory = [];

  /// Number of times load was called.
  int loadCallCount = 0;

  @override
  Future<PreferencesData> load() async {
    loadCallCount++;
    return _data;
  }

  @override
  Future<void> save(PreferencesData data) async {
    _data = data;
    saveHistory.add(data);
  }

  @override
  Future<String?> loadLegacyFavoriteTeam() async {
    return _legacyFavoriteTeam;
  }

  @override
  Future<void> removeLegacyFavoriteTeam() async {
    _legacyFavoriteTeam = null;
  }

  /// Returns the current data (for test verification).
  PreferencesData get currentData => _data;
}
