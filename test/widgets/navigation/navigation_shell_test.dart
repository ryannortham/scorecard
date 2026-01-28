import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

class MockStatefulNavigationShell extends StatefulWidget {
  const MockStatefulNavigationShell({
    required this.currentIndex,
    required this.onGoBranch,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onGoBranch;

  @override
  State<MockStatefulNavigationShell> createState() => _MockStatefulNavigationShellState();
}

class _MockStatefulNavigationShellState extends State<MockStatefulNavigationShell> implements StatefulNavigationShell {
  @override
  int get currentIndex => widget.currentIndex;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    widget.onGoBranch(index);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('NavigationShell should track tab history', (WidgetTester tester) async {
    int currentIndex = 0;
    final List<int> branchesVisited = [];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            final mockShell = _createMockShell(currentIndex, (index) {
              setState(() {
                currentIndex = index;
                branchesVisited.add(index);
              });
            });
            return NavigationShell(
              navigationShell: mockShell,
              child: const Text('Body'),
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

    expect(currentIndex, 1);
    
    // Tap Results tab (index 2)
    await tester.tap(find.byIcon(Icons.emoji_events_outlined));
    await tester.pump();

    expect(currentIndex, 2);

    // Simulate back button press
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump();

    // Should go back to Teams (index 1)
    expect(currentIndex, 1);

    // Simulate back button press again
    await widgetsAppState.didPopRoute();
    await tester.pump();

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
            final mockShell = _createMockShell(currentIndex, (index) {
              setState(() {
                currentIndex = index;
              });
            });
            return NavigationShell(
              navigationShell: mockShell,
              child: const SizedBox.expand(child: Text('Body')),
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
    expect(currentIndex, 1);

    // Simulate edge swipe (left to right from edge)
    await tester.dragFrom(const Offset(5, 100), const Offset(50, 0));
    await tester.pump();

    // Should go back to Scoring (index 0)
    expect(currentIndex, 0);
  });
}

// Helper to create something that looks like StatefulNavigationShell enough for the test
StatefulNavigationShell _createMockShell(int index, void Function(int) onGoBranch) {
  return _FakeStatefulNavigationShell(index, onGoBranch);
}

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
