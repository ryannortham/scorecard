import 'package:flutter/material.dart';

/// A reusable app bar with consistent styling and settings navigation
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSettings;
  final VoidCallback? onSettingsPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSettings = true,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarActions = [
      if (actions != null) ...actions!,
      if (showSettings)
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onSettingsPressed ??
              () => Navigator.of(context).pushNamed('/settings'),
        ),
    ];

    return AppBar(
      title: Text(title),
      actions: appBarActions.isNotEmpty ? appBarActions : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
