import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:intl/intl.dart';
import 'package:customizable_counter/customizable_counter.dart';
import 'team_list.dart';
import 'scoring.dart';

class GameSetup extends StatefulWidget {
  const GameSetup({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<GameSetup> createState() => _GameSetupState();
}

class _GameSetupState extends State<GameSetup> {
  int _selectedIndex = 0;
  String? homeTeam;
  String? awayTeam;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('EEEE dd/MM/yyyy').format(DateTime.now()),
  );

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
    required TextEditingController controller,
    required String labelText,
    required String emptyValueError,
    required Future<String?> Function() onTap,
  }) {
    return TextFormField(
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
    );
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

                  return null;
                },
              ),
              const Spacer(flex: 1),
              _buildTextField(
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
                  return null;
                },
              ),
              const Spacer(flex: 1),
              _buildTextField(
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
                    return null;
                  }),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Quarter Minutes'),
                  CustomizableCounter(
                    backgroundColor:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderWidth: 2,
                    borderRadius: 100,
                    textSize: 22,
                    count: gameSetupProvider.quarterMinutes.toDouble(),
                    step: 1,
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
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const Scoring(title: 'Scoring'),
                        ),
                      );
                    }
                  }),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Game Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            label: 'Scoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}
