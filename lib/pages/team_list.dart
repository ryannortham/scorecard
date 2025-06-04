import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/teams_provider.dart';
import 'settings.dart';

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Settings(title: 'Settings'),
              ),
            ),
          ),
        ],
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
                            icon: Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () {
                              _showEditTeamDialog(
                                  context, teamsProvider, realIndex);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            tooltip: 'Delete',
                            onPressed: () async {
                              final deletedTeam = teamNames[index];
                              await teamsProvider.deleteTeam(realIndex);
                              if (context.mounted) {
                                Navigator.pop(context, deletedTeam);
                              }
                            },
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
        onPressed: () => _showAddTeamDialog(context, teamsProvider),
        tooltip: 'Add Team',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, TeamsProvider teamsProvider) {
    String newTeam = '';
    String? errorText;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Team'),
              content: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Team name',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  setState(() {
                    newTeam = value;
                    errorText = null;
                  });
                },
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  if (teamsProvider.teams.contains(value.trim())) {
                    setState(() {
                      errorText = 'Team name already exists';
                    });
                    return;
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  await teamsProvider.addTeam(value.trim());
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (newTeam.trim().isEmpty) return;
                    if (teamsProvider.teams.contains(newTeam.trim())) {
                      setState(() {
                        errorText = 'Team name already exists';
                      });
                      return;
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    await teamsProvider.addTeam(newTeam.trim());
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTeamDialog(
      BuildContext context, TeamsProvider teamsProvider, int index) {
    String editedTeam = teamsProvider.teams[index];
    String? errorText;
    final controller = TextEditingController(text: editedTeam);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Team'),
              content: TextField(
                autofocus: true,
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Team name',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  setState(() {
                    editedTeam = value;
                    errorText = null;
                  });
                },
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  if (teamsProvider.teams.contains(value.trim()) &&
                      value.trim() != teamsProvider.teams[index]) {
                    setState(() {
                      errorText = 'Team name already exists';
                    });
                    return;
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  await teamsProvider.editTeam(index, value.trim());
                  if (context.mounted) {
                    Navigator.pop(context, value.trim());
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (editedTeam.trim().isEmpty) return;
                    if (teamsProvider.teams.contains(editedTeam.trim()) &&
                        editedTeam.trim() != teamsProvider.teams[index]) {
                      setState(() {
                        errorText = 'Team name already exists';
                      });
                      return;
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    await teamsProvider.editTeam(index, editedTeam.trim());
                    if (context.mounted) {
                      Navigator.pop(context, editedTeam.trim());
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
