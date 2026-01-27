// tests for PreferencesViewModel with mock repository

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/repositories/preferences_repository.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';

import '../mocks/mock_preferences_repository.dart';

void main() {
  group('PreferencesViewModel', () {
    group('initialisation', () {
      test('should load preferences from repository on creation', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(
            favoriteTeams: ['Richmond'],
            themeMode: ThemeMode.dark,
            quarterMinutes: 20,
          ),
        );

        final provider = PreferencesViewModel(repository: repository);

        // Wait for async initialisation (includes dynamic color check)
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(provider.favoriteTeams, equals(['Richmond']));
        expect(provider.themeMode, equals(ThemeMode.dark));
        expect(provider.quarterMinutes, equals(20));
        expect(provider.loaded, isTrue);
      });

      test(
        'should use default values when repository returns defaults',
        () async {
          final repository = MockPreferencesRepository();

          final provider = PreferencesViewModel(repository: repository);

          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(provider.favoriteTeams, isEmpty);
          expect(provider.themeMode, equals(ThemeMode.system));
          expect(provider.quarterMinutes, equals(15));
          expect(provider.useTallys, isTrue);
          expect(provider.isCountdownTimer, isTrue);
        },
      );

      test('should migrate legacy single favourite team', () async {
        final repository = MockPreferencesRepository(
          legacyFavoriteTeam: 'Collingwood',
        );

        final provider = PreferencesViewModel(repository: repository);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(provider.favoriteTeams, equals(['Collingwood']));
        // Should have saved migrated favourites
        expect(repository.saveHistory.isNotEmpty, isTrue);
        // Legacy favourite should be removed
        final legacy = await repository.loadLegacyFavoriteTeam();
        expect(legacy, isNull);
      });
    });

    group('favorite teams', () {
      test('should add team to favourites', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.addFavoriteTeam('Melbourne');

        expect(provider.favoriteTeams, contains('Melbourne'));
        expect(repository.saveHistory.isNotEmpty, isTrue);
      });

      test('should not add duplicate favourite team', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(favoriteTeams: ['Sydney']),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final saveCountBefore = repository.saveHistory.length;
        await provider.addFavoriteTeam('Sydney');

        expect(provider.favoriteTeams.length, equals(1));
        expect(repository.saveHistory.length, equals(saveCountBefore));
      });

      test('should remove team from favourites', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(
            favoriteTeams: ['Brisbane', 'Geelong'],
          ),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.removeFavoriteTeam('Brisbane');

        expect(provider.favoriteTeams, equals(['Geelong']));
      });

      test('should toggle favourite status', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(favoriteTeams: ['Hawthorn']),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Toggle off
        await provider.toggleFavoriteTeam('Hawthorn');
        expect(provider.favoriteTeams, isEmpty);

        // Toggle on
        await provider.toggleFavoriteTeam('Hawthorn');
        expect(provider.favoriteTeams, contains('Hawthorn'));
      });

      test('should check if team is favourite', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(favoriteTeams: ['Carlton']),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(provider.isFavoriteTeam('Carlton'), isTrue);
        expect(provider.isFavoriteTeam('Essendon'), isFalse);
      });

      test('should return default favourite team', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(
            favoriteTeams: ['First', 'Second'],
          ),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(provider.getDefaultFavoriteTeam(), equals('First'));
      });

      test('should return null when no favourite teams', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(provider.getDefaultFavoriteTeam(), isNull);
      });
    });

    group('theme settings', () {
      test('should set theme mode', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.setThemeMode(ThemeMode.light);

        expect(provider.themeMode, equals(ThemeMode.light));
        expect(repository.saveHistory.isNotEmpty, isTrue);
      });

      test('should set color theme', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.setColorTheme('ocean');

        // Note: colorTheme may be validated/transformed by ColorService
        expect(repository.saveHistory.isNotEmpty, isTrue);
      });
    });

    group('game preferences', () {
      test('should set quarter minutes', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.setQuarterMinutes(25);

        expect(provider.quarterMinutes, equals(25));
        expect(repository.saveHistory.isNotEmpty, isTrue);
      });

      test('should set countdown timer mode', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.setIsCountdownTimer(value: false);

        expect(provider.isCountdownTimer, isFalse);
      });

      test('should set use tallys preference', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await provider.setUseTallys(value: false);

        expect(provider.useTallys, isFalse);
      });
    });

    group('listener notifications', () {
      test('should notify listeners when preferences change', () async {
        final repository = MockPreferencesRepository();
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.addFavoriteTeam('North Melbourne');
        await provider.setThemeMode(ThemeMode.dark);
        await provider.setQuarterMinutes(18);

        expect(notifyCount, equals(3));
      });
    });

    group('favouriteTeams immutability', () {
      test('should return unmodifiable list', () async {
        final repository = MockPreferencesRepository(
          initialData: const PreferencesData(favoriteTeams: ['Test']),
        );
        final provider = PreferencesViewModel(repository: repository);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          () => provider.favoriteTeams.add('Another'),
          throwsUnsupportedError,
        );
      });
    });
  });
}
