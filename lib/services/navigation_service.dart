import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/screens/results/results_screen.dart';
import 'package:scorecard/screens/results/results_list_screen.dart';
import 'package:scorecard/screens/scoring/scoring_setup_screen.dart';
import 'package:scorecard/screens/scoring/scoring_screen.dart';
import 'package:scorecard/screens/teams/team_list_screen.dart';
import 'package:scorecard/services/dialog_service.dart';

/// Centralized navigation service following Flutter best practices
/// Reduces code duplication and provides type-safe navigation
class AppNavigator {
  static const String teamList = '/team-list';
  static const String gameSetup = '/game-setup';
  static const String gameHistory = '/game-history';
  static const String gameDetails = '/game-details';
  static const String scoring = '/scoring';

  /// Navigate to team selection with callback
  static Future<String?> toTeamSelection({
    required BuildContext context,
    required String title,
    required Function(String) onTeamSelected,
    String? excludeTeam,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (context) =>
                TeamListScreen(title: title, onTeamSelected: onTeamSelected),
        settings: RouteSettings(arguments: excludeTeam),
      ),
    );
  }

  /// Navigate to game setup
  static Future<T?> toGameSetup<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (context) => const ScoringSetupScreen()),
    );
  }

  /// Navigate to game history
  static Future<T?> toGameHistory<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (context) => const ResultsListScreen()),
    );
  }

  /// Navigate to game details
  static Future<T?> toGameDetails<T extends Object?>({
    required BuildContext context,
    required GameRecord game,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (context) => ResultsScreen(game: game)),
    );
  }

  /// Navigate to active scoring screen
  static Future<T?> toScoring<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const ScoringScreen(title: 'Scoring'),
      ),
    );
  }

  /// Show confirmation dialog with consistent styling
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    bool isDestructive = false,
  }) async {
    return await DialogService.showConfirmationDialog(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      isDestructive: isDestructive,
    );
  }
}
