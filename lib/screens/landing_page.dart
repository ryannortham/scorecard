import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_setup_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
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
      appBar: CustomAppBar(
        title: widget.title,
        onSettingsPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const Settings(title: 'Settings'),
          ),
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
            CustomButton(
              text: "Start New Game",
              width: MediaQuery.of(context).size.width * 0.75,
              onPressed: () async {
                // Reset GameSetupProvider before navigating using settings defaults
                final gameSetupProvider =
                    Provider.of<GameSetupProvider>(context, listen: false);
                final settingsProvider =
                    Provider.of<SettingsProvider>(context, listen: false);

                // Store navigator before async operation to avoid using context across async gaps
                final navigator = Navigator.of(context);

                // Ensure settings are loaded before proceeding
                if (!settingsProvider.loaded) {
                  await settingsProvider.loadSettings();
                }

                gameSetupProvider.reset(
                  defaultQuarterMinutes: settingsProvider.defaultQuarterMinutes,
                  defaultIsCountdownTimer:
                      settingsProvider.defaultIsCountdownTimer,
                  favoriteTeam: settingsProvider.favoriteTeam,
                );
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => const GameSetup(title: 'Game Setup'),
                  ),
                );
              },
            ),
            const Spacer(flex: 1),
            CustomButton(
              text: "Game History",
              width: MediaQuery.of(context).size.width * 0.75,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GameHistoryScreen(),
                ),
              ),
            ),
            const Spacer(flex: 8),
          ],
        ),
      ),
    );
  }
}
