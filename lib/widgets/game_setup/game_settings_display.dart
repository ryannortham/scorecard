import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../adapters/game_setup_adapter.dart';
import '../common/settings_card.dart';

/// Widget for displaying game settings configuration
class GameSettingsDisplay extends StatelessWidget {
  const GameSettingsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSetupAdapter>(
      builder: (context, gameSetupAdapter, child) {
        return SettingsCard(
          title: 'Game Settings',
          children: [
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
                  gameSetupAdapter.isCountdownTimer ? 'Countdown' : 'Count Up',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
