// app menu with settings and preferences

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';

/// material 3 menu for app settings access
class AppMenu extends StatelessWidget {
  const AppMenu({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesViewModel>(
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
                onChanged:
                    (value) => userPreferences.setUseTallys(value: value),
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
                  () => userPreferences.setUseTallys(
                    value: !userPreferences.useTallys,
                  ),
            ),

            // Timer Mode Toggle
            MenuItemButton(
              onPressed:
                  currentRoute == 'scoring'
                      ? null
                      : () => _toggleTimerMode(
                        context,
                        userPreferences,
                        !userPreferences.isCountdownTimer,
                      ),
              leadingIcon: const Icon(Icons.timer_outlined),
              trailingIcon: Switch.adaptive(
                value: userPreferences.isCountdownTimer,
                onChanged:
                    currentRoute == 'scoring'
                        ? null
                        : (bool newValue) => _toggleTimerMode(
                          context,
                          userPreferences,
                          newValue,
                        ),
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
                  const Text('Colour'),
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

  /// builds colour theme menu items
  List<Widget> _buildColorThemeMenuItems(
    BuildContext context,
    PreferencesViewModel userPreferences,
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

  // helper methods
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
        return 'Blue';
    }
  }

  /// toggles timer mode between countdown and count up
  Future<void> _toggleTimerMode(
    BuildContext context,
    PreferencesViewModel userPreferences,
    bool newValue,
  ) async {
    // Read context before async gap
    final gameState = context.read<GameViewModel>();

    await userPreferences.setIsCountdownTimer(value: newValue);

    // Update the current game's timer mode without resetting the timer
    gameState.setCountdownMode(isCountdownMode: newValue);
  }
}
