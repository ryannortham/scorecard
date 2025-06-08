import 'package:flutter/material.dart';
import 'package:customizable_counter/customizable_counter.dart';

/// A counter row widget for settings with consistent styling
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        CustomizableCounter(
          borderWidth: 2,
          borderRadius: 36,
          textSize: Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
          count: value,
          minCount: minCount,
          maxCount: maxCount,
          showButtonText: false,
          onCountChange: onCountChange,
        ),
      ],
    );
  }
}
