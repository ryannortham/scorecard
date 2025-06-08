import 'package:flutter/material.dart';

/// A reusable info card widget for displaying game details
class GameInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget content;
  final Color? iconColor;

  const GameInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}
