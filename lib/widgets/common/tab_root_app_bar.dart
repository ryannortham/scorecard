// app bar for tab root screens with automatic back button based on tab history

import 'package:flutter/material.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/navigation/navigation_shell.dart';

/// A sliver app bar for tab root screens that automatically shows/hides
/// a back button based on the tab navigation history.
///
/// When the user has navigated between tabs, a back button appears that
/// allows navigation back through the tab history. When at the root of
/// the navigation (no previous tabs), no back button is shown.
///
/// This widget encapsulates the common pattern used across tab root screens
/// and reduces code duplication.
class TabRootAppBar extends StatelessWidget {
  const TabRootAppBar({
    required this.title,
    this.actions,
    super.key,
  });

  /// The title widget displayed in the app bar.
  final Widget title;

  /// Optional action widgets displayed on the right side of the app bar.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final navState = NavigationShellInfo.of(context);
    final canPop = navState?.canPopTab ?? false;

    return StyledSliverAppBar(
      automaticallyImplyLeading: false,
      leading:
          canPop
              ? IconButton(
                icon: Icon(Icons.adaptive.arrow_back_outlined),
                onPressed: () => navState?.popTab(),
                tooltip: 'Back',
              )
              : null,
      title: title,
      actions: actions,
    );
  }
}
