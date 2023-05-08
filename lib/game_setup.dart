import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:customizable_counter/customizable_counter.dart';
import 'team_list.dart';
import 'ground_list.dart';
import 'division_list.dart';

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
  String? ground;
  String? division;

  final GlobalKey _formKey = GlobalKey<FormState>();
  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();
  final TextEditingController _groundController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('EEEE dd/MM/yyyy').format(DateTime.now()),
  );

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

  void onGroundSelected(String groundName) {
    setState(() {
      ground = groundName;
    });
    _groundController.text = groundName;
  }

  void onDivisionSelected(String divisionName) {
    setState(() {
      division = divisionName;
    });
    _divisionController.text = divisionName;
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              TextField(
                readOnly: true,
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Game Date',
                ),
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
                },
              ),
              const Spacer(flex: 1),
              TextField(
                  readOnly: true,
                  controller: _divisionController,
                  decoration: const InputDecoration(
                    labelText: 'Division',
                  ),
                  onTap: () async {
                    ground = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DivisionList(
                          title: 'Select Devision',
                          onDivisionSelected: onDivisionSelected,
                        ),
                      ),
                    );
                  }),
              const Spacer(flex: 1),
              TextField(
                readOnly: true,
                controller: _homeTeamController,
                decoration: const InputDecoration(
                  labelText: 'Home Team',
                ),
                onTap: () async {
                  homeTeam = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TeamList(
                            title: 'Select Home Team',
                            onTeamSelected: onHomeTeamSelected)),
                  );
                },
              ),
              const Spacer(flex: 1),
              TextField(
                  readOnly: true,
                  controller: _awayTeamController,
                  decoration: const InputDecoration(
                    labelText: 'Away Team',
                  ),
                  onTap: () async {
                    homeTeam = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TeamList(
                              title: 'Select Away Team',
                              onTeamSelected: onAwayTeamSelected)),
                    );
                  }),
              const Spacer(flex: 1),
              TextField(
                  readOnly: true,
                  controller: _groundController,
                  decoration: const InputDecoration(
                    labelText: 'Ground',
                  ),
                  onTap: () async {
                    ground = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GroundList(
                              title: 'Select Ground',
                              onGroundSelected: onGroundSelected)),
                    );
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
                    incrementIcon: const Icon(
                      Icons.add,
                    ),
                    decrementIcon: const Icon(
                      Icons.remove,
                    ),
                    onCountChange: (count) {},
                    onIncrement: (count) {},
                    onDecrement: (count) {},
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.47,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: primaryButtonStyle,
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.47,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle save button press
                      },
                      style: primaryButtonStyle,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
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
