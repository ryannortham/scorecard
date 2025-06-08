import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/game_setup_provider.dart';
import '../providers/score_panel_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_form_field.dart';
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
        Provider.of<GameSetupProvider>(context, listen: false);
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
      final gameSetupProvider =
          Provider.of<GameSetupProvider>(context, listen: false);
      _homeTeamController.text = gameSetupProvider.homeTeam;
      _awayTeamController.text = gameSetupProvider.awayTeam;
      _dateController.text =
          DateFormat('EEEE dd/MM/yyyy').format(gameSetupProvider.gameDate);
      homeTeam = gameSetupProvider.homeTeam.isNotEmpty
          ? gameSetupProvider.homeTeam
          : null;
      awayTeam = gameSetupProvider.awayTeam.isNotEmpty
          ? gameSetupProvider.awayTeam
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
    final gameSetupProvider = Provider.of<GameSetupProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        onSettingsPressed: () async {
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
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              CustomFormField(
                formKey: dateKey,
                controller: _dateController,
                labelText: 'Game Date',
                emptyValueError: 'Please select Game Date',
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (pickedDate != null) {
                    gameSetupProvider.setGameDate(pickedDate);
                    _dateController.text =
                        DateFormat('EEEE dd/MM/yyyy').format(pickedDate);
                  }
                  dateKey.currentState!.validate();
                  return null;
                },
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
                child: CustomButton(
                  text: 'Start Scoring',
                  width: MediaQuery.of(context).size.width * 0.6,
                  onPressed: () {
                    if (isValidSetup()) {
                      // Reset the score state for a new game
                      final scorePanelProvider =
                          Provider.of<ScorePanelProvider>(context,
                              listen: false);
                      scorePanelProvider.resetGame();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GameContainer(),
                        ),
                      );
                    }
                  },
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
