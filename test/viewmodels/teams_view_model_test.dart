// tests for TeamsViewModel with mock repository

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';

import '../mocks/mock_team_repository.dart';

void main() {
  group('TeamsViewModel', () {
    group('initialisation', () {
      test('should load teams from repository on creation', () async {
        final repository = MockTeamRepository(
          initialTeams: [
            const Team(name: 'Richmond'),
            const Team(name: 'Carlton'),
          ],
        );

        final provider = TeamsViewModel(repository: repository);

        // Wait for async initialisation
        await Future<void>.delayed(Duration.zero);

        expect(provider.teams.length, equals(2));
        expect(provider.teamNames, equals(['Richmond', 'Carlton']));
        expect(provider.loaded, isTrue);
        expect(repository.loadTeamsCallCount, equals(1));
      });

      test('should handle empty teams list', () async {
        final repository = MockTeamRepository();

        final provider = TeamsViewModel(repository: repository);

        await Future<void>.delayed(Duration.zero);

        expect(provider.teams, isEmpty);
        expect(provider.loaded, isTrue);
      });

      test('should migrate legacy team names on first load', () async {
        final repository = MockTeamRepository(
          legacyTeamNames: ['Collingwood', 'Essendon'],
        );

        final provider = TeamsViewModel(repository: repository);

        await Future<void>.delayed(Duration.zero);

        expect(provider.teams.length, equals(2));
        expect(provider.teamNames, equals(['Collingwood', 'Essendon']));
        // Should have saved migrated teams
        expect(repository.saveHistory.length, equals(1));
        // Legacy names should be removed
        final legacyNames = await repository.loadLegacyTeamNames();
        expect(legacyNames, isNull);
      });

      test('should not migrate if teams already exist', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Hawthorn')],
          legacyTeamNames: ['Old Team'],
        );

        final provider = TeamsViewModel(repository: repository);

        await Future<void>.delayed(Duration.zero);

        expect(provider.teams.length, equals(1));
        expect(provider.teamNames, equals(['Hawthorn']));
        // Should not have saved (no migration needed)
        expect(repository.saveHistory, isEmpty);
      });
    });

    group('addTeam', () {
      test('should add a new team with just name', () async {
        final repository = MockTeamRepository();
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.addTeam('Melbourne');

        expect(provider.teams.length, equals(1));
        expect(provider.teams.first.name, equals('Melbourne'));
        expect(repository.saveHistory.length, equals(1));
      });

      test('should add a team with all optional fields', () async {
        final repository = MockTeamRepository();
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.addTeam(
          'Sydney',
          logoUrl: 'https://example.com/logo.png',
          logoUrl32: 'https://example.com/logo32.png',
          playHQId: 'phq123',
        );

        expect(provider.teams.first.name, equals('Sydney'));
        expect(
          provider.teams.first.logoUrl,
          equals('https://example.com/logo.png'),
        );
        expect(provider.teams.first.playHQId, equals('phq123'));
      });

      test('should notify listeners when team is added', () async {
        final repository = MockTeamRepository();
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.addTeam('Brisbane');

        expect(notifyCount, equals(1));
      });
    });

    group('editTeam', () {
      test('should edit an existing team', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Old Name')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.editTeam(0, 'New Name');

        expect(provider.teams.first.name, equals('New Name'));
        expect(repository.saveHistory.length, equals(1));
      });

      test('should update optional fields when editing', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Geelong')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.editTeam(
          0,
          'Geelong Cats',
          logoUrl: 'https://example.com/cats.png',
        );

        expect(provider.teams.first.name, equals('Geelong Cats'));
        expect(
          provider.teams.first.logoUrl,
          equals('https://example.com/cats.png'),
        );
      });

      test('should do nothing for invalid index', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Test')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.editTeam(5, 'Invalid');

        expect(provider.teams.first.name, equals('Test'));
        expect(repository.saveHistory, isEmpty);
      });

      test('should handle negative index gracefully', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Test')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.editTeam(-1, 'Invalid');

        expect(provider.teams.first.name, equals('Test'));
        expect(repository.saveHistory, isEmpty);
      });
    });

    group('deleteTeam', () {
      test('should delete team at index', () async {
        final repository = MockTeamRepository(
          initialTeams: [
            const Team(name: 'First'),
            const Team(name: 'Second'),
          ],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.deleteTeam(0);

        expect(provider.teams.length, equals(1));
        expect(provider.teams.first.name, equals('Second'));
        expect(repository.saveHistory.length, equals(1));
      });

      test('should do nothing for invalid index', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Test')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        await provider.deleteTeam(5);

        expect(provider.teams.length, equals(1));
        expect(repository.saveHistory, isEmpty);
      });
    });

    group('findTeamByName', () {
      test('should find existing team by name', () async {
        final repository = MockTeamRepository(
          initialTeams: [
            const Team(
              name: 'Port Adelaide',
              logoUrl: 'https://example.com/pa',
            ),
          ],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        final team = provider.findTeamByName('Port Adelaide');

        expect(team, isNotNull);
        expect(team!.name, equals('Port Adelaide'));
        expect(team.logoUrl, equals('https://example.com/pa'));
      });

      test('should return null for non-existent team', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Fremantle')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        final team = provider.findTeamByName('Non Existent');

        expect(team, isNull);
      });
    });

    group('hasTeamWithName', () {
      test('should return true for existing team', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'Gold Coast')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        expect(provider.hasTeamWithName('Gold Coast'), isTrue);
      });

      test('should return false for non-existent team', () async {
        final repository = MockTeamRepository(
          initialTeams: [const Team(name: 'GWS')],
        );
        final provider = TeamsViewModel(repository: repository);
        await Future<void>.delayed(Duration.zero);

        expect(provider.hasTeamWithName('Unknown'), isFalse);
      });
    });
  });
}
