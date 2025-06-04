import 'package:flutter/material.dart';
import 'package:goalkeeper/pages/game_setup.dart';
import 'package:goalkeeper/pages/game_history.dart';
import 'package:goalkeeper/pages/results.dart';
import 'package:goalkeeper/pages/scoring.dart';

class Debug extends StatefulWidget {
  const Debug({super.key});

  @override
  DebugState createState() => DebugState();
}

class DebugState extends State<Debug> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const GameSetup(
        title: "Game Setup",
      ),
      const Scoring(
        title: "Scoring",
      ),
      const Results(
        title: "Results",
      ),
      const GameHistoryScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
