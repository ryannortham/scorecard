import 'package:flutter/material.dart';

class GroundList extends StatelessWidget {
  GroundList({Key? key, required this.title, required this.onGroundSelected})
      : super(key: key);
  final String title;
  final void Function(String) onGroundSelected;
  final List<String> groundNames = [
    'Ground 1',
    'Ground 2',
    'Ground 3',
    'Ground 4',
    'Ground 5',
    'Ground 6',
    'Ground 7',
    'Ground 8',
    'Ground 9',
    'Ground 10',
    'Ground 11',
    'Ground 12',
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
          itemCount: groundNames.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                title: Text(groundNames[index]),
                onTap: () {
                  // Call the callback function with the selected Ground name
                  onGroundSelected(groundNames[index]);
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
