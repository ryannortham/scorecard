import 'package:flutter/material.dart';

class TeamList extends StatelessWidget {
  TeamList({Key? key, required this.title, required this.onTeamSelected})
      : super(key: key);
  final String title;
  final void Function(String) onTeamSelected;
  final List<String> teamNames = [
    'Team 1',
    'Team 2',
    'Team 3',
    'Team 4',
    'Team 5',
    'Team 6',
    'Team 7',
    'Team 8',
    'Team 9',
    'Team 10',
    'Team 11',
    'Team 12',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: teamNames.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                title: Text(teamNames[index]),
                onTap: () {
                  // Call the callback function with the selected team name
                  onTeamSelected(teamNames[index]);
                  // Pop the screen to return to the first screen
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
