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
              child: const Text('Body'),
            );
          },
        ),
      ),
    );

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
              child: const Text('Body'),
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
}

// Internal classes for testing - need to be accessible or mocked
// Since _NavigationShellState is private, I might need to make it public or use a different approach.
// For now, I'll assume I'll make it public for testing or add a getter to the widget if possible.
// Actually, I'll make it public: NavigationShellState.

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
