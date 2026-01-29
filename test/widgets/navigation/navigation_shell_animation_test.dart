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

    // Find the FractionalTranslation for the incoming child
    final translations = tester.widgetList<FractionalTranslation>(
      find.byType(FractionalTranslation),
    );

    // One of the translations should have a horizontal component on iOS
    var foundHorizontal = false;
    for (final t in translations) {
      if (t.translation.dx != 0 && t.translation.dy == 0) {
        foundHorizontal = true;
        break;
      }
    }
    expect(
      foundHorizontal,
      isTrue,
      reason: 'iOS should have horizontal translation',
    );
  });

  testWidgets(
    'NavigationShell should use shared-axis vertical (Y translate) for Android',
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

      // Android uses shared-axis vertical with Transform.translate
      // (not FractionalTranslation or scale)
      final transforms = tester.widgetList<Transform>(find.byType(Transform));

      // Find a Transform with Y-axis translation (matrix[13] is Y translation)
      var foundYTranslate = false;
      for (final t in transforms) {
        final matrix = t.transform;
        // Matrix4.storage[13] is the Y translation component
        final yTranslation = matrix.storage[13];
        if (yTranslation != 0) {
          foundYTranslate = true;
          break;
        }
      }
      expect(
        foundYTranslate,
        isTrue,
        reason: 'Android should use Y-axis translate for shared-axis vertical',
      );

      // Also verify Opacity widgets are present for the fade effect
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      var foundPartialOpacity = false;
      for (final o in opacities) {
        if (o.opacity > 0.0 && o.opacity < 1.0) {
          foundPartialOpacity = true;
          break;
        }
      }
      expect(
        foundPartialOpacity,
        isTrue,
        reason: 'Android should have opacity animation during transition',
      );
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
