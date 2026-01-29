import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  testWidgets('NavigationShell should track tab history', (
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

    // ignore: avoid_dynamic_calls, needed to simulate back button press
    final handled1 = await (widgetsAppState.didPopRoute() as Future<bool>);
    await tester.pumpAndSettle();
    expect(handled1, isTrue, reason: 'First back press should be intercepted');

    // Should go back to Teams (index 1)
    expect(currentIndex, 1);

    // Simulate back button press again
    // ignore: avoid_dynamic_calls, needed to simulate back button press
    final handled2 = await (widgetsAppState.didPopRoute() as Future<bool>);
    await tester.pumpAndSettle();
    expect(handled2, isTrue, reason: 'Second back press should be intercepted');

    // Should go back to Scoring (index 0)
    expect(currentIndex, 0);

    // Third back press should NOT be intercepted (canPop should be true)
    // ignore: avoid_dynamic_calls, needed to simulate back button press
    final handled3 = await (widgetsAppState.didPopRoute() as Future<bool>);
    await tester.pumpAndSettle();
    expect(
      handled3,
      isFalse,
      reason: 'Final back press should NOT be intercepted',
    );
  });
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
