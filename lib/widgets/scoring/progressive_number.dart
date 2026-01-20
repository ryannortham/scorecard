import 'package:flutter/material.dart';

/// Visual decoration state for a progressive number
enum NumberDecoration {
  /// Diagonal strikethrough (forward slash) - for previous numbers
  strikethrough,

  /// Underline - for final number in completed quarter
  underline,

  /// No decoration - for current number in active quarter
  none,
}

/// Renders a single number with optional strikethrough or underline decoration.
/// Used in progressive scoring display mode.
class ProgressiveNumber extends StatelessWidget {
  final int number;
  final NumberDecoration decoration;
  final TextStyle? textStyle;

  const ProgressiveNumber({
    super.key,
    required this.number,
    this.decoration = NumberDecoration.none,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = textStyle ?? theme.textTheme.labelMedium;

    if (decoration == NumberDecoration.underline) {
      return _UnderlinedNumber(number: number, textStyle: effectiveStyle);
    }

    if (decoration == NumberDecoration.strikethrough) {
      return _StrikethroughNumber(number: number, textStyle: effectiveStyle);
    }

    // NumberDecoration.none
    return Text(number.toString(), style: effectiveStyle);
  }
}

/// Internal widget that renders a number with a diagonal strikethrough overlay
class _StrikethroughNumber extends StatelessWidget {
  final int number;
  final TextStyle? textStyle;

  const _StrikethroughNumber({required this.number, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DiagonalStrikethroughPainter(
        color:
            textStyle?.color?.withValues(alpha: 0.55) ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        strokeWidth: 1.5,
      ),
      child: Text(number.toString(), style: textStyle),
    );
  }
}

/// Internal widget that renders a number with an underline below it
class _UnderlinedNumber extends StatelessWidget {
  final int number;
  final TextStyle? textStyle;

  const _UnderlinedNumber({required this.number, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _UnderlinePainter(
        color:
            textStyle?.color?.withValues(alpha: 0.55) ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        strokeWidth: 1.5,
      ),
      child: Text(number.toString(), style: textStyle),
    );
  }
}

/// Custom painter that draws a diagonal line (forward slash direction)
/// with consistent angle regardless of text width
class _DiagonalStrikethroughPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DiagonalStrikethroughPainter({required this.color, this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // use consistent angle, line centered on widget
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // line length based on height with small padding
    final halfLength = (size.height * 0.45);

    // calculate endpoints using fixed angle
    final dx = halfLength * (1 / 1.73); // cos(60°) ≈ 0.577
    final dy = halfLength;

    // draw from bottom-left to top-right (forward slash direction)
    canvas.drawLine(
      Offset(centerX - dx, centerY + dy),
      Offset(centerX + dx, centerY - dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalStrikethroughPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Custom painter that draws an underline with adjustable offset
class _UnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _UnderlinePainter({required this.color, this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // draw underline just below text (1px offset)
    final y = size.height;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
