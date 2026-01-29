// navigation shell that wraps screens with bottom navigation

import 'dart:async';

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
  none,
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

class NavigationShellState extends State<NavigationShell> {
  bool _isNavigationVisible = true;
  late final List<int> _tabHistory;
  bool _isInternalNavigating = false;

  /// Current direction of navigation for transitions
  NavigationDirection currentDirection = NavigationDirection.none;

  @override
  void initState() {
    super.initState();
    // Initialize history with the starting tab
    _tabHistory = [widget.navigationShell.currentIndex];
  }

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

    // canPop is true only when on home tab with no more history
    final canPop =
        _tabHistory.length <= 1 && widget.navigationShell.currentIndex == 0;

    return Scaffold(
      extendBody: true,
      body: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _popTab();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: Stack(
            children: [
              // Use a custom container that animates between branches without
              // duplicating global keys.
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
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 100) {
                        _popTab();
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
      duration: const Duration(milliseconds: 300),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        // If not selected and animation finished, hide completely
        if (value <= 0 && !widget.isSelected) {
          return const SizedBox.shrink();
        }

        // Handle initial state with no direction
        if (widget.direction == NavigationDirection.none) {
          return Opacity(
            opacity: widget.isSelected ? 1.0 : 0.0,
            child: widget.isSelected ? child : const SizedBox.shrink(),
          );
        }

        final isBackward = widget.direction == NavigationDirection.backward;

        Offset offset;
        if (widget.isSelected) {
          // Incoming widget
          final begin = isBackward ? const Offset(-1, 0) : const Offset(1, 0);
          offset =
              Offset.lerp(
                begin,
                Offset.zero,
                Curves.easeInOutCubic.transform(value),
              )!;
        } else {
          // Outgoing widget
          final end = isBackward ? const Offset(1, 0) : const Offset(-1, 0);
          offset =
              Offset.lerp(
                end,
                Offset.zero,
                Curves.easeInOutCubic.transform(value),
              )!;
        }

        // Apply platform specific feel
        if (!widget.isIOS) {
          // Android: subtle move + fade
          offset = offset * 0.05;
        }

        return FractionalTranslation(
          translation: offset,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: TickerMode(
        enabled: widget.isSelected || _controller.isAnimating,
        child: IgnorePointer(
          ignoring: !widget.isSelected,
          child: widget.child,
        ),
      ),
    );
  }
}
