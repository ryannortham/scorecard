import 'package:flutter/material.dart';

/// A Material 3 compliant bottom sheet for end quarter/game confirmation
class EndQuarterBottomSheet {
  /// Show the end quarter/game confirmation bottom sheet
  static Future<bool> show({
    required BuildContext context,
    required int currentQuarter,
    required bool isLastQuarter,
    required VoidCallback onConfirm,
  }) async {
    final actionText = isLastQuarter ? 'End Game' : 'Next Quarter';
    final icon = isLastQuarter ? Icons.outlined_flag : Icons.arrow_forward;

    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm();
                  },
                  icon: Icon(icon),
                  label: Text(actionText),
                ),
              ],
            ),
          ),
    );

    return result ?? false;
  }
}
