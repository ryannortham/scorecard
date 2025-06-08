import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../adapters/game_setup_adapter.dart';
import '../adapters/score_panel_adapter.dart';
import '../providers/settings_provider.dart';
import '../widgets/game_setup/team_selection_widget.dart';
import '../widgets/game_setup/game_settings_display.dart';
import 'game_container.dart';
import 'settings.dart';

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
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final gameSetupProvider =
        Provider.of<GameSetupAdapter>(context, listen: false);
    gameSetupProvider.setQuarterMinutes(settingsProvider.defaultQuarterMinutes);
    gameSetupProvider
        .setIsCountdownTimer(settingsProvider.defaultIsCountdownTimer);
    // Set favorite team as home team if home team is currently empty
    if (gameSetupProvider.homeTeam.isEmpty &&
        settingsProvider.favoriteTeam.isNotEmpty) {
      gameSetupProvider.setHomeTeam(settingsProvider.favoriteTeam);
      _homeTeamController.text = settingsProvider.favoriteTeam;
    }
  }

  @override
  void initState() {
    super.initState();
    // Synchronize text controllers with provider values on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameSetupAdapter =
          Provider.of<GameSetupAdapter>(context, listen: false);
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
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
        ],
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
              const GameSettingsDisplay(),
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
                        final settingsProvider = Provider.of<SettingsProvider>(
                            context,
                            listen: false);

                        // First configure the game with current setup data
                        gameSetupAdapter.setHomeTeam(homeTeam ?? '');
                        gameSetupAdapter.setAwayTeam(awayTeam ?? '');

                        // Configure timer settings
                        scorePanelAdapter.configureTimer(
                          isCountdownMode:
                              settingsProvider.defaultIsCountdownTimer,
                          quarterMaxTime:
                              settingsProvider.defaultQuarterMinutes *
                                  60 *
                                  1000,
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
