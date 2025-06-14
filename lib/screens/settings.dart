import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/providers/user_preferences_provider.dart';
import 'team_list.dart';

class Settings extends StatefulWidget {
  const Settings({super.key, required this.title});
  final String title;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  DropdownMenuItem<String> _buildColorDropdownItem(
      String value, String label, Color color) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: value == 'adaptive' ? null : color,
              gradient: value == 'adaptive'
                  ? const LinearGradient(
                      colors: [Colors.blue, Colors.green, Colors.purple],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : null,
              shape: BoxShape.circle,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }

  Color _getAdaptiveColor() {
    // Return a gradient-like color for adaptive to indicate it uses device colors
    return const Color(0xFF6750A4); // Material Purple as fallback
  }

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<UserPreferencesProvider>(context);

    if (!userPreferences.loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Settings Section
            _buildSection(
              context: context,
              children: [
                _buildTeamSelectionTile(context, userPreferences),
              ],
            ),

            const SizedBox(height: 32),

            // Theme Settings Section
            _buildSection(
              context: context,
              title: 'Theme Options',
              children: [
                _buildThemeModeTile(context, userPreferences),
                const SizedBox(height: 24),
                _buildColorThemeTile(context, userPreferences),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    String? title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
        ],
        ...children,
      ],
    );
  }

  Widget _buildTeamSelectionTile(
      BuildContext context, UserPreferencesProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Favorite Team',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamList(
                      title: 'Select Favorite Team',
                      onTeamSelected: (teamName) {
                        provider.setFavoriteTeam(teamName);
                      },
                    ),
                  ),
                );
              },
              child: Text(
                provider.favoriteTeam.isEmpty
                    ? 'Select Team'
                    : provider.favoriteTeam,
              ),
            ),
            if (provider.favoriteTeam.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => provider.setFavoriteTeam(''),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear favorite team',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildThemeModeTile(
      BuildContext context, UserPreferencesProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<ThemeMode>(
          value: provider.themeMode,
          onChanged: (ThemeMode? newValue) {
            if (newValue != null) {
              provider.setThemeMode(newValue);
            }
          },
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorThemeTile(
      BuildContext context, UserPreferencesProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Color Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          value: provider.colorTheme,
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setColorTheme(newValue);
            }
          },
          items: [
            _buildColorDropdownItem(
                'adaptive', 'Adaptive (Device Colors)', _getAdaptiveColor()),
            _buildColorDropdownItem('blue', 'Blue', const Color(0xFF1976D2)),
            _buildColorDropdownItem('green', 'Green', const Color(0xFF2E7D32)),
            _buildColorDropdownItem('teal', 'Teal', const Color(0xFF00695C)),
            _buildColorDropdownItem(
                'purple', 'Purple', const Color(0xFF6A1B9A)),
            _buildColorDropdownItem(
                'indigo', 'Indigo', const Color(0xFF283593)),
            _buildColorDropdownItem('red', 'Red', const Color(0xFFC62828)),
            _buildColorDropdownItem('pink', 'Pink', const Color(0xFFAD1457)),
            _buildColorDropdownItem(
                'deep_orange', 'Deep Orange', const Color(0xFFD84315)),
            _buildColorDropdownItem('amber', 'Amber', const Color(0xFFF57C00)),
            _buildColorDropdownItem('cyan', 'Cyan', const Color(0xFF00838F)),
            _buildColorDropdownItem('brown', 'Brown', const Color(0xFF5D4037)),
          ],
        ),
      ],
    );
  }
}
