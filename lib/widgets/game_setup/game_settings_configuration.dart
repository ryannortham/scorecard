import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/providers/user_preferences_provider.dart';

/// Widget for configuring timer settings (quarter minutes and timer type)
/// on the game setup screen
class GameSettingsConfiguration extends StatelessWidget {
  const GameSettingsConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, UserPreferencesProvider>(
      builder: (context, gameSetupAdapter, userPreferences, child) {
        if (!userPreferences.loaded) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quarter Minutes Setting
            _buildQuarterMinutesSection(
                context, gameSetupAdapter, userPreferences),

            const SizedBox(height: 20),

            // Timer Type Setting
            _buildTimerTypeSection(context, gameSetupAdapter, userPreferences),
          ],
        );
      },
    );
  }

  Widget _buildQuarterMinutesSection(
    BuildContext context,
    GameSetupAdapter gameSetupAdapter,
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${gameSetupAdapter.quarterMinutes}',
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
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: Slider(
            value: gameSetupAdapter.quarterMinutes.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '${gameSetupAdapter.quarterMinutes}',
            onChanged: (value) {
              final minutes = value.toInt();
              gameSetupAdapter.setQuarterMinutes(minutes);
              userPreferences.setQuarterMinutes(minutes);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimerTypeSection(
    BuildContext context,
    GameSetupAdapter gameSetupAdapter,
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              gameSetupAdapter.isCountdownTimer ? 'Countdown' : 'Count Up',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        Switch(
          value: gameSetupAdapter.isCountdownTimer,
          onChanged: (value) {
            gameSetupAdapter.setIsCountdownTimer(value);
            userPreferences.setIsCountdownTimer(value);
          },
        ),
      ],
    );
  }
}
