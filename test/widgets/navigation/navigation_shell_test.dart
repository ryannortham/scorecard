import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  group('NavigationShell tab history', () {
    testWidgets('should track tab history and provide info', (
      WidgetTester tester,
    ) async {
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
                  _TestScreen(title: 'Scoring', index: 0),
                  _TestScreen(title: 'Teams', index: 1),
                  _TestScreen(title: 'Results', index: 2),
                ],
              );
            },
          ),
        ),
      );

      // Initial state
      expect(currentIndex, 0);
      expect(find.byTooltip('Back'), findsNothing);

      // Tap Teams tab (index 1)
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();

      expect(currentIndex, 1);
      expect(find.byTooltip('Back'), findsOneWidget);

      // Tap the back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(currentIndex, 0);
      expect(find.byTooltip('Back'), findsNothing);

      // Navigate to Teams again
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(currentIndex, 1);

      // Simulate system back button press
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

      // ignore: avoid_dynamic_calls, needed to simulate back button press
      final handled1 = await (widgetsAppState.didPopRoute() as Future<bool>);
      await tester.pumpAndSettle();
      expect(
        handled1,
        isTrue,
        reason: 'System back press should be intercepted',
      );
      expect(currentIndex, 0);

      // Final system back button press (at root)
      // ignore: avoid_dynamic_calls, needed to simulate back button press
      final handled2 = await (widgetsAppState.didPopRoute() as Future<bool>);
      await tester.pumpAndSettle();

      // It should be intercepted because we use canPop: false and handle
      // exit manually
      expect(
        handled2,
        isTrue,
        reason: 'Root back press should be intercepted for manual exit',
      );
    });
  });

  group('Platform-specific back gesture handling', () {
    testWidgets(
      'Android: system back from Teams tab should return to Scoring tab',
      (WidgetTester tester) async {
        var currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
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
                    _TestScreen(title: 'Scoring', index: 0),
                    _TestScreen(title: 'Teams', index: 1),
                    _TestScreen(title: 'Results', index: 2),
                  ],
                );
              },
            ),
          ),
        );

        // Initial state - at Scoring tab (index 0)
        expect(currentIndex, 0);

        // Navigate to Teams tab (index 1)
        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();
        expect(currentIndex, 1);

        // Simulate Android system back gesture
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        // ignore: avoid_dynamic_calls, needed to simulate back button press
        final handled = await (widgetsAppState.didPopRoute() as Future<bool>);
        await tester.pumpAndSettle();

        // Back should be intercepted and return to Scoring tab
        expect(
          handled,
          isTrue,
          reason: 'Android back gesture should be intercepted',
        );
        expect(
          currentIndex,
          0,
          reason: 'Should return to Scoring tab, not close app',
        );
      },
    );

    testWidgets(
      'Android: system back from Results tab should return to previous tab',
      (WidgetTester tester) async {
        var currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.android),
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
                    _TestScreen(title: 'Scoring', index: 0),
                    _TestScreen(title: 'Teams', index: 1),
                    _TestScreen(title: 'Results', index: 2),
                  ],
                );
              },
            ),
          ),
        );

        // Navigate: Scoring -> Teams -> Results
        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();
        expect(currentIndex, 1);

        await tester.tap(find.byIcon(Icons.emoji_events_outlined));
        await tester.pumpAndSettle();
        expect(currentIndex, 2);

        // Simulate Android system back gesture from Results
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        // ignore: avoid_dynamic_calls, needed to simulate back button press
        final handled = await (widgetsAppState.didPopRoute() as Future<bool>);
        await tester.pumpAndSettle();

        // Back should return to Teams tab (previous in history)
        expect(
          handled,
          isTrue,
          reason: 'Android back gesture should be intercepted',
        );
        expect(
          currentIndex,
          1,
          reason: 'Should return to Teams tab (previous in history)',
        );
      },
    );

    testWidgets(
      'iOS: system back from Teams tab should return to Scoring tab',
      (WidgetTester tester) async {
        var currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
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
                    _TestScreen(title: 'Scoring', index: 0),
                    _TestScreen(title: 'Teams', index: 1),
                    _TestScreen(title: 'Results', index: 2),
                  ],
                );
              },
            ),
          ),
        );

        // Navigate to Teams tab
        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();
        expect(currentIndex, 1);

        // Simulate iOS system back
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        // ignore: avoid_dynamic_calls, needed to simulate back button press
        final handled = await (widgetsAppState.didPopRoute() as Future<bool>);
        await tester.pumpAndSettle();

        expect(
          handled,
          isTrue,
          reason: 'iOS back should be intercepted',
        );
        expect(
          currentIndex,
          0,
          reason: 'Should return to Scoring tab',
        );
      },
    );

    testWidgets(
      'iOS: system back from Results tab should return to previous tab',
      (WidgetTester tester) async {
        var currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
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
                    _TestScreen(title: 'Scoring', index: 0),
                    _TestScreen(title: 'Teams', index: 1),
                    _TestScreen(title: 'Results', index: 2),
                  ],
                );
              },
            ),
          ),
        );

        // Navigate: Scoring -> Teams -> Results
        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.emoji_events_outlined));
        await tester.pumpAndSettle();
        expect(currentIndex, 2);

        // Simulate iOS system back from Results
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        // ignore: avoid_dynamic_calls, needed to simulate back button press
        final handled = await (widgetsAppState.didPopRoute() as Future<bool>);
        await tester.pumpAndSettle();

        expect(
          handled,
          isTrue,
          reason: 'iOS back should be intercepted',
        );
        expect(
          currentIndex,
          1,
          reason: 'Should return to Teams tab (previous in history)',
        );
      },
    );
  });

  group('handleBack() helper method', () {
    testWidgets('handleBack calls popTab when not in selection mode', (
      WidgetTester tester,
    ) async {
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
                  _TestScreen(title: 'Scoring', index: 0),
                  _TestScreen(title: 'Teams', index: 1),
                  _TestScreen(title: 'Results', index: 2),
                ],
              );
            },
          ),
        ),
      );

      // Navigate to Teams tab
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(currentIndex, 1);

      // Get the navigation shell state and call handleBack
      tester
          .state<NavigationShellState>(find.byType(NavigationShell))
          .handleBack();
      await tester.pumpAndSettle();

      // Should have navigated back to Scoring tab
      expect(currentIndex, 0);
    });

    testWidgets('handleBack calls onExitSelectionMode when in selection mode', (
      WidgetTester tester,
    ) async {
      var currentIndex = 0;
      var exitSelectionModeCalled = false;

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
                  _TestScreen(title: 'Scoring', index: 0),
                  _TestScreen(title: 'Teams', index: 1),
                  _TestScreen(title: 'Results', index: 2),
                ],
              );
            },
          ),
        ),
      );

      // Navigate to Teams tab
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(currentIndex, 1);

      // Get the navigation shell state and call handleBack with selection mode
      tester
          .state<NavigationShellState>(find.byType(NavigationShell))
          .handleBack(
            isInSelectionMode: true,
            onExitSelectionMode: () => exitSelectionModeCalled = true,
          );
      await tester.pumpAndSettle();

      // Should have called exit selection mode, NOT navigated back
      expect(exitSelectionModeCalled, isTrue);
      expect(currentIndex, 1, reason: 'Should stay on Teams tab');
    });
  });
}

class _TestScreen extends StatelessWidget {
  const _TestScreen({required this.title, required this.index});
  final String title;
  final int index;

  @override
  Widget build(BuildContext context) {
    final navState = NavigationShellInfo.of(context);
    final canPop = navState?.canPopTab ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading:
            canPop
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => navState?.popTab(),
                  tooltip: 'Back',
                )
                : null,
      ),
      body: Center(child: Text('Screen $index')),
    );
  }
}

// Helper to create something that looks like StatefulNavigationShell enough
// for the test
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
