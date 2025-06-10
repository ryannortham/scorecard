import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../adapters/game_setup_adapter.dart';
import '../../providers/user_preferences_provider.dart';

/// Widget for configuring game settings (quarter minutes and timer type)
/// on the game setup screen with user interaction
class GameSettingsConfiguration extends StatelessWidget {
  const GameSettingsConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameSetupAdapter, UserPreferencesProvider>(
      builder: (context, gameSetupAdapter, userPreferences, child) {
        if (!userPreferences.loaded) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return Card(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Quarter Minutes Setting
                _buildQuarterMinutesSection(
                    context, gameSetupAdapter, userPreferences),

                const SizedBox(height: 24),

                // Timer Type Setting
                _buildTimerTypeSection(
                    context, gameSetupAdapter, userPreferences),
              ],
            ),
          ),
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${gameSetupAdapter.quarterMinutes}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
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
        Text(
          'Timer Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              gameSetupAdapter.isCountdownTimer ? 'Countdown' : 'Count Up',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: gameSetupAdapter.isCountdownTimer,
              onChanged: (value) {
                gameSetupAdapter.setIsCountdownTimer(value);
                userPreferences.setIsCountdownTimer(value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
