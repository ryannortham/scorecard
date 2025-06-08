import 'package:flutter/material.dart';

/// A counter row widget for settings with consistent styling using Material 3 Slider
class SettingsCounterRow extends StatelessWidget {
  final String label;
  final double value;
  final double minCount;
  final double maxCount;
  final void Function(double) onCountChange;

  const SettingsCounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.minCount,
    required this.maxCount,
    required this.onCountChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${value.round()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: minCount,
          max: maxCount,
          divisions: (maxCount - minCount).round(),
          label: '${value.round()}',
          onChanged: onCountChange,
        ),
      ],
    );
  }
}
