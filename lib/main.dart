import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/score_counter_provider.dart';
import 'package:goalkeeper/widgets/score_counter.dart';
import 'package:goalkeeper/widgets/score_panel.dart';
import 'package:provider/provider.dart';
import 'providers/score_panel_state.dart';
import 'pages/landing_page.dart';

void main() {
  runApp(const GoalKeeper());
}

class GoalKeeper extends StatelessWidget {
  const GoalKeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScoreCounterProvider()),
          // Add other providers if needed
        ],
        child: MaterialApp(
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
            // home: const LandingPage(title: 'GoalKeeper'),
            home:
                ScoreCounter(label: "label", isGoal: true, isHomeTeam: true)));
  }
}
