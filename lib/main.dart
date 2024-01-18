import 'package:flutter/material.dart';
// import 'package:json_theme/json_theme.dart';
// import 'package:flutter/services.dart';
// import 'dart:convert';
import 'package:goalkeeper/pages/landing_page.dart';
import 'package:goalkeeper/providers/score_panel_state.dart';
import 'package:goalkeeper/providers/game_setup_state.dart';
import 'package:provider/provider.dart';
// import 'package:logging/logging.dart';

// final _logger = Logger('main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  // final themeJson = jsonDecode(themeStr);
  // final theme = ThemeDecoder.decodeThemeData(themeJson) ?? ThemeData();
  final theme = ThemeData();
  runApp(GoalKeeper(theme: theme));
}

class GoalKeeper extends StatelessWidget {
  final ThemeData? theme;

  const GoalKeeper({Key? key, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => GameSetupState()),
          ChangeNotifierProvider(create: (context) => ScorePanelState()),
        ],
        child: MaterialApp(
            title: 'GoalKeeper',
            theme: theme,
            home: const LandingPage(
              title: 'GoalKeeper',
            )));
  }
}
