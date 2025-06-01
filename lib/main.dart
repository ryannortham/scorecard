import 'package:flutter/material.dart';
import 'package:goalkeeper/pages/landing_page.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final theme = ThemeData();
  runApp(GoalKeeper(theme: theme));
}

class GoalKeeper extends StatelessWidget {
  final ThemeData? theme;

  const GoalKeeper({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => GameSetupProvider()),
          ChangeNotifierProvider(create: (context) => ScorePanelProvider()),
        ],
        child: MaterialApp(
            title: 'GoalKeeper',
            theme: theme,
            home: const LandingPage(
              title: 'GoalKeeper',
            )));
  }
}
