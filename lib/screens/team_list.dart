import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/teams_provider.dart';
import '../services/navigation_service.dart';
import 'settings.dart';
import 'game_history.dart';

class TeamList extends StatelessWidget {
  const TeamList(
      {super.key, required this.title, required this.onTeamSelected});
  final String title;
  final void Function(String) onTeamSelected;

  @override
  Widget build(BuildContext context) {
    final teamsProvider = Provider.of<TeamsProvider>(context);
    final teamToExclude = ModalRoute.of(context)?.settings.arguments as String?;
    final teamNames =
        teamsProvider.teams.where((team) => team != teamToExclude).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Menu',
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.sports_rugby,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GoalKeeper',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Menu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Settings(title: 'Settings'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Game History'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: teamsProvider.loaded
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: teamNames.length,
                itemBuilder: (BuildContext context, int index) {
                  final teamName = teamNames[index];
                  final realIndex = teamsProvider.teams.indexOf(teamName);
                  return Card(
                    child: ListTile(
                      title: Text(teamName),
                      onTap: () {
                        onTeamSelected(teamName);
                        Navigator.pop(context, teamName);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _showEditTeamDialog(
                                context, teamsProvider, realIndex, teamName),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => _showDeleteTeamConfirmation(
                                context, teamsProvider, realIndex, teamName),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeamDialog(context),
        tooltip: 'Add Team',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTeamDialog(BuildContext context) async {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Team'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a team name';
                }
                final trimmedValue = value.trim();
                if (teamsProvider.teams.contains(trimmedValue)) {
                  return 'Team name already exists';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final teamName = controller.text.trim();
                  await teamsProvider.addTeam(teamName);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTeamDialog(BuildContext context,
      TeamsProvider teamsProvider, int index, String currentTeamName) async {
    final TextEditingController controller =
        TextEditingController(text: currentTeamName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Team Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a team name';
                }
                final trimmedValue = value.trim();
                // Don't validate against the current team name (allow keeping the same name)
                if (trimmedValue != currentTeamName &&
                    teamsProvider.teams.contains(trimmedValue)) {
                  return 'Team name already exists';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newTeamName = controller.text.trim();
                  if (newTeamName != currentTeamName) {
                    await teamsProvider.editTeam(index, newTeamName);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteTeamConfirmation(BuildContext context,
      TeamsProvider teamsProvider, int index, String teamName) async {
    final confirmed = await AppNavigator.showConfirmationDialog(
      context: context,
      title: 'Delete Team?',
      content: 'Are you sure you want to delete "$teamName"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed) {
      await teamsProvider.deleteTeam(index);
      // Stay on the team list after deletion - don't navigate back
    }
  }
}
