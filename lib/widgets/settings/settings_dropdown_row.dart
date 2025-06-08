import 'package:flutter/material.dart';

/// A dropdown row widget for settings with consistent styling
class SettingsDropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const SettingsDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
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
        DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: items,
        ),
      ],
    );
  }
}
