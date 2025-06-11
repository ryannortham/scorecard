import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../adapters/game_setup_adapter.dart';
import '../providers/user_preferences_provider.dart';
import '../services/game_state_service.dart';
import 'game_setup.dart';
import 'scoring.dart';

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
      final userPreferences =
          Provider.of<UserPreferencesProvider>(context, listen: false);

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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if there's an active game
        final gameState = GameStateService.instance;

        if (gameState.hasActiveGame) {
          // If there's an active game, go to scoring screen
          return const Scoring(title: 'Scoring');
        } else {
          // If no active game, go to game setup
          return const GameSetup(title: 'Game Setup');
        }
      },
    );
  }

  /// Initialize game setup with user preferences
  void _initializeGameSetup(UserPreferencesProvider userPreferences) {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);

    // Reset the game setup adapter with user preferences
    gameSetupAdapter.reset(
      defaultQuarterMinutes: userPreferences.quarterMinutes,
      defaultIsCountdownTimer: userPreferences.isCountdownTimer,
      favoriteTeam: userPreferences.favoriteTeam,
    );
  }
}
