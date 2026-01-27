// score worm custom painters

import 'package:flutter/material.dart';

import 'package:scorecard/models/score_worm.dart';

/// grid painter for chart background
class GridPainter extends CustomPainter {
  GridPainter({required this.gridColour, required this.zeroLineColour});
  final Color gridColour;
  final Color zeroLineColour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = gridColour
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final zeroLinePaint =
        Paint()
          ..color = zeroLineColour
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    // horizontal lines at 25%, 50%, 75%
    final quarterHeight = size.height / 4;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint)
      ..drawLine(
        Offset(0, quarterHeight),
        Offset(size.width, quarterHeight),
        paint,
      )
      // zero line (heavier)
      ..drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        zeroLinePaint,
      )
      ..drawLine(
        Offset(0, quarterHeight * 3),
        Offset(size.width, quarterHeight * 3),
        paint,
      );

    // vertical lines for quarter columns
    final colWidth = size.width / 4;
    for (var i = 1; i < 4; i++) {
      final x = i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridColour != gridColour ||
        oldDelegate.zeroLineColour != zeroLineColour;
  }
}

/// worm line painter with zero-crossing colour changes
class WormLinePainter extends CustomPainter {
  WormLinePainter({
    required this.points,
    required this.yAxisMax,
    required this.colours,
  });
  final List<ScoreWormPoint> points;
  final int yAxisMax;
  final ScoreWormColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint =
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    Offset toScreen(double x, int differential) {
      final screenX = (x / 4.0) * size.width;
      final screenY =
          size.height / 2 - (differential / yAxisMax) * (size.height / 2);
      return Offset(screenX, screenY);
    }

    Color getColour(int differential) {
      if (differential > 0) return colours.homeLeadingColour;
      if (differential < 0) return colours.awayLeadingColour;
      return colours.neutralColour;
    }

    // draw line segments, splitting at zero crossings
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final crossesZero =
          (p1.differential > 0 && p2.differential < 0) ||
          (p1.differential < 0 && p2.differential > 0);

      if (crossesZero && p1.differential != 0 && p2.differential != 0) {
        // interpolate to find zero crossing point
        final t =
            p1.differential.abs() /
            (p1.differential.abs() + p2.differential.abs());
        final zeroX = p1.x + t * (p2.x - p1.x);

        // first half in p1's colour
        paint.color = getColour(p1.differential);
        canvas.drawLine(
          toScreen(p1.x, p1.differential),
          toScreen(zeroX, 0),
          paint,
        );

        // second half in p2's colour
        paint.color = getColour(p2.differential);
        canvas.drawLine(
          toScreen(zeroX, 0),
          toScreen(p2.x, p2.differential),
          paint,
        );
      } else {
        // no crossing - use the non-zero differential's colour
        final colourDiff =
            p1.differential != 0 ? p1.differential : p2.differential;
        paint.color = getColour(colourDiff);
        canvas.drawLine(
          toScreen(p1.x, p1.differential),
          toScreen(p2.x, p2.differential),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WormLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.yAxisMax != yAxisMax ||
        oldDelegate.colours != colours;
  }
}
