// standardised sliver app bar with consistent styling

import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';

/// sliver app bar with consistent styling across the app
class StyledSliverAppBar extends StatelessWidget {
  const StyledSliverAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  /// creates app bar with a standard back button
  factory StyledSliverAppBar.withBackButton({
    required Widget title,
    required VoidCallback onBackPressed,
    Key? key,
    List<Widget>? actions,
  }) {
    return StyledSliverAppBar(
      key: key,
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined),
        tooltip: 'Back',
        onPressed: onBackPressed,
      ),
      actions: actions,
    );
  }

  /// creates app bar for selection mode with close button
  factory StyledSliverAppBar.selectionMode({
    required int selectedCount,
    required VoidCallback onClose,
    required VoidCallback? onDelete,
    Key? key,
  }) {
    return StyledSliverAppBar(
      key: key,
      title: Text('$selectedCount selected'),
      leading: IconButton(
        icon: const Icon(Icons.close_outlined),
        onPressed: onClose,
      ),
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      ],
    );
  }

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: ColorService.transparent,
      foregroundColor: context.colors.onPrimaryContainer,
      floating: true,
      snap: true,
      elevation: 0,
      shadowColor: ColorService.transparent,
      surfaceTintColor: ColorService.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      leading: leading,
      actions: actions,
    );
  }
}
