import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:scorecard/services/color_service.dart';

/// Sophisticated atmospheric background with blurred colour blobs.
///
/// Creates a modern "mesh blur" effect using positioned colour containers
/// with [BackdropFilter] and [ImageFilter.blur] to create soft, diffused
/// glows without hard edges. Wrapped in [RepaintBoundary] for performance
/// optimisation.
class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryContainer = context.colors.primaryContainer;
    final surface = context.colors.surface;
    final primary = context.colors.primary;
    final screenHeight = MediaQuery.of(context).size.height;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base surface colour
          Container(color: surface),

          // Blob 1 - Primary glow, top-left quadrant
          // Extends off-screen for edgeless appearance
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: ColorService.withAlpha(primaryContainer, 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Blob 2 - Secondary accent, mid-right
          // Creates diagonal flow from primary blob
          Positioned(
            top: screenHeight * 0.45,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: ColorService.withAlpha(primary, 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Blur filter - diffuses all colour blobs beneath
          // Creates soft, atmospheric glow effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: ColorService.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
