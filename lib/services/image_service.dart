import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

/// Service for handling image capture and saving to device storage accessible by gallery apps
class ImageService {
  /// Captures a widget as an image and saves it to a location accessible by gallery apps
  /// Uses direct rendering approach for more reliable capture
  static Future<void> saveWidgetToGallery({
    required GlobalKey repaintBoundaryKey,
    required BuildContext context,
    String? homeTeam,
    String? awayTeam,
  }) async {
    // Track if we're done to avoid showing multiple snackbars
    bool hasShownFeedback = false;

    try {
      // First check if the boundary key is valid
      if (repaintBoundaryKey.currentContext == null) {
        if (context.mounted && !hasShownFeedback) {
          hasShownFeedback = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot save image: View is not ready'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Try to capture the widget
      final imageBytes = await captureWidgetAsBytes(
        repaintBoundaryKey: repaintBoundaryKey,
        context: context,
        pixelRatio:
            2.0, // Using a more conservative value to prevent memory issues
      );

      // Check if image capture failed
      if (imageBytes == null || imageBytes.isEmpty) {
        if (context.mounted && !hasShownFeedback) {
          hasShownFeedback = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to capture image'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Generate descriptive filename
      final fileName = _generateFileName(homeTeam, awayTeam);

      // Create directories and save file
      try {
        // Save to gallery/photos using gal
        await Gal.putImageBytes(imageBytes, name: fileName);
        debugPrint('Gal save successful: $fileName');
        if (context.mounted && !hasShownFeedback) {
          hasShownFeedback = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to gallery/photos'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {}, // Dismiss action
              ),
            ),
          );
        }
      } catch (saveError) {
        debugPrint('Error saving image to gallery: $saveError');
        if (context.mounted && !hasShownFeedback) {
          hasShownFeedback = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving image: \\${saveError.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in saveWidgetToGallery: $e');

      // Show error message if we haven't shown feedback yet
      if (context.mounted && !hasShownFeedback) {
        hasShownFeedback = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving screenshot: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Captures a widget as image bytes using direct rendering approach
  static Future<Uint8List?> captureWidgetAsBytes({
    required GlobalKey repaintBoundaryKey,
    required BuildContext context,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Add a small delay to ensure the UI has been completely drawn
      await Future.delayed(const Duration(milliseconds: 300));

      // Safety check to ensure context and key are valid
      if (!context.mounted || !isReadyForCapture(repaintBoundaryKey)) {
        debugPrint('Context or repaint boundary is invalid for capture');
        return null;
      }

      // Get the RepaintBoundary render object (safe because we checked with isReadyForCapture)
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary;

      try {
        // Create the image with a safe pixel ratio (too high can cause OOM errors)
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          debugPrint('Failed to get byte data from image');
          return null;
        }
        return byteData.buffer.asUint8List();
      } catch (renderError) {
        // If the first attempt fails, try again with a lower pixel ratio
        debugPrint(
            'First render attempt failed: $renderError. Trying with lower quality...');
        try {
          final lowerQualityImage = await boundary.toImage(pixelRatio: 1.5);
          final lowerQualityByteData = await lowerQualityImage.toByteData(
              format: ui.ImageByteFormat.png);
          return lowerQualityByteData?.buffer.asUint8List();
        } catch (fallbackError) {
          debugPrint('Fallback render attempt also failed: $fallbackError');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error capturing widget as bytes: $e');
      return null;
    }
  }

  /// Generates a descriptive filename based on team names and timestamp
  static String _generateFileName(String? homeTeam, String? awayTeam) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';

    if (homeTeam != null && awayTeam != null) {
      // Clean team names - remove spaces and special characters
      final cleanHome = homeTeam.replaceAll(RegExp(r'[^\w]'), '');
      final cleanAway = awayTeam.replaceAll(RegExp(r'[^\w]'), '');
      return '$cleanHome-v-${cleanAway}_$timestamp.png';
    } else {
      return 'game-details_$timestamp.png';
    }
  }

  /// Checks if the rendering system is ready to capture an image
  static bool isReadyForCapture(GlobalKey key) {
    if (key.currentContext == null) {
      debugPrint('RepaintBoundary context is null');
      return false;
    }

    if (key.currentWidget == null) {
      debugPrint('RepaintBoundary widget is null');
      return false;
    }

    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null) {
      debugPrint('Render object is null');
      return false;
    }

    if (renderObject is! RenderRepaintBoundary) {
      debugPrint('Render object is not a RenderRepaintBoundary');
      return false;
    }

    return true;
  }
}
