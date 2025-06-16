import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/providers/user_preferences_provider.dart';
import 'package:goalkeeper/screens/team_list.dart';
import 'package:goalkeeper/screens/game_history.dart';

/// A shared app drawer widget that includes navigation and settings
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<UserPreferencesProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // App Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Footy Score Card',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const Divider(),

          // Favorite Team
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Favorite Team'),
            subtitle: Text(
              userPreferences.favoriteTeam.isEmpty
                  ? 'Not set'
                  : userPreferences.favoriteTeam,
            ),
            trailing: userPreferences.favoriteTeam.isNotEmpty
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
                  builder: (context) => TeamList(
                    title: 'Select Favorite Team',
                    onTeamSelected: (teamName) {
                      userPreferences.setFavoriteTeam(teamName);
                    },
                  ),
                ),
              );
            },
          ),

          // Navigation Items
          if (currentRoute != 'game_history')
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Game History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                );
              },
            ),

          // Theme Mode
          GestureDetector(
            onTapDown: (TapDownDetails details) => _showThemeModeMenu(
                context, userPreferences, details.globalPosition),
            child: ListTile(
              leading: Icon(_getThemeModeIcon(userPreferences.themeMode)),
              title: Text(_getThemeModeText(userPreferences.themeMode)),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),

          // Color Theme
          GestureDetector(
            onTapDown: (TapDownDetails details) => _showColorThemeMenu(
                context, userPreferences, details.globalPosition),
            child: ListTile(
              leading: Icon(
                Icons.palette_outlined,
                color: userPreferences.colorTheme == 'adaptive'
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
      case 'adaptive':
        return 'Adaptive (Device Colors)';
      case 'blue':
        return 'Ocean Blue';
      case 'light_blue':
        return 'Sky Blue';
      case 'indigo':
        return 'Midnight Indigo';
      case 'deep_purple':
        return 'Deep Purple';
      case 'purple':
        return 'Royal Purple';
      case 'pink':
        return 'Rose Pink';
      case 'red':
        return 'Ruby Red';
      case 'deep_orange':
        return 'Sunset Orange';
      case 'orange':
        return 'Vibrant Orange';
      case 'amber':
        return 'Golden Amber';
      case 'yellow':
        return 'Sunny Yellow';
      case 'lime':
        return 'Lime Green';
      case 'light_green':
        return 'Fresh Green';
      case 'green':
        return 'Forest Green';
      case 'teal':
        return 'Emerald Teal';
      case 'cyan':
        return 'Azure Cyan';
      case 'brown':
        return 'Earth Brown';
      case 'blue_grey':
        return 'Steel Blue';
      case 'grey':
        return 'Modern Grey';
      default:
        return 'Adaptive';
    }
  }

  void _showThemeModeMenu(BuildContext context,
      UserPreferencesProvider provider, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        tapPosition,
        tapPosition,
      ),
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

  void _showColorThemeMenu(BuildContext context,
      UserPreferencesProvider provider, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        tapPosition,
        tapPosition,
      ),
      Offset.zero & overlay.size,
    );

    final colorOptions = [
      {
        'value': 'adaptive',
        'label': 'Adaptive (Device Colors)',
        'color': const Color(0xFF6750A4)
      },
      // Blues
      {
        'value': 'blue',
        'label': 'Ocean Blue',
        'color': const Color(0xFF1976D2)
      },
      {
        'value': 'light_blue',
        'label': 'Sky Blue',
        'color': const Color(0xFF0288D1)
      },
      {
        'value': 'cyan',
        'label': 'Azure Cyan',
        'color': const Color(0xFF00838F)
      },
      {
        'value': 'teal',
        'label': 'Emerald Teal',
        'color': const Color(0xFF00695C)
      },
      // Greens
      {
        'value': 'green',
        'label': 'Forest Green',
        'color': const Color(0xFF2E7D32)
      },
      {
        'value': 'light_green',
        'label': 'Fresh Green',
        'color': const Color(0xFF689F38)
      },
      {
        'value': 'lime',
        'label': 'Lime Green',
        'color': const Color(0xFF9E9D24)
      },
      // Yellows/Oranges
      {
        'value': 'yellow',
        'label': 'Sunny Yellow',
        'color': const Color(0xFFF9A825)
      },
      {
        'value': 'amber',
        'label': 'Golden Amber',
        'color': const Color(0xFFFF8F00)
      },
      {
        'value': 'orange',
        'label': 'Vibrant Orange',
        'color': const Color(0xFFF57C00)
      },
      {
        'value': 'deep_orange',
        'label': 'Sunset Orange',
        'color': const Color(0xFFD84315)
      },
      // Reds/Pinks
      {'value': 'red', 'label': 'Ruby Red', 'color': const Color(0xFFC62828)},
      {'value': 'pink', 'label': 'Rose Pink', 'color': const Color(0xFFAD1457)},
      // Purples
      {
        'value': 'purple',
        'label': 'Royal Purple',
        'color': const Color(0xFF6A1B9A)
      },
      {
        'value': 'deep_purple',
        'label': 'Deep Purple',
        'color': const Color(0xFF512DA8)
      },
      {
        'value': 'indigo',
        'label': 'Midnight Indigo',
        'color': const Color(0xFF283593)
      },
      // Neutrals
      {
        'value': 'brown',
        'label': 'Earth Brown',
        'color': const Color(0xFF5D4037)
      },
      {
        'value': 'blue_grey',
        'label': 'Steel Blue',
        'color': const Color(0xFF455A64)
      },
      {
        'value': 'grey',
        'label': 'Modern Grey',
        'color': const Color(0xFF616161)
      },
    ];

    showMenu<String>(
      context: context,
      position: position,
      items: colorOptions.map((option) {
        return PopupMenuItem<String>(
          value: option['value'] as String,
          child: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: option['value'] == 'adaptive'
                    ? Theme.of(context).colorScheme.primary
                    : option['color'] as Color,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(option['label'] as String)),
              if (provider.colorTheme == option['value']) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
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
