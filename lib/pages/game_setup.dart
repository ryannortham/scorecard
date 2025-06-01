import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:intl/intl.dart';
import 'package:customizable_counter/customizable_counter.dart';
import 'team_list.dart';
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
              const Spacer(flex: 1),
              _buildTextField(
                formKey: homeTeamKey,
                controller: _homeTeamController,
                labelText: 'Home Team',
                emptyValueError: 'Please select Home Team',
                onTap: () async {
                  homeTeam = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TeamList(
                            title: 'Select Home Team',
                            onTeamSelected: (teamName) {
                              gameSetupProvider.setHomeTeam(teamName);
                              _homeTeamController.text = teamName;
                            })),
                  );
                  homeTeamKey.currentState!.validate();
                  return null;
                },
              ),
              const Spacer(flex: 1),
              _buildTextField(
                  formKey: awayTeamKey,
                  controller: _awayTeamController,
                  labelText: 'Away Team',
                  emptyValueError: 'Please select Away Team',
                  onTap: () async {
                    awayTeam = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TeamList(
                              title: 'Select Away Team',
                              onTeamSelected: (teamName) {
                                gameSetupProvider.setAwayTeam(teamName);
                                _awayTeamController.text = teamName;
                              })),
                    );
                    awayTeamKey.currentState!.validate();
                    return null;
                  }),
              const Spacer(flex: 1),
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
              const Spacer(flex: 1),
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
              const Spacer(flex: 1),
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
