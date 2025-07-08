import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/screens/game_history.dart';
import 'package:scorecard/screens/team_list.dart';
import 'package:scorecard/services/color_service.dart';
import '../football_icon.dart';

/// A Material 3 navigation drawer for the app.
///
/// Provides navigation to key screens and settings controls.
/// Adapts its content based on the current route to prevent
/// navigation conflicts and circular routes.
class AppDrawer extends StatelessWidget {
  /// The identifier for the current route/screen.
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, userPreferences, _) {
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // App header using Material 3 DrawerHeader
              _buildDrawerHeader(context),

              // Navigation section
              ..._buildNavigationItems(context, userPreferences),

              // Divider before settings
              const Divider(),

              // Settings section
              ..._buildSettingsItems(context, userPreferences),
            ],
          ),
        );
      },
    );
  }

  /// Builds the drawer header with app branding.
  Widget _buildDrawerHeader(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Footy Score Card',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          _buildAppIcon(context),
        ],
      ),
    );
  }

  /// Builds the app icon with proper theming.
  Widget _buildAppIcon(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 56,
      height: 56,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onPrimary,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          'assets/icon/app_icon_masked.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return FootballIcon(size: 56, color: theme.colorScheme.onPrimary);
          },
        ),
      ),
    );
  }

  /// Builds navigation items for the drawer.
  List<Widget> _buildNavigationItems(
    BuildContext context,
    UserPreferencesProvider userPreferences,
  ) {
    final List<Widget> items = [];

    // Favorite Team - hide on team-related screens
    if (!_isTeamRelatedRoute()) {
      items.add(
        ListTile(
          leading: Icon(
            userPreferences.favoriteTeam.isNotEmpty
                ? Icons.star
                : Icons.star_outline,
          ),
          title: const Text('Favorite Team'),
          subtitle:
              userPreferences.favoriteTeam.isNotEmpty
                  ? Text(userPreferences.favoriteTeam)
                  : const Text('None selected'),
          trailing:
              userPreferences.favoriteTeam.isNotEmpty
                  ? IconButton(
                    onPressed: () => userPreferences.setFavoriteTeam(''),
                    icon: const Icon(Icons.clear_outlined),
                    tooltip: 'Clear favorite team',
                  )
                  : null,
          onTap: () => _navigateToTeamSelection(context, userPreferences),
        ),
      );
    }

    // Manage Teams - hide on team-related screens
    if (!_isTeamRelatedRoute()) {
      items.add(
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: const Text('Manage Teams'),
          onTap: () => _navigateToTeamManagement(context),
        ),
      );
    }

    // Game Results - hide on team-related screens
    if (!_isTeamRelatedRoute() && currentRoute != 'game_history') {
      items.add(
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Game Results'),
          onTap: () => _navigateToGameHistory(context),
        ),
      );
    }

    return items;
  }

  /// Builds settings items for the drawer.
  List<Widget> _buildSettingsItems(
    BuildContext context,
    UserPreferencesProvider userPreferences,
  ) {
    return [
      // Tally Marks Toggle
      SwitchListTile.adaptive(
        secondary: ColorFiltered(
          colorFilter: ColorFilter.mode(
            context.colors.onSurfaceVariant,
            BlendMode.srcIn,
          ),
          child: Image.asset('assets/tally/tally5.ico', width: 24, height: 24),
        ),
        title: const Text('Tally Marks'),
        value: userPreferences.useTallys,
        onChanged: userPreferences.setUseTallys,
      ),

      // Countdown Timer Toggle - hide on scoring screen
      if (currentRoute != 'scoring')
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.timer_outlined),
          title: const Text('Countdown Timer'),
          value: userPreferences.isCountdownTimer,
          onChanged: userPreferences.setIsCountdownTimer,
        ),

      // Theme Mode Selector
      GestureDetector(
        onTapDown:
            (details) => _showThemeModeMenu(
              context,
              userPreferences,
              details.globalPosition,
            ),
        child: ListTile(
          leading: Icon(_getThemeModeIcon(userPreferences.themeMode)),
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeName(userPreferences.themeMode)),
          trailing: const Icon(Icons.arrow_drop_down),
        ),
      ),

      // Color Theme Selector
      GestureDetector(
        onTapDown:
            (details) => _showColorThemeMenu(
              context,
              userPreferences,
              details.globalPosition,
            ),
        child: ListTile(
          leading: Icon(
            Icons.palette_outlined,
            color:
                userPreferences.colorTheme == 'dynamic'
                    ? context.colors.primary
                    : userPreferences.getThemeColor(),
          ),
          title: const Text('Colour'),
          subtitle: Text(_getColorThemeName(userPreferences.colorTheme)),
          trailing: const Icon(Icons.arrow_drop_down),
        ),
      ),
    ];
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
                Icon(Icons.check, color: context.colors.primary),
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
                Icon(Icons.check, color: context.colors.primary),
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
                Icon(Icons.check, color: context.colors.primary),
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

    final colorOptions = ColorService.getColorOptions(
      supportsDynamicColors: provider.supportsDynamicColors,
    );

    showMenu<String>(
      context: context,
      position: position,
      items:
          colorOptions.map((option) {
            return PopupMenuItem<String>(
              value: option['value'] as String,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: option['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(option['label'] as String),
                  if (provider.colorTheme == option['value']) ...[
                    const Spacer(),
                    Icon(Icons.check, color: context.colors.primary),
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

  /// Helper methods
  bool _isTeamRelatedRoute() {
    return currentRoute == 'add_team' || currentRoute == 'team_list';
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

  /// Navigation methods
  Future<void> _navigateToTeamSelection(
    BuildContext context,
    UserPreferencesProvider userPreferences,
  ) async {
    Navigator.pop(context);
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeamList(
              title: 'Select Favorite Team',
              onTeamSelected: userPreferences.setFavoriteTeam,
            ),
      ),
    );
  }

  void _navigateToTeamManagement(BuildContext context) {
    Navigator.pop(context);
    if (currentRoute == 'add_team') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => TeamList(
                title: 'Manage Teams',
                onTeamSelected: (_) {}, // No action needed
              ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => TeamList(
                title: 'Manage Teams',
                onTeamSelected: (_) {}, // No action needed
              ),
        ),
      );
    }
  }

  void _navigateToGameHistory(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GameHistoryScreen()));
  }
}
