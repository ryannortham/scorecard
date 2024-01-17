import 'package:flutter/material.dart';
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
  bool isTimerEnabled = true;
  int quarterMinutes = 15;
  int _selectedIndex = 0;
  String? homeTeam;
  String? awayTeam;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('EEEE dd/MM/yyyy').format(DateTime.now()),
  );
  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();

  void onHomeTeamSelected(String teamName) {
    setState(() {
      homeTeam = teamName;
    });
    _homeTeamController.text = teamName;
  }

  void onAwayTeamSelected(String teamName) {
    setState(() {
      awayTeam = teamName;
    });
    _awayTeamController.text = teamName;
  }

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
                  // Show date picker dialog
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (pickedDate != null) {
                    // Update text field value when date is picked
                    setState(() {
                      _dateController.text =
                          DateFormat('EEEE dd/MM/yyyy').format(pickedDate);
                    });
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
                            onTeamSelected: onHomeTeamSelected)),
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
                    homeTeam = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TeamList(
                              title: 'Select Away Team',
                              onTeamSelected: onAwayTeamSelected)),
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
                    count: 15,
                    step: 1,
                    minCount: 1,
                    maxCount: 60,
                    showButtonText: false,
                    onCountChange: (count) {},
                  ),
                ],
              ),
              const Spacer(flex: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Countdown Timer'),
                  Switch(
                    value: isTimerEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        isTimerEnabled = value;
                      });
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
                      // Validation successful, navigate to scoring page
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
