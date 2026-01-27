// displays action buttons for a team (favourite, edit, delete)

import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';

/// displays the action buttons for a team (favourite, edit, delete)
class TeamActionButtons extends StatelessWidget {
  const TeamActionButtons({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Favorite Button
            _ActionButton(
              icon:
                  isFavorite ? Icons.star_outlined : Icons.star_border_outlined,
              label: 'Favorite',
              isActive: isFavorite,
              onPressed: onToggleFavorite,
            ),

            // Edit Button
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit Name',
              onPressed: onEdit,
            ),

            // Delete Button
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;

    if (isDestructive) {
      backgroundColor = context.colors.error;
      foregroundColor = context.colors.onError;
    } else if (isActive) {
      backgroundColor = context.colors.primary;
      foregroundColor = context.colors.onPrimary;
    } else {
      backgroundColor = context.colors.surfaceContainerHighest;
      foregroundColor = context.colors.onSurface;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            minimumSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
