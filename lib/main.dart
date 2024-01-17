import 'package:flutter/material.dart';
import 'package:json_theme/json_theme.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:goalkeeper/pages/landing_page.dart';
import 'package:goalkeeper/providers/score_panel_state.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

final _logger = Logger('main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final theme = await loadTheme('assets/appainter_theme.json');

  runApp(GoalKeeper(theme: theme));
}

Future<ThemeData> loadTheme(String path) async {
  try {
    final themeString = await rootBundle.loadString(path);
    final themeJson = json.decode(themeString);
    return ThemeDecoder.decodeThemeData(themeJson)!;
  } catch (e) {
    _logger.severe('Failed to load theme: $e');
    return ThemeData(); // Fallback to default theme
  }
}

class GoalKeeper extends StatelessWidget {
  final ThemeData theme;

  const GoalKeeper({Key? key, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ScorePanelState()),
          // Add other providers if needed
        ],
        child: MaterialApp(
            title: 'GoalKeeper',
            theme: theme,
            home: const LandingPage(
              title: 'GoalKeeper',
            )));
  }
}
