import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/teams_provider.dart';
import 'package:goalkeeper/providers/user_preferences_provider.dart';
import 'package:goalkeeper/screens/home_screen.dart';
import 'package:goalkeeper/services/app_logger.dart';

void main() {
  // Initialize logging system
  AppLogger.initialize();
  AppLogger.info('Score Card app starting', component: 'Main');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => GameSetupAdapter()),
        ChangeNotifierProvider(create: (_) => ScorePanelAdapter()),
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
            final seedColor = userPreferences.getThemeColor();

            // Use dynamic colors if user selected 'adaptive' theme
            final useDynamicColors = userPreferences.colorTheme == 'adaptive';

            // Get color schemes
            final lightColorScheme = (useDynamicColors && lightDynamic != null)
                ? lightDynamic
                : ColorScheme.fromSeed(seedColor: seedColor);

            final darkColorScheme = (useDynamicColors && darkDynamic != null)
                ? darkDynamic
                : ColorScheme.fromSeed(
                    seedColor: seedColor, brightness: Brightness.dark);

            return MaterialApp(
              title: 'Score Card',
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                // Enhanced button themes for better visibility
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: lightColorScheme.onPrimary,
                    backgroundColor: lightColorScheme.primary,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    disabledBackgroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.12),
                    elevation: 2,
                    shadowColor: lightColorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    foregroundColor: lightColorScheme.onPrimary,
                    backgroundColor: lightColorScheme.primary,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    disabledBackgroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: lightColorScheme.primary,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightColorScheme.primary,
                    backgroundColor: Colors.transparent,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    side: BorderSide(
                      color: lightColorScheme.outline,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: lightColorScheme.onSurfaceVariant,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                toggleButtonsTheme: ToggleButtonsThemeData(
                  borderColor: lightColorScheme.outline,
                  selectedBorderColor: lightColorScheme.primary,
                  fillColor: lightColorScheme.primaryContainer,
                  selectedColor: lightColorScheme.onPrimaryContainer,
                  color: lightColorScheme.onSurface,
                  borderWidth: 1.5,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: lightColorScheme.surfaceContainer,
                    foregroundColor: lightColorScheme.onSurface,
                    selectedBackgroundColor: lightColorScheme.primary,
                    selectedForegroundColor: lightColorScheme.onPrimary,
                    disabledForegroundColor:
                        lightColorScheme.onSurface.withValues(alpha: 0.38),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                // Complete button theme configuration for dark mode
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: darkColorScheme.onPrimary,
                    backgroundColor: darkColorScheme.primary,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    disabledBackgroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.12),
                    elevation: 2,
                    shadowColor: darkColorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    foregroundColor: darkColorScheme.onPrimary,
                    backgroundColor: darkColorScheme.primary,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    disabledBackgroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: darkColorScheme.primary,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    // Add subtle background for better visibility in dark mode
                    backgroundColor:
                        darkColorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkColorScheme.primary,
                    backgroundColor: darkColorScheme.surface,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    side: BorderSide(
                      color: darkColorScheme.outline,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: darkColorScheme.onSurfaceVariant,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                toggleButtonsTheme: ToggleButtonsThemeData(
                  borderColor: darkColorScheme.outline,
                  selectedBorderColor: darkColorScheme.primary,
                  fillColor: darkColorScheme.primaryContainer,
                  selectedColor: darkColorScheme.onPrimaryContainer,
                  color: darkColorScheme.onSurface,
                  borderWidth: 1.5,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: darkColorScheme.surfaceContainer,
                    foregroundColor: darkColorScheme.onSurface,
                    selectedBackgroundColor: darkColorScheme.primary,
                    selectedForegroundColor: darkColorScheme.onPrimary,
                    disabledForegroundColor:
                        darkColorScheme.onSurface.withValues(alpha: 0.38),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              themeMode: userPreferences.themeMode,
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
