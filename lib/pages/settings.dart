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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
