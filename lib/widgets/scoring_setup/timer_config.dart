// widget for configuring timer settings on scoring setup screen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';

/// widget for configuring timer settings (quarter minutes and timer type)
class TimerConfig extends StatelessWidget {
  const TimerConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameViewModel, PreferencesViewModel>(
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
    GameViewModel gameState,
    PreferencesViewModel userPreferences,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quarter Minutes: ${gameState.quarterMinutes}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(
            context,
          ).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape()),
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
              unawaited(userPreferences.setQuarterMinutes(minutes));
            },
          ),
        ),
      ],
    );
  }
}
