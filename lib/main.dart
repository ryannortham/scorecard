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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        // Show loading screen until settings are loaded
        if (!settingsProvider.loaded) {
          return MaterialApp(
            title: 'GoalKeeper',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final seedColor = settingsProvider.getThemeColor();

            // Use dynamic colors if user selected 'adaptive' theme
            final useDynamicColors = settingsProvider.colorTheme == 'adaptive';

            // Get color schemes
            final lightColorScheme = (useDynamicColors && lightDynamic != null)
                ? lightDynamic
                : ColorScheme.fromSeed(seedColor: seedColor);

            final darkColorScheme = (useDynamicColors && darkDynamic != null)
                ? darkDynamic
                : ColorScheme.fromSeed(
                    seedColor: seedColor, brightness: Brightness.dark);

            return MaterialApp(
              title: 'GoalKeeper',
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                // Enhanced button themes for better visibility
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: lightColorScheme.primary,
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightColorScheme.primary,
                    side: BorderSide(
                      color: lightColorScheme.onSurface,
                      width: 1.5,
                    ),
                  ),
                ),
                toggleButtonsTheme: ToggleButtonsThemeData(
                  borderColor: lightColorScheme.onSurface,
                  selectedBorderColor: lightColorScheme.primary,
                  fillColor: lightColorScheme.primaryContainer,
                  selectedColor: lightColorScheme.onPrimaryContainer,
                  borderWidth: 1.5,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                // Enhanced button themes for better visibility in dark mode
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: darkColorScheme.primary,
                    // Add subtle background for better visibility in dark mode
                    backgroundColor: darkColorScheme.primary.withOpacity(0.08),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkColorScheme.primary,
                    side: BorderSide(
                      color: darkColorScheme.onSurface,
                      width: 2.0, // Thicker border for dark mode visibility
                    ),
                    backgroundColor: darkColorScheme.surface,
                  ),
                ),
                toggleButtonsTheme: ToggleButtonsThemeData(
                  borderColor: darkColorScheme.onSurface,
                  selectedBorderColor: darkColorScheme.primary,
                  fillColor: darkColorScheme.primaryContainer,
                  selectedColor: darkColorScheme.onPrimaryContainer,
                  color: darkColorScheme.onSurface,
                  borderWidth: 2.0, // Thicker for better visibility
                ),
              ),
              themeMode: settingsProvider.themeMode,
              home: const LandingPage(title: 'GoalKeeper'),
            );
          },
        );
      },
    );
  }
}
