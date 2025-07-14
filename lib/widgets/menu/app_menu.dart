import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_preferences_provider.dart';
import '../../services/color_service.dart';
import '../../services/game_state_service.dart';

/// A Material 3 compliant menu that provides access to app settings and preferences.
/// Follows Material 3 menu guidelines for clean, simple design.
class AppMenu extends StatelessWidget {
  /// The identifier for the current route/screen.
  final String currentRoute;

  const AppMenu({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, userPreferences, _) {
        return MenuAnchor(
          menuChildren: [
            // Tally Marks Toggle
            MenuItemButton(
              leadingIcon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/tally/tally5.ico',
                  width: 20,
                  height: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailingIcon: Switch.adaptive(
                value: userPreferences.useTallys,
                onChanged: userPreferences.setUseTallys,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tally Marks'),
                  Text(
                    userPreferences.useTallys
                        ? 'Display Tally Marks'
                        : 'Display Numbers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              onPressed:
                  () =>
                      userPreferences.setUseTallys(!userPreferences.useTallys),
            ),

            // Timer Mode Toggle
            MenuItemButton(
              onPressed:
                  currentRoute == 'scoring'
                      ? null
                      : () => _toggleTimerMode(
                        userPreferences,
                        !userPreferences.isCountdownTimer,
                      ),
              leadingIcon: const Icon(Icons.timer_outlined),
              trailingIcon: Switch.adaptive(
                value: userPreferences.isCountdownTimer,
                onChanged:
                    currentRoute == 'scoring'
                        ? null
                        : (bool newValue) =>
                            _toggleTimerMode(userPreferences, newValue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Countdown Timer'),
                  Text(
                    userPreferences.isCountdownTimer
                        ? 'Timer Counts Down'
                        : 'Timer Counts Up',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Theme Settings
            SubmenuButton(
              leadingIcon: Icon(_getThemeModeIcon(userPreferences.themeMode)),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.light_mode_outlined),
                  child: const Text('Light'),
                  onPressed:
                      () => userPreferences.setThemeMode(ThemeMode.light),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.dark_mode_outlined),
                  child: const Text('Dark'),
                  onPressed: () => userPreferences.setThemeMode(ThemeMode.dark),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.brightness_auto_outlined),
                  child: const Text('System'),
                  onPressed:
                      () => userPreferences.setThemeMode(ThemeMode.system),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme'),
                  Text(
                    _getThemeModeName(userPreferences.themeMode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            SubmenuButton(
              leadingIcon: Icon(
                Icons.palette_outlined,
                color:
                    userPreferences.colorTheme == 'dynamic'
                        ? context.colors.primary
                        : userPreferences.getThemeColor(),
              ),
              menuChildren: _buildColorThemeMenuItems(context, userPreferences),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Color'),
                  Text(
                    _getColorThemeName(userPreferences.colorTheme),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.more_vert_outlined),
              tooltip: 'Menu',
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        );
      },
    );
  }

  /// Builds color theme menu items
  List<Widget> _buildColorThemeMenuItems(
    BuildContext context,
    UserPreferencesProvider userPreferences,
  ) {
    final colorOptions = ColorService.getColorOptions(
      supportsDynamicColors: userPreferences.supportsDynamicColors,
    );

    return colorOptions.map((option) {
      return MenuItemButton(
        leadingIcon: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: option['color'] as Color,
            shape: BoxShape.circle,
          ),
        ),
        child: Text(option['label'] as String),
        onPressed:
            () => userPreferences.setColorTheme(option['value'] as String),
      );
    }).toList();
  }

  /// Helper methods
  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getColorThemeName(String colorTheme) {
    switch (colorTheme) {
      case 'dynamic':
        return 'Dynamic';
      case 'blue':
        return 'Blue';
      case 'green':
        return 'Green';
      case 'purple':
        return 'Purple';
      case 'orange':
        return 'Orange';
      case 'pink':
        return 'Pink';
      default:
        return 'Blue'; // fallback
    }
  }

  /// Navigation and action methods
  Future<void> _toggleTimerMode(
    UserPreferencesProvider userPreferences,
    bool newValue,
  ) async {
    await userPreferences.setIsCountdownTimer(newValue);

    // Update the current game's timer mode without resetting the timer
    final gameState = GameStateService.instance;
    gameState.setCountdownMode(newValue);
  }
}
