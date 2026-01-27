// mesh background with blurred colour blobs

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:scorecard/theme/colors.dart';

/// creates modern mesh blur effect with soft diffused glows
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key});

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
          // base surface colour
          Container(color: surface),

          // blob 1 - primary glow, top-left quadrant
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

          // blob 2 - secondary accent, mid-right
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

          // blur filter - diffuses all colour blobs beneath
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
