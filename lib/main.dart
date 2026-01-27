// app entry point, provider setup, and theme configuration

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

Future<void> main() async {
  // preserve splash screen until app is ready
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  AppLogger.initialize();
  AppLogger.info('Score Card app starting', component: 'Main');

  try {
    await dotenv.load();
    AppLogger.info('Environment variables loaded', component: 'Main');
  } on Exception catch (e) {
    AppLogger.error('Failed to load .env file: $e', component: 'Main');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => GameStateService()),
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
            final useDynamicColors = userPreferences.colorTheme == 'dynamic';

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
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(elevation: 1),
                ),
                cardTheme: const CardThemeData(elevation: 1),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
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

/// handles native splash screen removal with fade transition
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    unawaited(_removeSplash());
  }

  Future<void> _removeSplash() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // brief delay for ui to settle before removing splash
      await Future<void>.delayed(const Duration(milliseconds: 200));
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const NavigationShell();
  }
}
