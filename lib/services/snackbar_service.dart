// consistent snackbar display across the app

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';

/// centralised snackbar message service
class SnackBarService {
  static const _errorDuration = Duration(seconds: 3);
  static const _defaultDuration = Duration(seconds: 2);

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: context.colors.error,
      duration: duration ?? _errorDuration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: context.colors.primary,
      duration: duration ?? _defaultDuration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, duration: duration ?? _defaultDuration);
  }

  static void showLoading(BuildContext context, String message) {
    hide(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction, {
    Duration? duration,
    Color? backgroundColor,
  }) {
    hide(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    hide(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}
