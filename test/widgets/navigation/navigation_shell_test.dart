import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  testWidgets('NavigationShell should track tab history', (WidgetTester tester) async {
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            final mockShell = _FakeStatefulNavigationShell(currentIndex, (index) {
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
    expect(currentIndex, 0);

    // Tap Teams tab (index 1)
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(currentIndex, 1);
    
    // Tap Results tab (index 2)
    await tester.tap(find.byIcon(Icons.emoji_events_outlined));
    await tester.pumpAndSettle();

    expect(currentIndex, 2);

    // Simulate back button press
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Should go back to Teams (index 1)
    expect(currentIndex, 1);

    // Simulate back button press again
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Should go back to Scoring (index 0)
    expect(currentIndex, 0);
  });

  testWidgets('NavigationShell should handle edge swipe on iOS', (WidgetTester tester) async {
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: StatefulBuilder(
          builder: (context, setState) {
            // IMPORTANT: Create a new instance every build to ensure didUpdateWidget 
            // sees a change in the navigationShell object itself if index changes.
            final mockShell = _FakeStatefulNavigationShell(currentIndex, (index) {
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
    expect(currentIndex, 0);

    // Tap Teams tab (index 1)
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(currentIndex, 1);

    // Simulate edge swipe (left to right from edge)
    final gesture = await tester.startGesture(const Offset(5, 100));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Should go back to Scoring (index 0)
    expect(currentIndex, 0);
  });
}

// Helper to create something that looks like StatefulNavigationShell enough for the test
class _FakeStatefulNavigationShell extends Fake implements StatefulNavigationShell {
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
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => super.toString();
}