// navigation shell that wraps screens with bottom navigation

import 'dart:async';
import 'dart:ui' show lerpDouble;

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

class NavigationShellState extends State<NavigationShell> {
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
    _tabHistory = [widget.navigationShell.currentIndex];
    AppLogger.debug(
      'NavigationShell: Initialized with index '
      '${widget.navigationShell.currentIndex}',
      component: 'Navigation',
    );
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

        if (value <= 0 && !widget.isSelected) {
          return const SizedBox.shrink();
        }

        if (widget.direction == NavigationDirection.none) {
          return Opacity(
            opacity: widget.isSelected ? 1.0 : 0.0,
            child: widget.isSelected ? child : const SizedBox.shrink(),
          );
        }

        if (widget.isIOS) {
          // iOS: Horizontal slide transition (card-style)
          return _buildIOSTransition(value, child);
        } else {
          // Android: Material 3 shared-axis vertical transition
          return _buildAndroidSharedAxisVerticalTransition(value, child);
        }
      },
      // RepaintBoundary isolates child repaints from animation repaints,
      // preventing expensive list widgets from being repainted during
      // tab transitions.
      child: RepaintBoundary(
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

  /// iOS horizontal slide transition (card-style navigation)
  Widget _buildIOSTransition(double value, Widget? child) {
    final isBackward = widget.direction == NavigationDirection.backward;

    Offset offset;
    if (widget.isSelected) {
      // Incoming screen slides in from right (forward) or left (backward)
      final begin = isBackward ? const Offset(-1, 0) : const Offset(1, 0);
      offset =
          Offset.lerp(
            begin,
            Offset.zero,
            Curves.easeInOutCubic.transform(value),
          )!;
    } else {
      // Outgoing screen slides out to left (forward) or right (backward)
      final end = isBackward ? const Offset(1, 0) : const Offset(-1, 0);
      offset =
          Offset.lerp(
            end,
            Offset.zero,
            Curves.easeInOutCubic.transform(value),
          )!;
    }

    return FractionalTranslation(
      translation: offset,
      child: Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }

  /// Android Material 3 shared-axis vertical transition.
  /// Matches native Android navigation bar transitions:
  /// - Forward: incoming slides up from below, outgoing slides up and out
  /// - Backward: incoming slides down from above, outgoing slides down and out
  Widget _buildAndroidSharedAxisVerticalTransition(
    double value,
    Widget? child,
  ) {
    final isBackward = widget.direction == NavigationDirection.backward;

    // Material 3 spec: 30 pixel offset for shared-axis transitions
    const slideOffset = 30.0;

    // Apply easing curve to the animation value
    final curvedValue = Easing.legacy.transform(value);

    double opacity;
    double yOffset;

    if (widget.isSelected) {
      // Incoming screen (value goes 0→1 via forward())
      // Fade in with decelerate curve for natural feel
      opacity = Easing.legacyDecelerate.transform(value);

      // Slide from below (forward) or above (backward) to centre
      yOffset =
          isBackward
              ? lerpDouble(-slideOffset, 0, curvedValue)!
              : lerpDouble(slideOffset, 0, curvedValue)!;
    } else {
      // Outgoing screen (value goes 1→0 via reverse())
      // So we use value directly - as it decreases, opacity decreases
      opacity = Easing.legacyAccelerate.transform(value);

      // Slide from centre to above (forward) or below (backward)
      // Since value goes 1→0, we need to invert the lerp logic
      final invertedCurve = Easing.legacy.transform(1.0 - value);
      yOffset =
          isBackward
              ? lerpDouble(0, slideOffset, invertedCurve)!
              : lerpDouble(0, -slideOffset, invertedCurve)!;
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, yOffset),
        child: child,
      ),
    );
  }
}
