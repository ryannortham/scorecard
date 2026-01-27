// adaptive title widget that scales to fit available space

import 'package:flutter/material.dart';

/// adapts title text by scaling down then truncating if too long
class AdaptiveTitle extends StatelessWidget {
  const AdaptiveTitle({
    required this.title,
    super.key,
    this.style,
    this.minScaleFactor = 0.7,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final TextStyle? style;
  final double minScaleFactor;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.headlineSmall;

    // Simple and safe approach: just use FittedBox with scaleDown
    // This avoids the LayoutBuilder infinite loop issue
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment:
          textAlign == TextAlign.center
              ? Alignment.center
              : textAlign == TextAlign.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
      child: Text(
        title,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
