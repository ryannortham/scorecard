// navigation shell that wraps screens with bottom navigation

import 'package:collection/collection.dart';
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
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<NavigationShell> createState() => NavigationShellState();
}

class NavigationShellState extends State<NavigationShell> {
  bool _isNavigationVisible = true;
  final List<int> _tabHistory = [0]; // Start with Scoring tab (index 0)
  bool _isInternalNavigating = false;
  
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
        final targetIndex = _tabHistory.last;
        _isInternalNavigating = true;
        
        // Remove the target from history because didUpdateWidget will add it back
        _tabHistory.removeLast(); 
        
        widget.navigationShell.goBranch(targetIndex);
      });
    } else if (widget.navigationShell.currentIndex != 0) {
      setState(() {
        _isInternalNavigating = true;
        widget.navigationShell.goBranch(0);
      });
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
              AnimatedBranchContainer(
                currentIndex: widget.navigationShell.currentIndex,
                direction: currentDirection,
                isIOS: isIOS,
                children: widget.children,
              ),
              // Edge swipe detector for iOS
              if (isIOS)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      // Detect a rightward swipe from the left edge
                      if (details.delta.dx > 10) {
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

/// Custom branch Navigator container that provides animated transitions
/// between branches in a way that avoids duplicate GlobalKeys.
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
      children: children.mapIndexed((int index, Widget child) {
        final bool isSelected = index == currentIndex;
        
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

class _AnimatedBranchItemState extends State<_AnimatedBranchItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.isIOS 
          ? const Duration(milliseconds: 350) 
          : const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _updateAnimations();
    
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedBranchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected || widget.direction != oldWidget.direction) {
      _updateAnimations();
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _updateAnimations() {
    final bool isBackward = widget.direction == NavigationDirection.backward;
    
    Offset begin;
    if (widget.isIOS) {
      begin = isBackward ? const Offset(-1, 0) : const Offset(1, 0);
    } else {
      begin = isBackward ? const Offset(0, -0.02) : const Offset(0, 0.02);
    }

    _slideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(_animation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: _slideAnimation,
        child: TickerMode(
          enabled: widget.isSelected || _controller.isAnimating,
          child: IgnorePointer(
            ignoring: !widget.isSelected,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
