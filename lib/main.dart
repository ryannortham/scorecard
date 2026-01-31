// app entry point, provider setup, and theme configuration

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/repositories/game_repository.dart';
import 'package:scorecard/repositories/shared_prefs_game_repository.dart';
import 'package:scorecard/router/app_router.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/viewmodels/results_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';

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
        Provider<GameRepository>(create: (_) => SharedPrefsGameRepository()),
        ChangeNotifierProvider(create: (_) => PreferencesViewModel()),
        ChangeNotifierProvider(create: (_) => GameViewModel()),
        ChangeNotifierProvider(create: (_) => TeamsViewModel()),
        ChangeNotifierProvider(create: (_) => ResultsViewModel()),
      ],
      child: const FootyScoreCardApp(),
    ),
  );
}

class FootyScoreCardApp extends StatelessWidget {
  const FootyScoreCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesViewModel>(
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

            return MaterialApp.router(
              routerConfig: appRouter,
              title: 'Score Card',
              debugShowCheckedModeBanner: false,
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
              builder: (context, child) {
                return SplashWrapper(child: child);
              },
            );
          },
        );
      },
    );
  }
}

/// handles native splash screen removal with fade transition
///
/// waits for critical data (preferences, teams, results) to load before
/// removing the splash screen, with a maximum timeout to prevent blocking
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({required this.child, super.key});

  final Widget? child;

  /// Maximum time to wait for data before removing splash anyway
  static const Duration maxWaitDuration = Duration(milliseconds: 500);

  /// Polling interval when checking if data is loaded
  static const Duration pollInterval = Duration(milliseconds: 50);

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
      await _waitForCriticalData();
      FlutterNativeSplash.remove();
    });
  }

  /// Waits for critical ViewModels to finish loading, with a max timeout.
  Future<void> _waitForCriticalData() async {
    final prefsVm = context.read<PreferencesViewModel>();
    final teamsVm = context.read<TeamsViewModel>();
    final resultsVm = context.read<ResultsViewModel>();

    final deadline = DateTime.now().add(SplashWrapper.maxWaitDuration);

    // Poll until all are loaded or timeout reached
    while (DateTime.now().isBefore(deadline)) {
      if (prefsVm.loaded && teamsVm.loaded && resultsVm.loaded) {
        AppLogger.debug(
          'SplashWrapper: All critical data loaded',
          component: 'Main',
        );
        return;
      }
      await Future<void>.delayed(SplashWrapper.pollInterval);
    }

    AppLogger.debug(
      'SplashWrapper: Timeout reached, proceeding without full data. '
      'prefs=${prefsVm.loaded}, teams=${teamsVm.loaded}, '
      'results=${resultsVm.loaded}',
      component: 'Main',
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
