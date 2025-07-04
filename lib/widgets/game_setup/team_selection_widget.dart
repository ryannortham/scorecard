import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/screens/team_list.dart';

/// Widget for selecting home and away teams with drag-and-drop reordering
class TeamSelectionWidget extends StatefulWidget {
  final String? homeTeam;
  final String? awayTeam;
  final ValueChanged<String?> onHomeTeamChanged;
  final ValueChanged<String?> onAwayTeamChanged;

  const TeamSelectionWidget({
    super.key,
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
    required String? excludeTeam,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeamList(
              title: title,
              onTeamSelected: (teamName) {
                // The TeamList will handle the navigation back via Navigator.pop(context, team.name)
                // We don't need to do anything here except maybe log
              },
            ),
        settings: RouteSettings(arguments: excludeTeam),
      ),
    );
    return result;
  }

  Widget _buildTeamCard({
    required String label,
    required String? teamName,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required bool isHomeTeam,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teamsProvider = Provider.of<TeamsProvider>(context);

    final team =
        teamName != null
            ? teamsProvider.teams.cast<dynamic>().firstWhere(
              (t) => t.name == teamName,
              orElse: () => null,
            )
            : null;

    final bool canDrag = widget.homeTeam != null || widget.awayTeam != null;

    Widget cardContent = Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child:
            teamName == null
                ? _buildEmptyState(label, colorScheme)
                : _buildSelectedState(
                  team,
                  teamName,
                  onClear,
                  canDrag,
                  colorScheme,
                ),
      ),
    );

    if (teamName != null && canDrag) {
      return DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          // Always accept drops - we'll handle swapping
          return true;
        },
        onAcceptWithDetails: (details) {
          // Handle the drop - swap the teams
          final droppedTeam = details.data;

          if (isHomeTeam) {
            // Dropping on home team slot
            if (widget.awayTeam == droppedTeam) {
              // Swapping away team to home
              widget.onHomeTeamChanged(droppedTeam);
              widget.onAwayTeamChanged(
                teamName,
              ); // Put current home team in away slot
            } else {
              // Just setting home team (from external drag or empty slot)
              widget.onHomeTeamChanged(droppedTeam);
            }
          } else {
            // Dropping on away team slot
            if (widget.homeTeam == droppedTeam) {
              // Swapping home team to away
              widget.onAwayTeamChanged(droppedTeam);
              widget.onHomeTeamChanged(
                teamName,
              ); // Put current away team in home slot
            } else {
              // Just setting away team (from external drag or empty slot)
              widget.onAwayTeamChanged(droppedTeam);
            }
          }
        },
        builder: (context, candidateData, rejectedData) {
          return LongPressDraggable<String>(
            data: teamName,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSelectedState(
                  team,
                  teamName,
                  null,
                  true,
                  colorScheme,
                ),
              ),
            ),
            childWhenDragging: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
              child: Container(height: 72),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration:
                  candidateData.isNotEmpty
                      ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                      : null,
              child: cardContent,
            ),
          );
        },
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        // Always accept drops - we'll handle swapping
        return true;
      },
      onAcceptWithDetails: (details) {
        // Handle the drop - swap the teams
        final droppedTeam = details.data;

        if (isHomeTeam) {
          // Dropping on home team slot
          if (widget.awayTeam == droppedTeam) {
            // Swapping away team to home
            widget.onHomeTeamChanged(droppedTeam);
            widget.onAwayTeamChanged(
              teamName,
            ); // Put current home team in away slot
          } else {
            // Just setting home team (from external drag or empty slot)
            widget.onHomeTeamChanged(droppedTeam);
          }
        } else {
          // Dropping on away team slot
          if (widget.homeTeam == droppedTeam) {
            // Swapping home team to away
            widget.onAwayTeamChanged(droppedTeam);
            widget.onHomeTeamChanged(
              teamName,
            ); // Put current away team in home slot
          } else {
            // Just setting away team (from external drag or empty slot)
            widget.onAwayTeamChanged(droppedTeam);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration:
              candidateData.isNotEmpty
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary, width: 2),
                  )
                  : null,
          child: cardContent,
        );
      },
    );
  }

  Widget _buildEmptyState(String label, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, size: 24, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildSelectedState(
    dynamic team,
    String teamName,
    VoidCallback? onClear,
    bool showDragHandle,
    ColorScheme colorScheme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: _buildTeamLogo(team),
      title: Text(
        teamName,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show drag handle when both teams are selected
          if (widget.homeTeam != null && widget.awayTeam != null)
            Icon(
              Icons.drag_handle,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamLogo(dynamic team) {
    if (team?.logoUrl != null && team.logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          team.logoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildDefaultLogo();
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sports_football,
        size: 28,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Home Team Card
        _buildTeamCard(
          label: 'Home Team',
          teamName: widget.homeTeam,
          onTap: () async {
            final selectedTeam = await _selectTeam(
              title: 'Select Home Team',
              excludeTeam: widget.awayTeam,
            );
            if (selectedTeam != null) {
              widget.onHomeTeamChanged(selectedTeam);
            }
          },
          onClear:
              widget.homeTeam != null
                  ? () => widget.onHomeTeamChanged(null)
                  : null,
          isHomeTeam: true,
        ),

        const SizedBox(height: 8),

        // Away Team Card
        _buildTeamCard(
          label: 'Away Team',
          teamName: widget.awayTeam,
          onTap: () async {
            final selectedTeam = await _selectTeam(
              title: 'Select Away Team',
              excludeTeam: widget.homeTeam,
            );
            if (selectedTeam != null) {
              widget.onAwayTeamChanged(selectedTeam);
            }
          },
          onClear:
              widget.awayTeam != null
                  ? () => widget.onAwayTeamChanged(null)
                  : null,
          isHomeTeam: false,
        ),
      ],
    );
  }
}
