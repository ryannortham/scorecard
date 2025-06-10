import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../adapters/game_setup_adapter.dart';
import '../providers/user_preferences_provider.dart';
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Menu',
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.sports_rugby,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GoalKeeper',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Menu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Settings(title: 'Settings'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Game History'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
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
                  final userPreferences = Provider.of<UserPreferencesProvider>(
                      context,
                      listen: false);

                  // Store navigator before async operation to avoid using context across async gaps
                  final navigator = Navigator.of(context);

                  // Ensure preferences are loaded before proceeding
                  if (!userPreferences.loaded) {
                    await userPreferences.loadPreferences();
                  }

                  gameSetupAdapter.reset(
                    defaultQuarterMinutes: userPreferences.quarterMinutes,
                    defaultIsCountdownTimer: userPreferences.isCountdownTimer,
                    favoriteTeam: userPreferences.favoriteTeam,
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
