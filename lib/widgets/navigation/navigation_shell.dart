// navigation shell that wraps screens with bottom navigation

import 'dart:async';

import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/widgets/navigation/bottom_nav_bar.dart';

/// Direction of tab navigation for transitions
enum NavigationDirection {
  /// Moving forward in history (new tab selected)
  forward,

  /// Moving backward in history (back button/swipe)
  backward,

  /// No direction (initial state)
  none,
}

/// Inherited widget to provide navigation shell state to children
class NavigationShellInfo extends InheritedWidget {
  const NavigationShellInfo({
    required this.state,
    required super.child,
    super.key,
  });

  final NavigationShellState state;

  static NavigationShellState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavigationShellInfo>()
        ?.state;
  }

  @override
  bool updateShouldNotify(NavigationShellInfo oldWidget) {
    // Only notify dependents when the state reference actually changes.
    // Previously this always returned true, causing unnecessary rebuilds
    // of all widgets depending on NavigationShellInfo during every
    // animation frame.
    return state != oldWidget.state;
  }
}

/// wraps screens with bottom navigation and handles tab history and
/// scroll visibility
class NavigationShell extends StatefulWidget {
  const NavigationShell({
    required this.navigationShell,
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<NavigationShell> createState() => NavigationShellState();
}

class NavigationShellState extends State<NavigationShell>
    with WidgetsBindingObserver {
  bool _isNavigationVisible = true;
  late final List<int> _tabHistory;

  /// Pending navigation direction to be applied on the next index change.
  /// This replaces the boolean flag pattern for more explicit state management.
  NavigationDirection? _pendingDirection;

  /// Current direction of navigation for transitions
  NavigationDirection currentDirection = NavigationDirection.none;

  /// Whether the tab history can be popped
  bool get canPopTab =>
      _tabHistory.length > 1 || widget.navigationShell.currentIndex != 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabHistory = [widget.navigationShell.currentIndex];
    AppLogger.debug(
      'NavigationShell: Initialized with index '
      '${widget.navigationShell.currentIndex}',
      component: 'Navigation',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isNavigationVisible) {
      setState(() {
        _isNavigationVisible = true;
      });
    }
  }

  @override
  void didUpdateWidget(NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != oldWidget.navigationShell.currentIndex) {
      // Use pending direction if set, otherwise default to forward
      currentDirection = _pendingDirection ?? NavigationDirection.forward;

      // Only update history for forward navigation (new tab selections)
      if (currentDirection == NavigationDirection.forward) {
        _updateHistory(newIndex);
      }

      // Clear the pending direction after applying
      _pendingDirection = null;

      // Reset tab bar visibility when switching tabs
      _isNavigationVisible = true;

      AppLogger.debug(
        'NavigationShell: Index changed to $newIndex. '
        'Direction: $currentDirection. History: $_tabHistory',
        component: 'Navigation',
      );

      setState(() {});
    }
  }

  void _updateHistory(int index) {
    if (_tabHistory.isEmpty || _tabHistory.last != index) {
      _tabHistory.add(index);
    }
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (delta > 0 && _isNavigationVisible) {
        setState(() {
          _isNavigationVisible = false;
        });
      } else if (delta < 0 && !_isNavigationVisible) {
        setState(() {
          _isNavigationVisible = true;
        });
      }
    }

    if (notification is ScrollUpdateNotification) {
      final scrollController = notification.metrics;
      if (scrollController.pixels <= 0 && !_isNavigationVisible) {
        setState(() {
          _isNavigationVisible = true;
        });
      }
    }

    return false;
  }

  /// Handles back navigation with optional selection mode support.
  ///
  /// If [isInSelectionMode] is true and [onExitSelectionMode] is provided,
  /// calls [onExitSelectionMode] instead of navigating back. Otherwise,
  /// delegates to [popTab] for tab history navigation.
  ///
  /// This method simplifies back navigation handling in tab root screens
  /// by combining selection mode and tab history navigation into a single call.
  void handleBack({
    bool isInSelectionMode = false,
    VoidCallback? onExitSelectionMode,
  }) {
    if (isInSelectionMode && onExitSelectionMode != null) {
      AppLogger.debug(
        'NavigationShell: handleBack - exiting selection mode',
        component: 'Navigation',
      );
      onExitSelectionMode();
    } else {
      popTab();
    }
  }

  /// Pops the tab history
  void popTab() {
    AppLogger.debug(
      'NavigationShell: popTab called. History: $_tabHistory',
      component: 'Navigation',
    );
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        final targetIndex = _tabHistory.last;
        _pendingDirection = NavigationDirection.backward;
        widget.navigationShell.goBranch(targetIndex);
      });
    } else if (widget.navigationShell.currentIndex != 0) {
      setState(() {
        _pendingDirection = NavigationDirection.backward;
        widget.navigationShell.goBranch(0);
      });
    } else {
      AppLogger.debug(
        'NavigationShell: Home tab reached. Exiting app.',
        component: 'Navigation',
      );
      unawaited(SystemNavigator.pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return NavigationShellInfo(
      state: this,
      child: Scaffold(
        extendBody: true,
        body: PopScope(
          // We always handle pop manually to ensure history is respected
          // and to prevent Android system from bypassing our logic.
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            AppLogger.debug(
              'NavigationShell: onPopInvokedWithResult. didPop: $didPop',
              component: 'Navigation',
            );
            if (didPop) return;
            popTab();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: Stack(
              children: [
                AnimatedBranchContainer(
                  currentIndex: widget.navigationShell.currentIndex,
                  direction: currentDirection,
                  isIOS: isIOS,
                  children: widget.children,
                ),
                if (isIOS)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 20, // Small width to avoid blocking back button taps
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 100) {
                          AppLogger.debug(
                            'NavigationShell: iOS Edge swipe detected',
                            component: 'Navigation',
                          );
                          popTab();
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          isVisible: _isNavigationVisible,
        ),
      ),
    );
  }
}

class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    required this.direction,
    required this.isIOS,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;
  final NavigationDirection direction;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children:
          children.mapIndexed((int index, Widget child) {
            final isSelected = index == currentIndex;

            return _AnimatedBranchItem(
              index: index,
              isSelected: isSelected,
              direction: direction,
              isIOS: isIOS,
              child: child,
            );
          }).toList(),
    );
  }
}

/// Animation duration for tab transitions.
/// Material Design recommends 200-250ms for shared-axis transitions.
const _kAnimationDuration = Duration(milliseconds: 200);

class _AnimatedBranchItem extends StatefulWidget {
  const _AnimatedBranchItem({
    required this.index,
    required this.isSelected,
    required this.direction,
    required this.isIOS,
    required this.child,
  });

  final int index;
  final bool isSelected;
  final NavigationDirection direction;
  final bool isIOS;
  final Widget child;

  @override
  State<_AnimatedBranchItem> createState() => _AnimatedBranchItemState();
}

class _AnimatedBranchItemState extends State<_AnimatedBranchItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedBranchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        unawaited(_controller.forward(from: 0));
      } else {
        unawaited(_controller.reverse(from: 1));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap child with RepaintBoundary to isolate repaints from animation,
    // preventing expensive list widgets from being repainted during
    // tab transitions.
    final wrappedChild = RepaintBoundary(
      child: TickerMode(
        enabled: widget.isSelected || _controller.isAnimating,
        child: IgnorePointer(
          ignoring: !widget.isSelected,
          child: widget.child,
        ),
      ),
    );

    // No direction means initial state - just show/hide without animation
    if (widget.direction == NavigationDirection.none) {
      return Visibility(
        visible: widget.isSelected,
        maintainState: true,
        child: wrappedChild,
      );
    }

    // Use platform-specific transitions
    if (widget.isIOS) {
      return _buildIOSTransition(wrappedChild);
    } else {
      return _buildAndroidTransition(wrappedChild);
    }
  }

  /// iOS horizontal slide transition (card-style navigation).
  /// Uses SlideTransition with fractional offset for smooth performance.
  Widget _buildIOSTransition(Widget child) {
    final isBackward = widget.direction == NavigationDirection.backward;

    // Determine slide direction based on forward/backward and selected state
    final Offset beginOffset;
    final Offset endOffset;

    if (widget.isSelected) {
      // Incoming: slide in from right (forward) or left (backward)
      beginOffset = isBackward ? const Offset(-1, 0) : const Offset(1, 0);
      endOffset = Offset.zero;
    } else {
      // Outgoing: slide out to left (forward) or right (backward)
      beginOffset = Offset.zero;
      endOffset = isBackward ? const Offset(1, 0) : const Offset(-1, 0);
    }

    final slideAnimation = Tween<Offset>(
      begin: widget.isSelected ? beginOffset : endOffset,
      end: widget.isSelected ? endOffset : beginOffset,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    final fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value <= 0 && !widget.isSelected) {
          return const SizedBox.shrink();
        }
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Android Material 3 shared-axis vertical transition.
  /// Uses the official animations package for optimised, spec-compliant motion.
  Widget _buildAndroidTransition(Widget child) {
    final isBackward = widget.direction == NavigationDirection.backward;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value <= 0 && !widget.isSelected) {
          return const SizedBox.shrink();
        }

        // Use SharedAxisTransition from animations package
        return SharedAxisTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Colors.transparent,
          // Flip direction for backward navigation
          child:
              isBackward
                  ? Transform.scale(
                    scaleY: -1,
                    child: Transform.scale(scaleY: -1, child: child),
                  )
                  : child,
        );
      },
    );
  }
}
