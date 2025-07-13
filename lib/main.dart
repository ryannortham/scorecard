import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/screens/scoring/scoring_setup_screen.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_state_service.dart';

void main() {
  // Preserve the native splash screen until the app is ready
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize logging system
  AppLogger.initialize();
  AppLogger.info('Score Card app starting', component: 'Main');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider.value(value: GameStateService.instance),
        ChangeNotifierProvider(create: (_) => TeamsProvider()),
      ],
      child: const FootyScoreCardApp(),
    ),
  );
}

class FootyScoreCardApp extends StatelessWidget {
  const FootyScoreCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, userPreferences, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Use dynamic colors if user selected 'dynamic' theme
            final useDynamicColors = userPreferences.colorTheme == 'dynamic';

            // Get color schemes
            final lightColorScheme =
                (useDynamicColors && lightDynamic != null)
                    ? lightDynamic
                    : ColorScheme.fromSeed(
                      seedColor: userPreferences.getThemeColor(),
                    );

            final darkColorScheme =
                (useDynamicColors && darkDynamic != null)
                    ? darkDynamic
                    : ColorScheme.fromSeed(
                      seedColor: userPreferences.getThemeColor(),
                      brightness: Brightness.dark,
                    );

            return MaterialApp(
              title: 'Score Card',
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                // Ensure Material 3 surface variations are respected
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(elevation: 1),
                ),
                cardTheme: const CardThemeData(elevation: 1),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                // Ensure Material 3 surface variations are respected
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(elevation: 1),
                ),
                cardTheme: const CardThemeData(elevation: 1),
              ),
              themeMode: userPreferences.themeMode,
              home: const SplashWrapper(),
            );
          },
        );
      },
    );
  }
}

/// Wrapper widget to handle native splash screen removal with fade effect
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _removeSplash();
  }

  void _removeSplash() async {
    // Wait for the first frame to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Give a brief moment for the UI to settle, then remove splash with fade
      await Future.delayed(const Duration(milliseconds: 200));
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ScoringSetupScreen();
  }
}
