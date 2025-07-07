import 'package:flutter/material.dart';

/// A wrapper widget that adds swipe-to-open drawer functionality.
///
/// Detects horizontal swipe gestures from the left edge of the screen
/// and opens the navigation drawer when a valid swipe is detected.
///
/// The swipe zone covers the left 15% of the screen width to provide
/// an intuitive gesture area without interfering with main content.
class SwipeDrawerWrapper extends StatelessWidget {
  /// The child widget to wrap with swipe functionality.
  final Widget child;

  /// The width of the swipe detection zone as a fraction of screen width.
  /// Defaults to 0.15 (15% of screen width).
  final double swipeZoneWidthFactor;

  /// The minimum velocity required to trigger drawer opening.
  /// Defaults to 200 pixels per second.
  final double minimumVelocity;

  const SwipeDrawerWrapper({
    super.key,
    required this.child,
    this.swipeZoneWidthFactor = 0.15,
    this.minimumVelocity = 200.0,
  }) : assert(
         swipeZoneWidthFactor > 0.0 && swipeZoneWidthFactor <= 1.0,
         'swipeZoneWidthFactor must be between 0.0 and 1.0',
       );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final swipeZoneWidth = constraints.maxWidth * swipeZoneWidthFactor;

        return Stack(
          children: [
            // Main content has highest priority
            child,

            // Swipe detection zone positioned at the left edge
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: swipeZoneWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd:
                    (details) => _handleSwipeGesture(context, details),
                // Empty child to capture gestures without visual impact
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handles the horizontal swipe gesture and opens drawer if valid.
  void _handleSwipeGesture(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity;

    // Check for left-to-right swipe with sufficient velocity
    if (velocity != null && velocity > minimumVelocity) {
      try {
        Scaffold.of(context).openDrawer();
      } catch (e) {
        // Scaffold not found in context - fail silently
        debugPrint('SwipeDrawerWrapper: No Scaffold found in context');
      }
    }
  }
}
