import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../adapters/game_setup_adapter.dart';
import '../providers/settings_provider.dart';
import '../providers/game_setup_preferences_provider.dart';
import 'game_setup.dart';
import 'game_history.dart';
import 'settings.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.title});
  final String title;

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Settings(title: 'Settings'),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Spacer(flex: 8),
            Text(
              'Welcome to GoalKeeper',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(flex: 2),
            Text(
              'What would you like to do?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ElevatedButton(
                onPressed: () async {
                  // Reset GameSetupAdapter before navigating using preferences defaults
                  final gameSetupAdapter =
                      Provider.of<GameSetupAdapter>(context, listen: false);
                  final settingsProvider =
                      Provider.of<SettingsProvider>(context, listen: false);
                  final preferencesProvider =
                      Provider.of<GameSetupPreferencesProvider>(context,
                          listen: false);

                  // Store navigator before async operation to avoid using context across async gaps
                  final navigator = Navigator.of(context);

                  // Ensure settings and preferences are loaded before proceeding
                  if (!settingsProvider.loaded) {
                    await settingsProvider.loadSettings();
                  }
                  if (!preferencesProvider.loaded) {
                    await preferencesProvider.loadPreferences();
                  }

                  gameSetupAdapter.reset(
                    defaultQuarterMinutes: preferencesProvider.quarterMinutes,
                    defaultIsCountdownTimer:
                        preferencesProvider.isCountdownTimer,
                    favoriteTeam: settingsProvider.favoriteTeam,
                  );
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const GameSetup(title: 'Game Setup'),
                    ),
                  );
                },
                child: const Text("Start New Game"),
              ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                ),
                child: const Text("Game History"),
              ),
            ),
            const Spacer(flex: 8),
          ],
        ),
      ),
    );
  }
}
