import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_state_service.dart';

import 'game_setup.dart';

/// Home screen that determines the initial screen based on game state
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;
      final userPreferences = Provider.of<UserPreferencesProvider>(
        context,
        listen: false,
      );

      // Only initialize if preferences are loaded and there's no active game
      if (userPreferences.loaded) {
        final gameState = GameStateService.instance;
        if (!gameState.hasActiveGame) {
          // Use post-frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initializeGameSetup(userPreferences);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, userPreferences, child) {
        // Show loading screen until settings are loaded
        if (!userPreferences.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // BUGFIX: Always start with game setup, regardless of game state
        // This prevents unintended navigation when timer settings change
        // The only way to get to scoring should be through the Start Game button
        AppLogger.debug(
          'HomeScreen: Showing GameSetup screen',
          component: 'HomeScreen',
        );
        return const GameSetup(title: 'Game Setup');
      },
    );
  }

  /// Initialize game setup with user preferences
  void _initializeGameSetup(UserPreferencesProvider userPreferences) {
    final gameState = GameStateService.instance;

    // Reset the game state with user preferences
    gameState.configureGame(
      homeTeam:
          userPreferences.favoriteTeam.isNotEmpty
              ? userPreferences.favoriteTeam
              : '',
      awayTeam: '',
      gameDate: DateTime.now(),
      quarterMinutes: userPreferences.quarterMinutes,
      isCountdownTimer: userPreferences.isCountdownTimer,
    );
  }
}
