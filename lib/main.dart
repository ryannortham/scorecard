import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
  runApp(const GoalKeeper());
}

class GoalKeeper extends StatelessWidget {
  const GoalKeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const LandingPage(title: 'GoalKeeper'),
    );
  }
}
