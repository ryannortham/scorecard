import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  testWidgets('NavigationShell should detect forward navigation direction', (WidgetTester tester) async {
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
    final state = tester.state<NavigationShellState>(find.byType(NavigationShell));
    expect(state.currentDirection, NavigationDirection.none);

    // Tap Teams tab (index 1) - Forward
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pump();

    expect(currentIndex, 1);
    expect(state.currentDirection, NavigationDirection.forward);
  });

  testWidgets('NavigationShell should detect backward navigation direction', (WidgetTester tester) async {
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

    // Navigate Forward first
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pump();
    
    final state = tester.state<NavigationShellState>(find.byType(NavigationShell));
    expect(state.currentDirection, NavigationDirection.forward);

    // Simulate back button press - Backward
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump();

    expect(currentIndex, 0);
    expect(state.currentDirection, NavigationDirection.backward);
  });

  testWidgets('NavigationShell should use AnimatedBranchContainer for tab transitions', (WidgetTester tester) async {
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

    // Should find an AnimatedBranchContainer
    expect(find.byType(AnimatedBranchContainer), findsOneWidget);
  });
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