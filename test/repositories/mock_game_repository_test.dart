// tests for MockGameRepository (validates mock behaviour for tests)

import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/game_record.dart';

import '../mocks/mock_game_repository.dart';

void main() {
  group('MockGameRepository', () {
    late MockGameRepository repository;

    setUp(() {
      repository = MockGameRepository();
    });

    GameRecord createTestGame({
      required String id,
      String homeTeam = 'Richmond',
      String awayTeam = 'Carlton',
      DateTime? date,
    }) {
      return GameRecord(
        id: id,
        date: date ?? DateTime(2024, 6, 15),
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeGoals: 10,
        homeBehinds: 8,
        awayGoals: 8,
        awayBehinds: 12,
        quarterMinutes: 20,
        isCountdownTimer: true,
        events: const [],
      );
    }

    group('saveGame', () {
      test('should save a new game', () async {
        final game = createTestGame(id: 'game-1');

        await repository.saveGame(game);

        expect(repository.currentGames.length, equals(1));
        expect(repository.currentGames.first.id, equals('game-1'));
      });

      test('should track save history', () async {
        final game1 = createTestGame(id: 'game-1');
        final game2 = createTestGame(id: 'game-2');

        await repository.saveGame(game1);
        await repository.saveGame(game2);

        expect(repository.saveHistory.length, equals(2));
      });

      test('should replace existing game with same ID', () async {
        final original = createTestGame(id: 'game-1', homeTeam: 'Original');
        final updated = createTestGame(id: 'game-1', homeTeam: 'Updated');

        await repository.saveGame(original);
        await repository.saveGame(updated);

        expect(repository.currentGames.length, equals(1));
        expect(repository.currentGames.first.homeTeam, equals('Updated'));
      });
    });

    group('loadGameById', () {
      test('should load existing game', () async {
        final game = createTestGame(id: 'game-1');
        await repository.saveGame(game);

        final loaded = await repository.loadGameById('game-1');

        expect(loaded, isNotNull);
        expect(loaded!.id, equals('game-1'));
        expect(repository.loadGameByIdCallCount, equals(1));
      });

      test('should return null for non-existent game', () async {
        final loaded = await repository.loadGameById('non-existent');

        expect(loaded, isNull);
      });
    });

    group('loadAllGames', () {
      test('should load all games sorted by date descending', () async {
        final game1 = createTestGame(id: 'game-1', date: DateTime(2024, 1, 15));
        final game2 = createTestGame(id: 'game-2'); // Uses default date
        final game3 = createTestGame(id: 'game-3', date: DateTime(2024, 3, 10));

        await repository.saveGame(game1);
        await repository.saveGame(game2);
        await repository.saveGame(game3);

        final games = await repository.loadAllGames();

        expect(games.length, equals(3));
        expect(games[0].id, equals('game-2')); // Latest first
        expect(games[1].id, equals('game-3'));
        expect(games[2].id, equals('game-1')); // Oldest last
        expect(repository.loadAllGamesCallCount, equals(1));
      });

      test('should return empty list when no games', () async {
        final games = await repository.loadAllGames();

        expect(games, isEmpty);
      });
    });

    group('loadGameSummaries', () {
      test('should return summaries with pagination', () async {
        for (var i = 0; i < 25; i++) {
          await repository.saveGame(
            createTestGame(
              id: 'game-$i',
              date: DateTime(2024, 2, 15).add(Duration(days: i)),
            ),
          );
        }

        final page1 = await repository.loadGameSummaries(limit: 10);
        final page2 = await repository.loadGameSummaries(limit: 10, offset: 10);
        final page3 = await repository.loadGameSummaries(limit: 10, offset: 20);

        expect(page1.length, equals(10));
        expect(page2.length, equals(10));
        expect(page3.length, equals(5)); // Only 5 remaining
      });

      test('should exclude specified game ID', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(createTestGame(id: 'game-2'));
        await repository.saveGame(createTestGame(id: 'game-3'));

        final summaries = await repository.loadGameSummaries(
          excludeGameId: 'game-2',
        );

        expect(summaries.length, equals(2));
        expect(summaries.any((s) => s.id == 'game-2'), isFalse);
      });

      test('should convert GameRecord to GameSummary correctly', () async {
        final game = GameRecord(
          id: 'test-game',
          date: DateTime(2024, 6, 15),
          homeTeam: 'Collingwood',
          awayTeam: 'Essendon',
          homeGoals: 15,
          homeBehinds: 10,
          awayGoals: 12,
          awayBehinds: 8,
          quarterMinutes: 20,
          isCountdownTimer: true,
          events: const [],
        );
        await repository.saveGame(game);

        final summaries = await repository.loadGameSummaries();

        expect(summaries.length, equals(1));
        final summary = summaries.first;
        expect(summary.id, equals('test-game'));
        expect(summary.homeTeam, equals('Collingwood'));
        expect(summary.awayTeam, equals('Essendon'));
        expect(summary.homeGoals, equals(15));
        expect(summary.homeBehinds, equals(10));
        expect(summary.homePoints, equals(15 * 6 + 10)); // 100
        expect(summary.awayPoints, equals(12 * 6 + 8)); // 80
      });
    });

    group('deleteGame', () {
      test('should delete existing game', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(createTestGame(id: 'game-2'));

        await repository.deleteGame('game-1');

        expect(repository.currentGames.length, equals(1));
        expect(repository.currentGames.first.id, equals('game-2'));
      });

      test('should do nothing for non-existent game', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));

        await repository.deleteGame('non-existent');

        expect(repository.currentGames.length, equals(1));
      });
    });

    group('clearAllGames', () {
      test('should remove all games', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(createTestGame(id: 'game-2'));

        await repository.clearAllGames();

        expect(repository.currentGames, isEmpty);
      });
    });

    group('getGameCount', () {
      test('should return total game count', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(createTestGame(id: 'game-2'));
        await repository.saveGame(createTestGame(id: 'game-3'));

        final count = await repository.getGameCount();

        expect(count, equals(3));
      });
    });

    group('getValidGameCount', () {
      test('should count only games with team data', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(
          createTestGame(
            id: 'game-2',
            homeTeam: '',
            awayTeam: '',
          ),
        );

        final count = await repository.getValidGameCount();

        expect(count, equals(1));
      });

      test('should exclude specified game from count', () async {
        await repository.saveGame(createTestGame(id: 'game-1'));
        await repository.saveGame(createTestGame(id: 'game-2'));

        final count = await repository.getValidGameCount(
          excludeGameId: 'game-1',
        );

        expect(count, equals(1));
      });
    });

    group('initialGames constructor', () {
      test('should initialise with provided games', () async {
        final initialGames = [
          createTestGame(id: 'preset-1'),
          createTestGame(id: 'preset-2'),
        ];

        final repo = MockGameRepository(initialGames: initialGames);

        expect(repo.currentGames.length, equals(2));
        final loaded = await repo.loadGameById('preset-1');
        expect(loaded, isNotNull);
      });
    });
  });
}
