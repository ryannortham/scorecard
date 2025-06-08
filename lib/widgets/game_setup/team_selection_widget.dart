import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../adapters/game_setup_adapter.dart';
import '../../providers/teams_provider.dart';
import '../../screens/team_list.dart';

/// Widget for selecting home and away teams with swap functionality
class TeamSelectionWidget extends StatefulWidget {
  final GlobalKey<FormState> homeTeamKey;
  final GlobalKey<FormState> awayTeamKey;
  final TextEditingController homeTeamController;
  final TextEditingController awayTeamController;
  final String? homeTeam;
  final String? awayTeam;
  final ValueChanged<String?> onHomeTeamChanged;
  final ValueChanged<String?> onAwayTeamChanged;

  const TeamSelectionWidget({
    super.key,
    required this.homeTeamKey,
    required this.awayTeamKey,
    required this.homeTeamController,
    required this.awayTeamController,
    required this.homeTeam,
    required this.awayTeam,
    required this.onHomeTeamChanged,
    required this.onAwayTeamChanged,
  });

  @override
  State<TeamSelectionWidget> createState() => _TeamSelectionWidgetState();
}

class _TeamSelectionWidgetState extends State<TeamSelectionWidget> {
  Future<String?> _selectTeam({
    required String title,
    required String teamType,
    required String? excludeTeam,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => TeamList(
          title: title,
          onTeamSelected: (teamName) {
            final gameSetupAdapter =
                Provider.of<GameSetupAdapter>(context, listen: false);
            if (teamType == 'home') {
              gameSetupAdapter.setHomeTeam(teamName);
              widget.homeTeamController.text = teamName;
            } else {
              gameSetupAdapter.setAwayTeam(teamName);
              widget.awayTeamController.text = teamName;
            }
          },
        ),
        settings: RouteSettings(arguments: excludeTeam),
      ),
    );

    if (result != null && mounted) {
      final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
      final gameSetupAdapter =
          Provider.of<GameSetupAdapter>(context, listen: false);

      // Handle team deletion or reselection
      if (teamType == 'home') {
        if (result == widget.homeTeam) {
          if (!teamsProvider.teams.contains(result)) {
            widget.onHomeTeamChanged(null);
            widget.homeTeamController.text = '';
            gameSetupAdapter.setHomeTeam('');
          } else {
            widget.onHomeTeamChanged(result);
            widget.homeTeamController.text = result;
            gameSetupAdapter.setHomeTeam(result);
          }
        } else {
          widget.onHomeTeamChanged(result);
          widget.homeTeamController.text = result;
          gameSetupAdapter.setHomeTeam(result);
        }
        widget.homeTeamKey.currentState?.validate();
      } else {
        if (result == widget.awayTeam) {
          if (!teamsProvider.teams.contains(result)) {
            widget.onAwayTeamChanged(null);
            widget.awayTeamController.text = '';
            gameSetupAdapter.setAwayTeam('');
          } else {
            widget.onAwayTeamChanged(result);
            widget.awayTeamController.text = result;
            gameSetupAdapter.setAwayTeam(result);
          }
        } else {
          widget.onAwayTeamChanged(result);
          widget.awayTeamController.text = result;
          gameSetupAdapter.setAwayTeam(result);
        }
        widget.awayTeamKey.currentState?.validate();
      }
    }
    return null;
  }

  void _swapTeams() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);

    final tempTeam = widget.homeTeam;
    widget.onHomeTeamChanged(widget.awayTeam);
    widget.onAwayTeamChanged(tempTeam);

    widget.homeTeamController.text = widget.awayTeam ?? '';
    widget.awayTeamController.text = tempTeam ?? '';

    gameSetupAdapter.setHomeTeam(widget.awayTeam ?? '');
    gameSetupAdapter.setAwayTeam(tempTeam ?? '');

    widget.homeTeamKey.currentState?.validate();
    widget.awayTeamKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: widget.homeTeamKey,
                child: TextFormField(
                  readOnly: true,
                  controller: widget.homeTeamController,
                  decoration: const InputDecoration(
                    labelText: 'Home Team',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select Home Team';
                    }
                    return null;
                  },
                  onTap: () => _selectTeam(
                    title: 'Select Home Team',
                    teamType: 'home',
                    excludeTeam: widget.awayTeam,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: widget.awayTeamKey,
                child: TextFormField(
                  readOnly: true,
                  controller: widget.awayTeamController,
                  decoration: const InputDecoration(
                    labelText: 'Away Team',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select Away Team';
                    }
                    return null;
                  },
                  onTap: () => _selectTeam(
                    title: 'Select Away Team',
                    teamType: 'away',
                    excludeTeam: widget.homeTeam,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_vert),
              label: const Text('Swap'),
              onPressed: (widget.homeTeam != null || widget.awayTeam != null)
                  ? _swapTeams
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
