import 'package:flutter/material.dart';

/// Header widget for the scoring screen with title and menu actions
class ScoringHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onSettingsPressed;

  const ScoringHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBackPressed,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: const EdgeInsets.all(6),
            ),
          ),
          const SizedBox(width: 6),
          // Title
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: onSettingsPressed,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }
}
