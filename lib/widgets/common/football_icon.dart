// football icon widget using png asset

import 'package:flutter/material.dart';

import 'package:scorecard/services/asset_service.dart';
import 'package:scorecard/theme/colors.dart';

/// displays a football icon that adapts to the app theme
class FootballIcon extends StatelessWidget {
  const FootballIcon({super.key, this.size = 24.0, this.color, this.context});
  final double size;
  final Color? color;
  final BuildContext? context;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (this.context ?? context).colors.onSurface;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      child: Image.asset(
        AssetService.footballIconPath,
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
