import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../adapters/game_setup_adapter.dart';
import '../adapters/score_panel_adapter.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/game_setup/team_selection_widget.dart';
import '../widgets/game_setup/game_settings_configuration.dart';
import 'game_container.dart';
import 'settings.dart';
import 'game_history.dart';

class GameSetup extends StatefulWidget {
  const GameSetup({super.key, required this.title});
  final String title;

  @override
  State<GameSetup> createState() => _GameSetupState();
}

class _GameSetupState extends State<GameSetup> {
  String? homeTeam;
  String? awayTeam;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final dateKey = GlobalKey<FormState>();
  final homeTeamKey = GlobalKey<FormState>();
  final awayTeamKey = GlobalKey<FormState>();

  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool isValidSetup() {
    bool dateValid = dateKey.currentState!.validate();
    bool homeTeamValid = homeTeamKey.currentState!.validate();
    bool awayTeamValid = awayTeamKey.currentState!.validate();

    return dateValid && homeTeamValid && awayTeamValid;
  }

  void _updateSettingsFromProvider() {
    final userPreferences =
        Provider.of<UserPreferencesProvider>(context, listen: false);
    final gameSetupProvider =
        Provider.of<GameSetupAdapter>(context, listen: false);

    // Use preferences for quarter minutes and countdown timer
    gameSetupProvider.setQuarterMinutes(userPreferences.quarterMinutes);
    gameSetupProvider.setIsCountdownTimer(userPreferences.isCountdownTimer);

    // Set favorite team as home team if home team is currently empty
    if (gameSetupProvider.homeTeam.isEmpty &&
        userPreferences.favoriteTeam.isNotEmpty) {
      gameSetupProvider.setHomeTeam(userPreferences.favoriteTeam);
      _homeTeamController.text = userPreferences.favoriteTeam;
    }
  }

  @override
  void initState() {
    super.initState();
    // Synchronize text controllers with provider values on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameSetupAdapter =
          Provider.of<GameSetupAdapter>(context, listen: false);
      final userPreferences =
          Provider.of<UserPreferencesProvider>(context, listen: false);

      // Initialize game settings from saved preferences
      if (userPreferences.loaded) {
        gameSetupAdapter.setQuarterMinutes(userPreferences.quarterMinutes);
        gameSetupAdapter.setIsCountdownTimer(userPreferences.isCountdownTimer);
      }

      _homeTeamController.text = gameSetupAdapter.homeTeam;
      _awayTeamController.text = gameSetupAdapter.awayTeam;
      _dateController.text =
          DateFormat('EEEE dd/MM/yyyy').format(gameSetupAdapter.gameDate);
      homeTeam = gameSetupAdapter.homeTeam.isNotEmpty
          ? gameSetupAdapter.homeTeam
          : null;
      awayTeam = gameSetupAdapter.awayTeam.isNotEmpty
          ? gameSetupAdapter.awayTeam
          : null;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(context);

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
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Settings(title: 'Settings'),
                  ),
                );
                // Update game setup with current settings when returning
                if (context.mounted) {
                  _updateSettingsFromProvider();
                }
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
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Form(
                key: dateKey,
                child: TextFormField(
                  readOnly: true,
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Game Date',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select Game Date';
                    }
                    return null;
                  },
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (pickedDate != null) {
                      gameSetupAdapter.setGameDate(pickedDate);
                      _dateController.text =
                          DateFormat('EEEE dd/MM/yyyy').format(pickedDate);
                    }
                    dateKey.currentState!.validate();
                  },
                ),
              ),
              const SizedBox(height: 20),
              TeamSelectionWidget(
                homeTeamKey: homeTeamKey,
                awayTeamKey: awayTeamKey,
                homeTeamController: _homeTeamController,
                awayTeamController: _awayTeamController,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                onHomeTeamChanged: (newTeam) {
                  setState(() {
                    homeTeam = newTeam;
                  });
                },
                onAwayTeamChanged: (newTeam) {
                  setState(() {
                    awayTeam = newTeam;
                  });
                },
              ),
              const SizedBox(height: 24),
              const GameSettingsConfiguration(),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isValidSetup()) {
                        final gameSetupAdapter = Provider.of<GameSetupAdapter>(
                            context,
                            listen: false);
                        final scorePanelAdapter =
                            Provider.of<ScorePanelAdapter>(context,
                                listen: false);

                        // First configure the game with current setup data
                        gameSetupAdapter.setHomeTeam(homeTeam ?? '');
                        gameSetupAdapter.setAwayTeam(awayTeam ?? '');

                        // Configure timer settings using current game setup adapter values
                        scorePanelAdapter.configureTimer(
                          isCountdownMode: gameSetupAdapter.isCountdownTimer,
                          quarterMaxTime:
                              gameSetupAdapter.quarterMinutes * 60 * 1000,
                        );

                        // Then reset the score state for a new game
                        scorePanelAdapter.resetGame();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GameContainer(),
                          ),
                        );
                      }
                    },
                    child: const Text('Start Scoring'),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
