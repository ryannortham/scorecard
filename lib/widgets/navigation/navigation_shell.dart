// navigation shell that wraps screens with bottom navigation

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/widgets/navigation/bottom_nav_bar.dart';

/// wraps screens with bottom navigation and scroll handling
class NavigationShell extends StatefulWidget {
  const NavigationShell({
    required this.navigationShell,
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  bool _isNavigationVisible = true;
  final List<int> _tabHistory = [0]; // Start with Scoring tab

  void _onDestinationSelected(int index) {
    // Only add to history if switching to a different tab
    if (index != widget.navigationShell.currentIndex) {
      _tabHistory.add(index);
    }
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

  void _goToPreviousTab() {
    _tabHistory.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tabHistory.length <= 1, // Allow exit only from initial tab
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // App is exiting, nothing to do

        // Go back to previous tab
        if (_tabHistory.length > 1) {
          setState(_goToPreviousTab);
          widget.navigationShell.goBranch(_tabHistory.last);
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Scaffold(
          extendBody: true,
          body: AnimatedBranchContainer(
            currentIndex: widget.navigationShell.currentIndex,
            children: widget.children,
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
/// when switching branches.
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  /// The index (in [children]) of the branch Navigator to display.
  final int currentIndex;

  /// The children (branch Navigators) to display in this container.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children:
          children.mapIndexed((int index, Widget navigator) {
            return AnimatedOpacity(
              opacity: index == currentIndex ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _branchNavigatorWrapper(index, navigator),
            );
          }).toList(),
    );
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) => IgnorePointer(
    ignoring: index != currentIndex,
    child: TickerMode(enabled: index == currentIndex, child: navigator),
  );
}
