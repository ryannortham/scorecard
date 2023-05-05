import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GameSetup extends StatefulWidget {
  const GameSetup({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<GameSetup> createState() => _GameSetupState();
}

class _GameSetupState extends State<GameSetup> {
  final dateController = TextEditingController(
    text: DateFormat('EEEE dd/MM/yyyy').format(DateTime.now()),
  );

  @override
  void dispose() {
    dateController.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Game Date',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                // Show date picker dialog
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (pickedDate != null) {
                  // Update text field value when date is picked
                  setState(() {
                    dateController.text =
                        DateFormat('EEEE dd/MM/yyyy').format(pickedDate);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
