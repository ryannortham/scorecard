import 'package:flutter/material.dart';

/// A settings section with optional title and spacing
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16.0),
    this.spacing = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: spacing / 2),
          ],
          ...children
              .map((child) => [
                    child,
                    if (child != children.last) SizedBox(height: spacing),
                  ])
              .expand((widgets) => widgets),
        ],
      ),
    );
  }
}
