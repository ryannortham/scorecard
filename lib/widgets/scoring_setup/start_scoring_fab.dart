// floating action button for starting a scoring session

import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';

/// fab for starting the scoring session
class StartScoringFab extends StatelessWidget {
  const StartScoringFab({
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  final bool isEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 140,
      child: FloatingActionButton.extended(
        backgroundColor:
            isEnabled
                ? context.colors.primary
                : context.colors.onSurface.withValues(alpha: 0.12),
        foregroundColor:
            isEnabled
                ? context.colors.onPrimary
                : context.colors.onSurface.withValues(alpha: 0.38),
        elevation: 0,
        disabledElevation: 0,
        heroTag: 'start_scoring_fab',
        onPressed: onPressed,
        icon: const Icon(Icons.outlined_flag),
        label: const Text('Start Scoring'),
      ),
    );
  }
}
