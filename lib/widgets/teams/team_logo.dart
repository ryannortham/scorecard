// reusable team logo widget with fallback to football icon

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/common/football_icon.dart';

/// reusable team logo widget with fallback to football icon
class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    this.logoUrl,
    this.size = 32.0,
    this.backgroundColor,
    this.iconColor,
  });

  /// url of the team logo image, if null or empty shows fallback icon
  final String? logoUrl;

  /// size of the logo (width and height)
  final double size;

  /// background colour for the fallback icon container
  final Color? backgroundColor;

  /// colour for the fallback football icon
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      // Use 2x size for retina displays
      final cacheSize = (size * 2).toInt();

      // RepaintBoundary isolates repaints during image loading transitions
      return RepaintBoundary(
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Limit decoded image size in memory cache for performance
            memCacheWidth: cacheSize,
            memCacheHeight: cacheSize,
            placeholder:
                (context, url) => SizedBox(
                  width: size,
                  height: size,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            errorWidget: (context, url, error) => _buildFallback(context),
          ),
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
