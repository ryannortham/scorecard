// navigation shell that wraps screens with bottom navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/bottom_nav_bar.dart';

/// Direction of tab navigation for transitions
enum NavigationDirection { 
  /// Moving forward in history (new tab selected)
  forward, 
  /// Moving backward in history (back button/swipe)
  backward, 
  /// No direction (initial state)
  none 
}

/// wraps screens with bottom navigation and handles tab history and scroll visibility
class NavigationShell extends StatefulWidget {
  const NavigationShell({
    required this.navigationShell,
    required this.child,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  State<NavigationShell> createState() => NavigationShellState();
}

class NavigationShellState extends State<NavigationShell> {
  bool _isNavigationVisible = true;
  final List<int> _tabHistory = [0]; // Start with Scoring tab (index 0)
  bool _isInternalNavigating = false;
  bool _swipeHandled = false;
  
  /// Current direction of navigation for transitions
  NavigationDirection currentDirection = NavigationDirection.none;

  @override
  void didUpdateWidget(NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the index changed (regardless of how), update history
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != oldWidget.navigationShell.currentIndex) {
      if (!_isInternalNavigating) {
        currentDirection = NavigationDirection.forward;
        _updateHistory(newIndex);
      } else {
        currentDirection = NavigationDirection.backward;
      }
      _isInternalNavigating = false;
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

      // Hide on scroll down, show on scroll up
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

    // Always show when at the top
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

  void _popTab() {
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast(); // Remove current
        final previousIndex = _tabHistory.last;
        _isInternalNavigating = true;
        widget.navigationShell.goBranch(previousIndex);
      });
    } else if (widget.navigationShell.currentIndex != 0) {
      _isInternalNavigating = true;
      widget.navigationShell.goBranch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return PopScope(
      // Can only pop (exit app) if we are on the first tab and history is exhausted
      canPop: _tabHistory.length <= 1 && widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popTab();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              widget.child,
              // Edge swipe detector for iOS
              if (isIOS)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => _swipeHandled = false,
                    onHorizontalDragUpdate: (details) {
                      if (!_swipeHandled && details.delta.dx > 10) {
                        _swipeHandled = true;
                        _popTab();
                      }
                    },
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            isVisible: _isNavigationVisible,
          ),
        ),
      ),
    );
  }
}