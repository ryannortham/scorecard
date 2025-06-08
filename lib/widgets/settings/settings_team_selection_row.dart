import 'package:flutter/material.dart';

/// A team selection row widget for settings with consistent styling
class SettingsTeamSelectionRow extends StatelessWidget {
  final String label;
  final String selectedTeam;
  final String buttonText;
  final VoidCallback onSelectTeam;
  final VoidCallback? onClearTeam;

  const SettingsTeamSelectionRow({
    super.key,
    required this.label,
    required this.selectedTeam,
    required this.buttonText,
    required this.onSelectTeam,
    this.onClearTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: onSelectTeam,
              child: Text(
                selectedTeam.isEmpty ? buttonText : selectedTeam,
              ),
            ),
            if (selectedTeam.isNotEmpty && onClearTeam != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClearTeam,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear favorite team',
              ),
            ],
          ],
        ),
      ],
    );
  }
}
