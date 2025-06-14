import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';

/// Widget for displaying game settings configuration
class GameSettingsDisplay extends StatelessWidget {
  const GameSettingsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSetupAdapter>(
      builder: (context, gameSetupAdapter, child) {
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quarter Minutes:'),
                    Text(
                      '${gameSetupAdapter.quarterMinutes}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Timer Type:'),
                    Text(
                      gameSetupAdapter.isCountdownTimer
                          ? 'Countdown'
                          : 'Count Up',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
