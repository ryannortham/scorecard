// wrapper widget for tab root screens to handle back navigation consistently

import 'package:flutter/material.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

/// A wrapper for tab root screens that handles back navigation consistently
/// across iOS and Android platforms.
///
/// This widget ensures that system back gestures (both hardware button and
/// swipe gestures) are properly intercepted and delegated to the
/// [NavigationShell]'s tab history navigation, rather than allowing the
/// gesture to close the app.
///
/// When [isInSelectionMode] is true, back gestures will call
/// [onExitSelectionMode] instead of navigating back through tab history.
class TabRootWrapper extends StatelessWidget {
  const TabRootWrapper({
    required this.child,
    this.isInSelectionMode = false,
    this.onExitSelectionMode,
    super.key,
  });

  /// The child widget to wrap (typically the tab root screen's body).
  final Widget child;

  /// Whether the screen is currently in selection mode.
  /// When true, back gestures exit selection mode instead of navigating.
  final bool isInSelectionMode;

  /// Callback to exit selection mode. Required when [isInSelectionMode] is
  /// true.
  final VoidCallback? onExitSelectionMode;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Always intercept pop to ensure proper tab history navigation.
      // This prevents Android's predictive back gesture from bypassing
      // the NavigationShell's tab history and closing the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Use the unified handleBack() method which handles both
        // selection mode and tab history navigation
        NavigationShellInfo.of(context)?.handleBack(
          isInSelectionMode: isInSelectionMode,
          onExitSelectionMode: onExitSelectionMode,
        );
      },
      child: child,
    );
  }
}
