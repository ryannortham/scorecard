import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/screens/team_list.dart';
import '../football_icon.dart';

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
                // This callback gets called when a team is selected
                // We don't need to do anything here since Navigator.pop will handle the return
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
        teamName != null && teamsProvider.loaded
            ? teamsProvider.teams.cast<dynamic>().firstWhere(
              (t) => t.name == teamName,
              orElse: () => null,
            )
            : null;

    final bool canDrag = widget.homeTeam != null || widget.awayTeam != null;

    Widget cardContent = Card(
      elevation: 0,
      color:
          teamName == null
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerHigh,
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
              child: SizedBox(
                width:
                    MediaQuery.of(context).size.width -
                    40, // Reduce by 44px to match original card width
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHigh,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSelectedState(
                      team,
                      teamName,
                      onClear, // Keep the actual onClear function
                      true,
                      colorScheme,
                    ),
                  ),
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
        horizontal: 8.0,
        vertical: 8.0,
      ),
      horizontalTitleGap: 8.0, // Consistent gap with selected state
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add spacing to align with drag handle + logo when present
          const SizedBox(width: 28), // 20px (drag handle) + 8px (spacing)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
      contentPadding: EdgeInsets.only(
        left: 8.0,
        right:
            onClear != null
                ? 4.0
                : 8.0, // 4px from right edge when X icon is present
        top: 8.0,
        bottom: 8.0,
      ),
      horizontalTitleGap: 8.0, // Reduce gap between leading and title
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show drag handle when this team is selected (so it can be dragged)
          if (showDragHandle) ...[
            Icon(
              Icons.drag_handle,
              color: colorScheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          _buildTeamLogo(team),
        ],
      ),
      title: Text(
        teamName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      trailing:
          onClear != null
              ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              )
              : null,
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
      child: FootballIcon(
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

        const SizedBox(height: 4),

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
