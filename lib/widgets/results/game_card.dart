// simple card wrapper for consistent styling in results display

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/common/adaptive_title.dart';

/// card wrapper for consistent styling in results display
class GameCard extends StatelessWidget {
  const GameCard({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: AdaptiveTitle(
                    title: title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.left,
                    minScaleFactor: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}
