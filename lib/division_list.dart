import 'package:flutter/material.dart';

class DivisionList extends StatelessWidget {
  DivisionList(
      {Key? key, required this.title, required this.onDivisionSelected})
      : super(key: key);
  final String title;
  final void Function(String) onDivisionSelected;
  final List<String> divisionNames = [
    'Division 1',
    'Division 2',
    'Division 3',
    'Division 4',
    'Division 5',
    'Division 6',
    'Division 7',
    'Division 8',
    'Division 9',
    'Division 10',
    'Division 11',
    'Division 12',
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
          itemCount: divisionNames.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                title: Text(divisionNames[index]),
                onTap: () {
                  // Call the callback function with the selected Division name
                  onDivisionSelected(divisionNames[index]);
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
