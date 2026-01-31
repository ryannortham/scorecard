import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  testWidgets('NavigationShell should use horizontal slide for iOS', (
    WidgetTester tester,
  ) async {
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
                Text('Scoring'),
                Text('Teams'),
                Text('Results'),
              ],
            );
          },
        ),
      ),
    );

    // Initial state
    expect(currentIndex, 0);

    // Tap Teams tab (index 1)
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // iOS uses SlideTransition for horizontal slide animation
    final slideTransitions = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    );

    // One of the SlideTransitions should have a horizontal component on iOS
    var foundHorizontal = false;
    for (final t in slideTransitions) {
      final position = t.position.value;
      if (position.dx != 0 && position.dy == 0) {
        foundHorizontal = true;
        break;
      }
    }
    expect(
      foundHorizontal,
      isTrue,
      reason: 'iOS should have horizontal SlideTransition',
    );

    // Should also have FadeTransition for the fade effect
    final fadeTransitions = tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(
      fadeTransitions.isNotEmpty,
      isTrue,
      reason: 'iOS should have FadeTransition for opacity animation',
    );
  });

  testWidgets(
    'NavigationShell should use SharedAxisTransition for Android',
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
                  Text('Scoring'),
                  Text('Teams'),
                  Text('Results'),
                ],
              );
            },
          ),
        ),
      );

      // Initial state
      expect(currentIndex, 0);

      // Tap Teams tab (index 1)
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Android should use SharedAxisTransition from animations package
      final sharedAxisTransitions = tester.widgetList<SharedAxisTransition>(
        find.byType(SharedAxisTransition),
      );

      expect(
        sharedAxisTransitions.isNotEmpty,
        isTrue,
        reason: 'Android should use SharedAxisTransition for tab animations',
      );

      // Verify it's using vertical axis
      for (final t in sharedAxisTransitions) {
        expect(
          t.transitionType,
          SharedAxisTransitionType.vertical,
          reason: 'Android should use vertical shared-axis transition',
        );
      }
    },
  );

  testWidgets('NavigationShell should detect forward navigation direction', (
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
              children: const [Text('Scoring'), Text('Teams'), Text('Results')],
            );
          },
        ),
      ),
    );

    // Initial state
    final state = tester.state<NavigationShellState>(
      find.byType(NavigationShell),
    );
    expect(state.currentDirection, NavigationDirection.none);

    // Tap Teams tab (index 1) - Forward
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pump();

    expect(currentIndex, 1);
    expect(state.currentDirection, NavigationDirection.forward);
  });

  testWidgets(
    'NavigationShell should wrap animated children in RepaintBoundary',
    (WidgetTester tester) async {
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
                  Text('Scoring'),
                  Text('Teams'),
                  Text('Results'),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // RepaintBoundary should be present to isolate child repaints
      // from animation repaints
      final repaintBoundaries = tester.widgetList<RepaintBoundary>(
        find.byType(RepaintBoundary),
      );

      // Should have at least one RepaintBoundary for the visible child
      // (within the AnimatedBranchItem widget tree)
      expect(
        repaintBoundaries.isNotEmpty,
        isTrue,
        reason:
            'RepaintBoundary should wrap animated children to isolate repaints',
      );
    },
  );

  testWidgets('NavigationShell should detect backward navigation direction', (
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
              children: const [Text('Scoring'), Text('Teams'), Text('Results')],
            );
          },
        ),
      ),
    );

    // Navigate Forward first
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pump();

    final state = tester.state<NavigationShellState>(
      find.byType(NavigationShell),
    );
    expect(state.currentDirection, NavigationDirection.forward);

    // Simulate back button press - Backward
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    // ignore: avoid_dynamic_calls, needed to simulate back button press
    await (widgetsAppState.didPopRoute() as Future<bool>);
    await tester.pump();

    expect(currentIndex, 0);
    expect(state.currentDirection, NavigationDirection.backward);
  });
}

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
