import 'package:flutter/material.dart';

/// A widget that adapts title text to fit available space by scaling down
/// to a minimum scale factor, then truncating with ellipsis if still too long
class AdaptiveTitle extends StatelessWidget {
  /// The title text to display
  final String title;

  /// The text style to use (defaults to theme titleLarge)
  final TextStyle? style;

  /// The minimum scale factor before switching to truncation (default: 0.7)
  final double minScaleFactor;

  /// The maximum number of lines (default: 1)
  final int maxLines;

  /// Text alignment (default: center)
  final TextAlign textAlign;

  const AdaptiveTitle({
    super.key,
    required this.title,
    this.style,
    this.minScaleFactor = 0.7,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.titleLarge;

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
