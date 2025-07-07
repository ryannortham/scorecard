import 'package:flutter/material.dart';

/// A wrapper widget that adds swipe-to-open drawer functionality
/// Detects swipes from the right 20% of the screen
class SwipeDrawerWrapper extends StatelessWidget {
  final Widget child;

  const SwipeDrawerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final swipeZoneWidth = screenWidth * 0.2; // Right 20% of screen

        return Stack(
          children: [
            // Main content
            child,

            // Invisible swipe detector on the right side
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: swipeZoneWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (DragEndDetails details) {
                  // Check if swipe was from right to left with sufficient velocity
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -200) {
                    // Open the drawer
                    Scaffold.of(context).openDrawer();
                  }
                },
                child: Container(
                  // Transparent container to capture gestures
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
