// material 3 bottom navigation bar

import 'package:flutter/material.dart';
import 'package:scorecard/widgets/common/football_icon.dart';

/// bottom navigation bar for app tabs
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
    this.isVisible = true,
  });
  final int currentIndex;
  final void Function(int) onDestinationSelected;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: FootballIcon(size: 32),
            selectedIcon: FootballIcon(size: 32),
            label: 'Scoring',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}

/// navigation destinations enum for type safety
enum NavigationTab {
  scoring(0),
  teams(1),
  results(2);

  const NavigationTab(this.tabIndex);
  final int tabIndex;

  static NavigationTab fromIndex(int index) {
    return NavigationTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => NavigationTab.scoring,
    );
  }

  static NavigationTab? fromRoute(String route) {
    switch (route) {
      case 'game_setup':
      case 'scoring':
        return NavigationTab.scoring;
      case 'teams':
      case 'team_list':
      case 'add_team':
        return NavigationTab.teams;
      case 'game_history':
      case 'game_details':
      case 'results':
        return NavigationTab.results;
      default:
        return null;
    }
  }
}
