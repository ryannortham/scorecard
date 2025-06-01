import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:intl/intl.dart';
import 'package:customizable_counter/customizable_counter.dart';
import 'team_list.dart';
import 'scoring.dart';
import '../providers/teams_provider.dart';

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
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('EEEE dd/MM/yyyy').format(DateTime.now()),
  );

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.40,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  Widget _buildTextField({
    required GlobalKey<FormState> formKey,
    required TextEditingController controller,
    required String labelText,
    required String emptyValueError,
    required Future<String?> Function() onTap,
  }) {
    return Form(
      key: formKey,
      child: TextFormField(
        readOnly: true,
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return emptyValueError;
          }
          return null;
        },
        onTap: onTap,
      ),
    );
  }

  bool isValidSetup() {
    bool dateValid = dateKey.currentState!.validate();
    bool homeTeamValid = homeTeamKey.currentState!.validate();
    bool awayTeamValid = awayTeamKey.currentState!.validate();

    return dateValid && homeTeamValid && awayTeamValid;
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
    final teamsProvider = Provider.of<TeamsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildTextField(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          formKey: homeTeamKey,
                          controller: _homeTeamController,
                          labelText: 'Home Team',
                          emptyValueError: 'Please select Home Team',
                          onTap: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamList(
                                  title: 'Select Home Team',
                                  onTeamSelected: (teamName) {
                                    gameSetupProvider.setHomeTeam(teamName);
                                    _homeTeamController.text = teamName;
                                  },
                                ),
                                settings: RouteSettings(arguments: awayTeam),
                              ),
                            );
                            // If a team was deleted and it matches the current selection, clear
                            if (result != null && result == homeTeam) {
                              // Only clear if the team was actually deleted (not reselected)
                              if (!teamsProvider.teams.contains(result)) {
                                homeTeam = null;
                                _homeTeamController.text = '';
                                gameSetupProvider.setHomeTeam('');
                              } else {
                                // Reselected the same team, keep selection
                                homeTeam = result;
                                _homeTeamController.text = result;
                                gameSetupProvider.setHomeTeam(result);
                              }
                            } else if (result != null) {
                              homeTeam = result;
                              _homeTeamController.text = result;
                              gameSetupProvider.setHomeTeam(result);
                            }
                            homeTeamKey.currentState!.validate();
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          formKey: awayTeamKey,
                          controller: _awayTeamController,
                          labelText: 'Away Team',
                          emptyValueError: 'Please select Away Team',
                          onTap: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamList(
                                  title: 'Select Away Team',
                                  onTeamSelected: (teamName) {
                                    gameSetupProvider.setAwayTeam(teamName);
                                    _awayTeamController.text = teamName;
                                  },
                                ),
                                settings: RouteSettings(arguments: homeTeam),
                              ),
                            );
                            if (result != null && result == awayTeam) {
                              if (!teamsProvider.teams.contains(result)) {
                                awayTeam = null;
                                _awayTeamController.text = '';
                                gameSetupProvider.setAwayTeam('');
                              } else {
                                awayTeam = result;
                                _awayTeamController.text = result;
                                gameSetupProvider.setAwayTeam(result);
                              }
                            } else if (result != null) {
                              awayTeam = result;
                              _awayTeamController.text = result;
                              gameSetupProvider.setAwayTeam(result);
                            }
                            awayTeamKey.currentState!.validate();
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.swap_vert),
                        label: Text('Swap'),
                        onPressed: (homeTeam == null && awayTeam == null)
                            ? null
                            : () {
                                final temp = homeTeam;
                                homeTeam = awayTeam;
                                awayTeam = temp;
                                _homeTeamController.text = homeTeam ?? '';
                                _awayTeamController.text = awayTeam ?? '';
                                gameSetupProvider.setHomeTeam(homeTeam ?? '');
                                gameSetupProvider.setAwayTeam(awayTeam ?? '');
                                homeTeamKey.currentState?.validate();
                                awayTeamKey.currentState?.validate();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Quarter Minutes'),
                  CustomizableCounter(
                    borderWidth: 2,
                    borderRadius: 36,
                    textSize:
                        Theme.of(context).textTheme.titleLarge?.fontSize ?? 22,
                    count: gameSetupProvider.quarterMinutes.toDouble(),
                    minCount: 1,
                    maxCount: 60,
                    showButtonText: false,
                    onCountChange: (count) {
                      gameSetupProvider.setQuarterMinutes(count.toInt());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Countdown Timer'),
                  Switch(
                    value: gameSetupProvider.isCountdownTimer,
                    onChanged: (bool value) {
                      gameSetupProvider.setIsCountdownTimer(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildButton('Cancel', () {
                    Navigator.pop(context);
                  }),
                  _buildButton('Start Scoring', () {
                    if (isValidSetup()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const Scoring(title: 'Scoring'),
                        ),
                      );
                    }
                  }),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
