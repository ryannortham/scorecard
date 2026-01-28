// app routing configuration using go_router

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/screens/results/results_list_screen.dart';
import 'package:scorecard/screens/results/results_screen.dart';
import 'package:scorecard/screens/scoring/scoring_screen.dart';
import 'package:scorecard/screens/scoring/scoring_setup_screen.dart';
import 'package:scorecard/screens/teams/team_add_screen.dart';
import 'package:scorecard/screens/teams/team_detail_screen.dart';
import 'package:scorecard/screens/teams/team_list_screen.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

/// global navigation key for the root navigator
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// navigation keys for each tab's navigator
final GlobalKey<NavigatorState> _scoringNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'scoringNav');
final GlobalKey<NavigatorState> _teamsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'teamsNav',
);
final GlobalKey<NavigatorState> _resultsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'resultsNav');

/// Data class for passing team selection parameters
class TeamSelectionExtra {
  const TeamSelectionExtra({
    required this.title,
    this.excludeTeam,
  });

  final String title;
  final String? excludeTeam;
}

/// app router configuration
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/scoring',
  routes: [
    StatefulShellRoute(
      builder: (context, state, navigationShell) {
        // Pass through - actual container is built in navigatorContainerBuilder
        return navigationShell;
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return NavigationShell(
          navigationShell: navigationShell,
          children: children,
        );
      },
      branches: [
        // Scoring tab
        StatefulShellBranch(
          navigatorKey: _scoringNavigatorKey,
          routes: [
            GoRoute(
              path: '/scoring',
              builder: (context, state) => const ScoringSetupScreen(),
            ),
          ],
        ),
        // Teams tab
        StatefulShellBranch(
          navigatorKey: _teamsNavigatorKey,
          routes: [
            GoRoute(
              path: '/teams',
              builder: (context, state) => const TeamListScreen(title: 'Teams'),
            ),
          ],
        ),
        // Results tab
        StatefulShellBranch(
          navigatorKey: _resultsNavigatorKey,
          routes: [
            GoRoute(
              path: '/results',
              builder: (context, state) => const ResultsListScreen(),
            ),
          ],
        ),
      ],
    ),
    // Detail screens outside the shell (full screen, no tab bar)
    GoRoute(
      path: '/scoring-game',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScoringScreen(title: 'Scoring'),
    ),
    GoRoute(
      path: '/team/:teamName',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final teamName = state.pathParameters['teamName'] ?? '';
        return TeamDetailScreen(teamName: teamName);
      },
    ),
    GoRoute(
      path: '/team-add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeamAddScreen(),
    ),
    GoRoute(
      path: '/team-select',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as TeamSelectionExtra?;
        return TeamListScreen(
          title: extra?.title ?? 'Select Team',
          excludeTeam: extra?.excludeTeam,
        );
      },
    ),
    GoRoute(
      path: '/results/:gameId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final game = state.extra! as GameRecord;
        return ResultsScreen(game: game);
      },
    ),
  ],
);
