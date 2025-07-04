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
            // Timer Type Setting
            _buildTimerTypeSection(context, gameState, userPreferences),

            const SizedBox(height: 20),

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quarter Minutes',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${gameState.quarterMinutes}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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

  Widget _buildTimerTypeSection(
    BuildContext context,
    GameStateService gameState,
    UserPreferencesProvider userPreferences,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timer Type',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              gameState.isCountdownTimer ? 'Countdown' : 'Count Up',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Switch(
          value: gameState.isCountdownTimer,
          onChanged: (value) {
            gameState.configureGame(
              homeTeam: gameState.homeTeam,
              awayTeam: gameState.awayTeam,
              gameDate: gameState.gameDate,
              quarterMinutes: gameState.quarterMinutes,
              isCountdownTimer: value,
            );
            userPreferences.setIsCountdownTimer(value);
          },
        ),
      ],
    );
  }
}
