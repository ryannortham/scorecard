import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/game_state_service.dart';

/// Widget for configuring timer settings (quarter minutes and timer type)
/// on the game setup screen
class GameSettingsConfiguration extends StatelessWidget {
  const GameSettingsConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameStateService, UserPreferencesProvider>(
      builder: (context, gameState, userPreferences, child) {
        if (!userPreferences.loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quarter Minutes Setting
            _buildQuarterMinutesSection(context, gameState, userPreferences),
          ],
        );
      },
    );
  }

  Widget _buildQuarterMinutesSection(
    BuildContext context,
    GameStateService gameState,
    UserPreferencesProvider userPreferences,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quarter Minutes: ${gameState.quarterMinutes}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: gameState.quarterMinutes.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '${gameState.quarterMinutes}',
            onChanged: (value) {
              final minutes = value.toInt();
              gameState.configureGame(
                homeTeam: gameState.homeTeam,
                awayTeam: gameState.awayTeam,
                gameDate: gameState.gameDate,
                quarterMinutes: minutes,
                isCountdownTimer: gameState.isCountdownTimer,
              );
              userPreferences.setQuarterMinutes(minutes);
            },
          ),
        ),
      ],
    );
  }
}
