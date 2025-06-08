import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_setup_provider.dart';
import '../common/settings_card.dart';

/// Widget for displaying game settings configuration
class GameSettingsDisplay extends StatelessWidget {
  const GameSettingsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSetupProvider>(
      builder: (context, gameSetupProvider, child) {
        return SettingsCard(
          title: 'Game Settings',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quarter Minutes:'),
                Text(
                  '${gameSetupProvider.quarterMinutes}',
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
                  gameSetupProvider.isCountdownTimer ? 'Countdown' : 'Count Up',
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
