import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorecard/widgets/common/tab_root_app_bar.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

void main() {
  group('TabRootAppBar', () {
    testWidgets('shows back button when canPopTab is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _TestNavigationShellWrapper(
            canPopTab: true,
            child: CustomScrollView(
              slivers: [
                TabRootAppBar(
                  title: Text('Test Title'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify back button is present
      expect(find.byTooltip('Back'), findsOneWidget);
      // Uses Icons.adaptive.arrow_back_outlined which varies by platform
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('hides back button when canPopTab is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _TestNavigationShellWrapper(
            canPopTab: false,
            child: CustomScrollView(
              slivers: [
                TabRootAppBar(
                  title: Text('Test Title'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify back button is NOT present
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('calls popTab when back button is pressed', (
      WidgetTester tester,
    ) async {
      var popTabCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: _TestNavigationShellWrapper(
            canPopTab: true,
            onPopTab: () => popTabCalled = true,
            child: const CustomScrollView(
              slivers: [
                TabRootAppBar(
                  title: Text('Test Title'),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap the back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(popTabCalled, isTrue);
    });

    testWidgets('displays title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _TestNavigationShellWrapper(
            canPopTab: false,
            child: CustomScrollView(
              slivers: [
                TabRootAppBar(
                  title: Text('My Custom Title'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('My Custom Title'), findsOneWidget);
    });

    testWidgets('displays actions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestNavigationShellWrapper(
            canPopTab: false,
            child: CustomScrollView(
              slivers: [
                TabRootAppBar(
                  title: const Text('Test'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}

/// A wrapper widget that provides a mock NavigationShellInfo for testing
class _TestNavigationShellWrapper extends StatefulWidget {
  const _TestNavigationShellWrapper({
    required this.canPopTab,
    required this.child,
    this.onPopTab,
  });

  final bool canPopTab;
  final Widget child;
  final VoidCallback? onPopTab;

  @override
  State<_TestNavigationShellWrapper> createState() =>
      _TestNavigationShellWrapperState();
}

class _TestNavigationShellWrapperState
    extends State<_TestNavigationShellWrapper> {
  late _FakeNavigationShellState _fakeState;

  @override
  void initState() {
    super.initState();
    _fakeState = _FakeNavigationShellState(
      canPopTab: widget.canPopTab,
      onPopTab: widget.onPopTab,
    );
  }

  @override
  void didUpdateWidget(_TestNavigationShellWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fakeState = _FakeNavigationShellState(
      canPopTab: widget.canPopTab,
      onPopTab: widget.onPopTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationShellInfo(
      state: _fakeState,
      child: Scaffold(body: widget.child),
    );
  }
}

/// A fake implementation of NavigationShellState for testing
class _FakeNavigationShellState extends Fake implements NavigationShellState {
  _FakeNavigationShellState({
    required this.canPopTab,
    this.onPopTab,
  });

  @override
  final bool canPopTab;

  final VoidCallback? onPopTab;

  @override
  NavigationDirection currentDirection = NavigationDirection.none;

  @override
  void popTab() {
    onPopTab?.call();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}
