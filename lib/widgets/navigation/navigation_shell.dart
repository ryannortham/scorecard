import 'package:flutter/material.dart';
import 'package:scorecard/screens/scoring/scoring_setup_screen.dart';
import 'package:scorecard/screens/teams/team_list_screen.dart';
import 'package:scorecard/screens/results/results_list_screen.dart';
import 'app_bottom_navigation_bar.dart';

/// Navigation shell that wraps screens with bottom navigation
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isNavigationVisible = true;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
    // No need for PageController animation - we'll switch directly
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

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const ScoringSetupScreen();
      case 1:
        return TeamListScreen(
          title: 'Teams',
          onTeamSelected: (_) {}, // No action needed for main teams view
        );
      case 2:
        return const ResultsListScreen();
      default:
        return const ScoringSetupScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Scaffold(
        body: _buildPage(
          _currentIndex,
        ), // Direct widget switching instead of PageView
        bottomNavigationBar: AppBottomNavigationBar(
          currentIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          isVisible: _isNavigationVisible,
        ),
      ),
    );
  }
}
