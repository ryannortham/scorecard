import 'package:flutter/material.dart';

/// A switch row widget for settings with consistent styling
class SettingsSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
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
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
