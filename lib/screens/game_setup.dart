import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/widgets/game_setup/game_settings_configuration.dart';
import 'package:scorecard/widgets/game_setup/team_selection_widget.dart';
import 'package:scorecard/widgets/game_setup/app_drawer.dart';

import 'scoring.dart';

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

  @override
  void initState() {
    super.initState();
    // Completely reset and initialize game state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameSetupAdapter = Provider.of<GameSetupAdapter>(
        context,
        listen: false,
      );
      final userPreferences = Provider.of<UserPreferencesProvider>(
        context,
        listen: false,
      );
      final scorePanelAdapter = Provider.of<ScorePanelAdapter>(
        context,
        listen: false,
      );

      // First, completely reset the game state
      gameSetupAdapter.reset(
        defaultQuarterMinutes: userPreferences.quarterMinutes,
        defaultIsCountdownTimer: userPreferences.isCountdownTimer,
        favoriteTeam: userPreferences.favoriteTeam,
      );

      // Reset the score panel as well
      scorePanelAdapter.resetGame();

      // Configure the timer with fresh settings
      scorePanelAdapter.configureTimer(
        isCountdownMode: userPreferences.isCountdownTimer,
        quarterMaxTime: userPreferences.quarterMinutes * 60 * 1000,
      );

      // Now set up the form fields
      String homeTeamValue = '';
      if (userPreferences.favoriteTeam.isNotEmpty) {
        homeTeamValue = userPreferences.favoriteTeam;
        gameSetupAdapter.setHomeTeam(homeTeamValue);
      }

      _homeTeamController.text = homeTeamValue;
      _awayTeamController.text = '';
      _dateController.text = DateFormat(
        'EEEE dd/MM/yyyy',
      ).format(DateTime.now());

      setState(() {
        homeTeam = homeTeamValue.isNotEmpty ? homeTeamValue : null;
        awayTeam = null;
      });
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
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        title: Text(widget.title),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'game_setup'),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 20),
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
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );

                            if (pickedDate != null) {
                              gameSetupAdapter.setGameDate(pickedDate);
                              _dateController.text = DateFormat(
                                'EEEE dd/MM/yyyy',
                              ).format(pickedDate);
                            }
                            dateKey.currentState!.validate();
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const GameSettingsConfiguration(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: FilledButton.tonal(
                    onPressed: () {
                      if (isValidSetup()) {
                        final gameSetupAdapter = Provider.of<GameSetupAdapter>(
                          context,
                          listen: false,
                        );
                        final scorePanelAdapter =
                            Provider.of<ScorePanelAdapter>(
                              context,
                              listen: false,
                            );

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
                            builder:
                                (context) => const Scoring(title: 'Scoring'),
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
