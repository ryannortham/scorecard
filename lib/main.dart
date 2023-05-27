import 'package:flutter/material.dart';
import 'pages/landing_page.dart';

void main() {
  runApp(const GoalKeeper());
}

class GoalKeeper extends StatelessWidget {
  const GoalKeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoalKeeper',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        canvasColor: Colors.indigo[50],
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.indigo,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
      home: const LandingPage(title: 'GoalKeeper'),
    );
  }
}
