import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customizable_counter/customizable_counter.dart';
import '../providers/settings_provider.dart';
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
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
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
                                      settingsProvider
                                          .setFavoriteTeam(teamName);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              settingsProvider.favoriteTeam.isEmpty
                                  ? 'Select Team'
                                  : settingsProvider.favoriteTeam,
                            ),
                          ),
                          if (settingsProvider.favoriteTeam.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                settingsProvider.setFavoriteTeam('');
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear favorite team',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quarter Minutes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      CustomizableCounter(
                        borderWidth: 2,
                        borderRadius: 36,
                        textSize:
                            Theme.of(context).textTheme.titleLarge?.fontSize ??
                                22,
                        count:
                            settingsProvider.defaultQuarterMinutes.toDouble(),
                        minCount: 1,
                        maxCount: 60,
                        showButtonText: false,
                        onCountChange: (count) {
                          settingsProvider
                              .setDefaultQuarterMinutes(count.toInt());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Countdown Timer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Switch(
                        value: settingsProvider.defaultIsCountdownTimer,
                        onChanged: (bool value) {
                          settingsProvider.setDefaultIsCountdownTimer(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Theme Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme Mode',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DropdownButton<ThemeMode>(
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Color Theme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DropdownButton<String>(
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
                          _buildColorDropdownItem('deep_orange',
                              'Sunset Orange', const Color(0xFFD84315)),
                          _buildColorDropdownItem(
                              'red', 'Ruby Red', const Color(0xFFC62828)),
                          _buildColorDropdownItem(
                              'pink', 'Rose Pink', const Color(0xFFAD1457)),
                          _buildColorDropdownItem('purple', 'Royal Purple',
                              const Color(0xFF6A1B9A)),
                          _buildColorDropdownItem('indigo', 'Midnight Indigo',
                              const Color(0xFF283593)),
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
          ],
        ),
      ),
    );
  }
}
