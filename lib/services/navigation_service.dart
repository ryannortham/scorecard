import 'package:flutter/material.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/screens/game_details.dart' as details;
import 'package:scorecard/screens/game_history.dart';
import 'package:scorecard/screens/game_setup.dart';
import 'package:scorecard/screens/scoring.dart';
import 'package:scorecard/screens/settings.dart';
import 'package:scorecard/screens/team_list.dart';
import 'package:scorecard/widgets/bottom_sheets/confirmation_bottom_sheet.dart';

/// Centralized navigation service following Flutter best practices
/// Reduces code duplication and provides type-safe navigation
class AppNavigator {
  static const String settings = '/settings';
  static const String teamList = '/team-list';
  static const String gameSetup = '/game-setup';
  static const String gameHistory = '/game-history';
  static const String gameDetails = '/game-details';
  static const String scoring = '/scoring';

  /// Navigate to settings page
  @Deprecated(
      'Settings screen has been deprecated. Use AppDrawer for settings access.')
  static Future<T?> toSettings<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const Settings(title: 'Settings'),
      ),
    );
  }

  /// Navigate to team selection with callback
  static Future<String?> toTeamSelection({
    required BuildContext context,
    required String title,
    required Function(String) onTeamSelected,
    String? excludeTeam,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => TeamList(
          title: title,
          onTeamSelected: onTeamSelected,
        ),
        settings: RouteSettings(arguments: excludeTeam),
      ),
    );
  }

  /// Navigate to game setup
  static Future<T?> toGameSetup<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const GameSetup(title: 'Game Setup'),
      ),
    );
  }

  /// Navigate to game history
  static Future<T?> toGameHistory<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const GameHistoryScreen(),
      ),
    );
  }

  /// Navigate to game details
  static Future<T?> toGameDetails<T extends Object?>({
    required BuildContext context,
    required GameRecord game,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => details.GameDetailsPage(game: game),
      ),
    );
  }

  /// Navigate to active scoring screen
  static Future<T?> toScoring<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const Scoring(title: 'Scoring'),
      ),
    );
  }

  /// Show confirmation bottom sheet with consistent styling
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    bool isDestructive = false,
  }) async {
    return await ConfirmationBottomSheet.show(
      context: context,
      actionText: confirmText,
      actionIcon:
          icon ?? (isDestructive ? Icons.delete_outline : Icons.check_outlined),
      onConfirm: () {}, // The bottom sheet handles navigation internally
      isDestructive: isDestructive,
    );
  }
}
