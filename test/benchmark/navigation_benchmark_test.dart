// Navigation and screen transition performance benchmark tests
//
// These tests measure the performance of navigating between screens and tabs.
// Run with: flutter test test/benchmark/ --reporter expanded

@Tags(['benchmark'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

import 'benchmark_utils.dart';

void main() {
  final reporter = BenchmarkReporter();

  group('Screen Transition Performance', () {
    testWidgets('measures tab switch animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TabTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Tap on second tab
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Tap on third tab
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Return to first tab
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'tab_switch_3x',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.tabNavigationMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.tabNavigationMs),
        reason:
            '3 tab switches should complete under '
            '${BenchmarkThresholds.tabNavigationMs}ms',
      );
    });

    testWidgets('measures page push/pop transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NavigationTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Push to detail page
      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'page_push_pop',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.screenTransitionMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.screenTransitionMs),
        reason:
            'Push/pop navigation should complete under '
            '${BenchmarkThresholds.screenTransitionMs}ms',
      );
    });

    testWidgets('measures rapid navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _NavigationTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      var navigationCount = 0;

      // Perform 5 push/pop cycles with proper settling
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Go to Detail'));
        await tester.pumpAndSettle();
        navigationCount++;

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        navigationCount++;
      }

      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'rapid_navigation_5x',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.screenTransitionMs * 5,
          metadata: {'navigation_count': navigationCount},
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.screenTransitionMs * 5),
        reason:
            '5 navigation cycles should complete under '
            '${BenchmarkThresholds.screenTransitionMs * 5}ms',
      );
    });

    testWidgets('measures NavigationShell tab transitions', (tester) async {
      var currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final mockShell = _FakeStatefulNavigationShell(currentIndex, (
                index,
              ) {
                setState(() {
                  currentIndex = index;
                });
              });
              return NavigationShell(
                navigationShell: mockShell,
                children: const [
                  Center(child: Text('Scoring')),
                  Center(child: Text('Teams')),
                  Center(child: Text('Results')),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Navigate through tabs: Scoring -> Teams -> Results -> Scoring
      // Using the actual icons from BottomNavBar
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();

      // Tap on Scoring label text to go back (FootballIcon is custom widget)
      await tester.tap(find.text('Scoring'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      reporter.record(
        BenchmarkResult(
          name: 'navigation_shell_tab_switch_3x',
          durationMs: stopwatch.elapsedMilliseconds,
          thresholdMs: BenchmarkThresholds.tabNavigationMs,
        ),
      );

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(BenchmarkThresholds.tabNavigationMs),
        reason:
            'NavigationShell 3 tab switches should complete under '
            '${BenchmarkThresholds.tabNavigationMs}ms',
      );
    });
  });

  tearDownAll(() async {
    reporter.printSummary();
    await reporter.writeResults('navigation_benchmark_results.json');
  });
}

/// Test widget with bottom navigation tabs.
class _TabTestWidget extends StatefulWidget {
  @override
  State<_TabTestWidget> createState() => _TabTestWidgetState();
}

class _TabTestWidgetState extends State<_TabTestWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(child: Text('Home')),
          Center(child: Text('List')),
          Center(child: Text('Settings')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Test widget for push/pop navigation.
class _NavigationTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder:
                    (context) => Scaffold(
                      appBar: AppBar(
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text('Detail'),
                      ),
                      body: const Center(child: Text('Detail Page')),
                    ),
              ),
            );
          },
          child: const Text('Go to Detail'),
        ),
      ),
    );
  }
}

/// Fake StatefulNavigationShell for testing NavigationShell widget.
class _FakeStatefulNavigationShell extends Fake
    implements StatefulNavigationShell {
  _FakeStatefulNavigationShell(this._currentIndex, this._onGoBranch);

  final int _currentIndex;
  final void Function(int) _onGoBranch;

  @override
  int get currentIndex => _currentIndex;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    _onGoBranch(index);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}
