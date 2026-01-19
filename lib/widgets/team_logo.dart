import 'package:flutter/material.dart';

import 'package:scorecard/services/asset_icon_service.dart';
import 'package:scorecard/services/color_service.dart';

/// Reusable team logo widget with fallback to football icon.
///
/// Handles network image loading with loading indicator, error fallback,
/// and consistent circular clipping. Use this widget instead of duplicating
/// logo loading logic across screens.
class TeamLogo extends StatelessWidget {
  /// URL of the team logo image. If null or empty, shows fallback icon.
  final String? logoUrl;

  /// Size of the logo (width and height).
  final double size;

  /// Background colour for the fallback icon container.
  /// Defaults to `primaryContainer` from theme.
  final Color? backgroundColor;

  /// Colour for the fallback football icon.
  /// Defaults to `onPrimaryContainer` from theme.
  final Color? iconColor;

  const TeamLogo({
    super.key,
    this.logoUrl,
    this.size = 32.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(
        size: size * 0.625, // Maintain 20/32 ratio from original design
        color: iconColor ?? context.colors.onPrimaryContainer,
      ),
    );
  }
}
