import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:goalkeeper/pages/landing_page.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/teams_provider.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameSetupProvider()),
        ChangeNotifierProvider(create: (_) => ScorePanelProvider()),
        ChangeNotifierProvider(create: (_) => TeamsProvider()),
      ],
      child: const GoalKeeperApp(),
    ),
  );
}

class GoalKeeperApp extends StatelessWidget {
  const GoalKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'GoalKeeper',
          theme: ThemeData(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                    seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const LandingPage(title: 'GoalKeeper'),
        );
      },
    );
  }
}
