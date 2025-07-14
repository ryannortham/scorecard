import 'package:flutter/material.dart';
import '../../services/assets/asset_icon_service.dart';

/// Material 3 compliant bottom navigation bar for the app
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final bool isVisible;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: FootballIcon(size: 32),
            selectedIcon: FootballIcon(size: 32),
            label: 'Scoring',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}

/// Navigation destinations enum for type safety
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
