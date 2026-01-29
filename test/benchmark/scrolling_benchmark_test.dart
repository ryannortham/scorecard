// Scrolling performance benchmark tests
//
// These tests measure widget build and scroll performance for list screens.
// Run with: flutter test test/benchmark/ --reporter expanded

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/widgets/results/results_summary_card.dart';
import 'package:scorecard/widgets/teams/team_logo.dart';

import 'benchmark_utils.dart';
import 'mock_data.dart';

void main() {
  final reporter = BenchmarkReporter();

  group('Results List Performance', () {
    testWidgets('measures initial build time for 50 items', (tester) async {
      final summaries = generateMockGameSummaries(50);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return ResultsSummaryCard(
                  gameSummary: summary,
                  onTap: () {},
                  homeTeamLogoUrl: '',
                  awayTeamLogoUrl: '',
                  shouldShowTrophy: false,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'results_list_initial_build_50',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.listInitialBuildMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.listInitialBuildMs),
        reason:
            'Initial build for 50 items should be under '
            '${BenchmarkThresholds.listInitialBuildMs}ms',
      );
    });

    testWidgets('measures scroll performance', (tester) async {
      final summaries = generateMockGameSummaries(100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return ResultsSummaryCard(
                  gameSummary: summary,
                  onTap: () {},
                  homeTeamLogoUrl: '',
                  awayTeamLogoUrl: '',
                  shouldShowTrophy: false,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      var frameCount = 0;

      // Simulate 10 scroll gestures
      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'results_list_scroll_10x',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.listScrollMs,
          frameCount: frameCount,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.listScrollMs),
        reason:
            '10 scroll gestures should complete under '
            '${BenchmarkThresholds.listScrollMs}ms',
      );
    });

    testWidgets('measures single ResultsSummaryCard build', (tester) async {
      final summary = GameSummary(
        id: 'test_game',
        date: DateTime.now(),
        homeTeam: 'Melbourne',
        awayTeam: 'Richmond',
        homeGoals: 12,
        homeBehinds: 8,
        awayGoals: 10,
        awayBehinds: 5,
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsSummaryCard(
              gameSummary: summary,
              onTap: () {},
              homeTeamLogoUrl: '',
              awayTeamLogoUrl: '',
              shouldShowTrophy: true,
            ),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'results_summary_card_single',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.singleWidgetBuildMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.singleWidgetBuildMs),
        reason:
            'Single card build should be under '
            '${BenchmarkThresholds.singleWidgetBuildMs}ms',
      );
    });
  });

  group('Team List Performance', () {
    testWidgets('measures initial build time for 50 teams', (tester) async {
      final teams = generateMockTeams(50);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Card(
                  child: ListTile(
                    leading: TeamLogo(logoUrl: team.logoUrl, size: 48),
                    title: Text(team.name),
                    trailing: const Icon(Icons.star_border_outlined),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'team_list_initial_build_50',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.listInitialBuildMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.listInitialBuildMs),
        reason:
            'Initial build for 50 teams should be under '
            '${BenchmarkThresholds.listInitialBuildMs}ms',
      );
    });

    testWidgets('measures team list scroll performance', (tester) async {
      final teams = generateMockTeams(100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Card(
                  child: ListTile(
                    // Use null logoUrl to avoid network image loading in tests
                    leading: const TeamLogo(size: 48),
                    title: Text(team.name),
                    trailing: const Icon(Icons.star_border_outlined),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Use pump instead of pumpAndSettle to avoid network image issues
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final stopwatch = Stopwatch()..start();
      var frameCount = 0;

      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }

      // Final frame to settle
      await tester.pump(const Duration(milliseconds: 100));
      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'team_list_scroll_10x',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.listScrollMs,
          frameCount: frameCount,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.listScrollMs),
        reason:
            '10 scroll gestures should complete under '
            '${BenchmarkThresholds.listScrollMs}ms',
      );
    });
  });

  tearDownAll(() async {
    reporter.printSummary();
    await reporter.writeResults('benchmark_results.json');
  });
}
