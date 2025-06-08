import 'package:flutter/material.dart';
import 'package:goalkeeper/screens/settings.dart';
import 'package:goalkeeper/screens/team_list.dart';
import 'package:goalkeeper/screens/game_setup.dart';
import 'package:goalkeeper/screens/game_history.dart';
import 'package:goalkeeper/screens/game_details.dart' as details;
import 'package:goalkeeper/screens/game_container.dart';
import 'package:goalkeeper/providers/game_record.dart';

/// Centralized navigation service following Flutter best practices
/// Reduces code duplication and provides type-safe navigation
class AppNavigator {
  static const String settings = '/settings';
  static const String teamList = '/team-list';
  static const String gameSetup = '/game-setup';
  static const String gameHistory = '/game-history';
  static const String gameDetails = '/game-details';
  static const String gameContainer = '/game-container';

  /// Navigate to settings page
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

  /// Navigate to active game container
  static Future<T?> toGameContainer<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => const GameContainer(),
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
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: icon != null
                ? Icon(
                    icon,
                    color: isDestructive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  )
                : null,
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              if (isDestructive)
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmText),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmText),
                ),
            ],
          ),
        ) ??
        false;
  }
}
