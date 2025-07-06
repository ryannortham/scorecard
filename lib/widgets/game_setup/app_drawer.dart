import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/screens/game_history.dart';
import 'package:scorecard/screens/team_list.dart';
import '../football_icon.dart';

/// A shared app drawer widget that includes navigation and settings
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<UserPreferencesProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // App Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Footy Score Card',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon_masked.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return FootballIcon(
                        size: 64,
                        color: Theme.of(context).colorScheme.onPrimary,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Favorite Team - hide on team-related screens to prevent navigation conflicts
          if (currentRoute != 'add_team' && currentRoute != 'team_list')
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Favorite Team'),
              subtitle: Text(
                userPreferences.favoriteTeam.isEmpty
                    ? 'Not set'
                    : userPreferences.favoriteTeam,
              ),
              trailing:
                  userPreferences.favoriteTeam.isNotEmpty
                      ? IconButton(
                        onPressed: () => userPreferences.setFavoriteTeam(''),
                        icon: const Icon(Icons.clear_outlined),
                        tooltip: 'Clear favorite team',
                      )
                      : null,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TeamList(
                          title: 'Select Favorite Team',
                          onTeamSelected: (teamName) {
                            userPreferences.setFavoriteTeam(teamName);
                          },
                        ),
                  ),
                );
              },
            ),

          // Manage Teams - hide on team-related screens to prevent navigation conflicts
          if (currentRoute != 'team_list' && currentRoute != 'add_team')
            ListTile(
              leading: const Icon(Icons.assignment_add),
              title: const Text('Manage Teams'),
              onTap: () {
                Navigator.pop(context);
                // Use pushReplacement when coming from add_team to prevent stack buildup
                if (currentRoute == 'add_team') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (context) => TeamList(
                            title: 'Manage Teams',
                            onTeamSelected: (teamName) {
                              // No action needed when selecting from manage teams
                            },
                          ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => TeamList(
                            title: 'Manage Teams',
                            onTeamSelected: (teamName) {
                              // No action needed when selecting from manage teams
                            },
                          ),
                    ),
                  );
                }
              },
            ),

          // Navigation Items - hide Game Results on team-related screens to prevent navigation conflicts
          if (currentRoute != 'game_history' &&
              currentRoute != 'add_team' &&
              currentRoute != 'team_list')
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Game Results'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                );
              },
            ),

          // Use Tallys Toggle
          ListTile(
            leading: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/tally/tally5.ico',
                width: 24,
                height: 24,
              ),
            ),
            title: const Text('Tally Marks'),
            trailing: Switch(
              value: userPreferences.useTallys,
              onChanged: (bool value) {
                userPreferences.setUseTallys(value);
              },
            ),
          ),

          // Countdown Timer Toggle - hide on scoring screen to prevent issues during active game
          if (currentRoute != 'scoring')
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Countdown Timer'),
              trailing: Switch(
                value: userPreferences.isCountdownTimer,
                onChanged: (bool value) {
                  userPreferences.setIsCountdownTimer(value);
                },
              ),
            ),

          // Theme Mode
          GestureDetector(
            onTapDown:
                (TapDownDetails details) => _showThemeModeMenu(
                  context,
                  userPreferences,
                  details.globalPosition,
                ),
            child: ListTile(
              leading: Icon(_getThemeModeIcon(userPreferences.themeMode)),
              title: Text(_getThemeModeText(userPreferences.themeMode)),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),

          // Color Theme
          GestureDetector(
            onTapDown:
                (TapDownDetails details) => _showColorThemeMenu(
                  context,
                  userPreferences,
                  details.globalPosition,
                ),
            child: ListTile(
              leading: Icon(
                Icons.palette_outlined,
                color:
                    userPreferences.colorTheme == 'dynamic'
                        ? Theme.of(context).colorScheme.primary
                        : userPreferences.getThemeColor(),
              ),
              title: Text(_getColorThemeText(userPreferences.colorTheme)),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

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

  String _getColorThemeText(String theme) {
    switch (theme) {
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
        return 'Dynamic';
    }
  }

  void _showThemeModeMenu(
    BuildContext context,
    UserPreferencesProvider provider,
    Offset tapPosition,
  ) {
    if (!context.mounted) return;

    final RenderObject? overlayRenderObject =
        Overlay.of(context).context.findRenderObject();

    if (overlayRenderObject is! RenderBox) return;

    final RenderBox overlay = overlayRenderObject;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    showMenu<ThemeMode>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              const Icon(Icons.light_mode_outlined),
              const SizedBox(width: 12),
              const Text('Light'),
              if (provider.themeMode == ThemeMode.light) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined),
              const SizedBox(width: 12),
              const Text('Dark'),
              if (provider.themeMode == ThemeMode.dark) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              const Icon(Icons.brightness_auto_outlined),
              const SizedBox(width: 12),
              const Text('System'),
              if (provider.themeMode == ThemeMode.system) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
      ],
    ).then((ThemeMode? result) {
      if (result != null) {
        provider.setThemeMode(result);
      }
    });
  }

  void _showColorThemeMenu(
    BuildContext context,
    UserPreferencesProvider provider,
    Offset tapPosition,
  ) {
    if (!context.mounted) return;

    final RenderObject? overlayRenderObject =
        Overlay.of(context).context.findRenderObject();

    if (overlayRenderObject is! RenderBox) return;

    final RenderBox overlay = overlayRenderObject;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    final colorOptions = <Map<String, dynamic>>[
      // Show dynamic only if device supports it
      if (provider.supportsDynamicColors)
        {
          'value': 'dynamic',
          'label': 'Dynamic',
          'color': const Color.fromRGBO(0, 145, 234, 1), // Fallback color
        },
      {
        'value': 'blue',
        'label': 'Blue',
        'color': const Color.fromRGBO(0, 145, 234, 1),
      },
      {
        'value': 'green',
        'label': 'Green',
        'color': const Color.fromRGBO(21, 183, 109, 1),
      },
      {
        'value': 'purple',
        'label': 'Purple',
        'color': const Color.fromRGBO(128, 100, 244, 1),
      },
      {
        'value': 'orange',
        'label': 'Orange',
        'color': const Color.fromRGBO(255, 158, 0, 1),
      },
      {
        'value': 'pink',
        'label': 'Pink',
        'color': const Color.fromRGBO(238, 33, 114, 1),
      },
    ];

    showMenu<String>(
      context: context,
      position: position,
      items:
          colorOptions.map((option) {
            return PopupMenuItem<String>(
              value: option['value'] as String,
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 16,
                    color:
                        option['value'] == 'dynamic'
                            ? Theme.of(context).colorScheme.primary
                            : option['color'] as Color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option['label'] as String)),
                  if (provider.colorTheme == option['value']) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
    ).then((String? result) {
      if (result != null) {
        provider.setColorTheme(result);
      }
    });
  }
}
