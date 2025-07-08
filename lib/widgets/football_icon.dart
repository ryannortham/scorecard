import 'package:flutter/material.dart';
import 'package:scorecard/services/color_service.dart';

/// A widget that displays a football icon using a PNG asset
/// The icon adapts to the app theme through color filtering
class FootballIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const FootballIcon({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? context.colors.onSurface;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      child: Image.asset(
        'assets/icon/football.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if asset fails to load
          return Icon(Icons.sports_football, size: size, color: iconColor);
        },
      ),
    );
  }
}
