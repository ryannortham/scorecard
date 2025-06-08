import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_dropdown_row.dart';
import '../widgets/settings/settings_switch_row.dart';
import '../widgets/settings/settings_counter_row.dart';
import '../widgets/settings/settings_team_selection_row.dart';
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
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (!settingsProvider.loaded) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Settings'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Game Settings Section
            SettingsSection(
              children: [
                SettingsTeamSelectionRow(
                  label: 'Favorite Team',
                  selectedTeam: settingsProvider.favoriteTeam,
                  buttonText: 'Select Team',
                  onSelectTeam: () async {
                    await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamList(
                          title: 'Select Favorite Team',
                          onTeamSelected: (teamName) {
                            settingsProvider.setFavoriteTeam(teamName);
                          },
                        ),
                      ),
                    );
                  },
                  onClearTeam: settingsProvider.favoriteTeam.isNotEmpty
                      ? () => settingsProvider.setFavoriteTeam('')
                      : null,
                ),
                SettingsCounterRow(
                  label: 'Quarter Minutes',
                  value: settingsProvider.defaultQuarterMinutes.toDouble(),
                  minCount: 1,
                  maxCount: 60,
                  onCountChange: (count) {
                    settingsProvider.setDefaultQuarterMinutes(count.toInt());
                  },
                ),
                SettingsSwitchRow(
                  label: 'Countdown Timer',
                  value: settingsProvider.defaultIsCountdownTimer,
                  onChanged: (value) {
                    settingsProvider.setDefaultIsCountdownTimer(value);
                  },
                ),
              ],
            ),

            // Theme Settings Section
            SettingsSection(
              title: 'Theme Options',
              children: [
                SettingsDropdownRow<ThemeMode>(
                  label: 'Theme Mode',
                  value: settingsProvider.themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      settingsProvider.setThemeMode(newValue);
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
                SettingsDropdownRow<String>(
                  label: 'Color Theme',
                  value: settingsProvider.colorTheme,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settingsProvider.setColorTheme(newValue);
                    }
                  },
                  items: [
                    _buildColorDropdownItem('adaptive',
                        'Adaptive (Device Colors)', _getAdaptiveColor()),
                    _buildColorDropdownItem(
                        'blue', 'Ocean Blue', const Color(0xFF1976D2)),
                    _buildColorDropdownItem(
                        'teal', 'Emerald Teal', const Color(0xFF00695C)),
                    _buildColorDropdownItem(
                        'green', 'Forest Green', const Color(0xFF2E7D32)),
                    _buildColorDropdownItem(
                        'amber', 'Golden Amber', const Color(0xFFF57C00)),
                    _buildColorDropdownItem('deep_orange', 'Sunset Orange',
                        const Color(0xFFD84315)),
                    _buildColorDropdownItem(
                        'red', 'Ruby Red', const Color(0xFFC62828)),
                    _buildColorDropdownItem(
                        'pink', 'Rose Pink', const Color(0xFFAD1457)),
                    _buildColorDropdownItem(
                        'purple', 'Royal Purple', const Color(0xFF6A1B9A)),
                    _buildColorDropdownItem(
                        'indigo', 'Midnight Indigo', const Color(0xFF283593)),
                    _buildColorDropdownItem(
                        'cyan', 'Azure Cyan', const Color(0xFF00838F)),
                    _buildColorDropdownItem(
                        'brown', 'Earth Brown', const Color(0xFF5D4037)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
