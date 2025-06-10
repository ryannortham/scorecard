import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'image_service.dart';

/// Service for handling sharing of game details as images
class ShareService {
  /// Captures a widget as an image and shares it
  static Future<void> shareWidgetAsImage({
    required GlobalKey repaintBoundaryKey,
    required BuildContext context,
    required String shareText,
  }) async {
    // Capture context.mounted early to avoid compiler warning
    final contextMounted = context.mounted;

    try {
      // Add a small delay to ensure rendering is complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Check if context is still valid after the delay
      if (!contextMounted || !context.mounted) {
        return;
      }

      // Verify the boundary is valid
      if (repaintBoundaryKey.currentContext == null) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final theme = Theme.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Cannot share: View is not ready'),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Capture the widget as an image - confirm context is valid right before async call
      if (!context.mounted) {
        return;
      }
      final pngBytes = await ImageService.captureWidgetAsBytes(
        repaintBoundaryKey: repaintBoundaryKey,
        context: context,
        pixelRatio: 2.0, // Using a safer value
      );

      // Check if the context is still valid after the async operation
      if (!context.mounted) {
        return;
      }

      if (pngBytes == null || pngBytes.isEmpty) {
        if (contextMounted && context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final theme = Theme.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Failed to capture image'),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Try to share the image with fallback to text
      try {
        // Save the image to a temporary file with a unique name
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/game_details_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        // Check context validity after async operation
        if (!contextMounted || !context.mounted) return;

        debugPrint('Created temp file for sharing: ${file.path}');

        // Share the image with text
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
          subject: 'Game Details',
        );

        // Clean up the temporary file after a delay
        Future.delayed(const Duration(seconds: 30), () {
          try {
            if (file.existsSync()) {
              file.deleteSync();
              debugPrint('Cleaned up temporary file');
            }
          } catch (cleanupError) {
            debugPrint('Error cleaning up temp file: $cleanupError');
          }
        });
      } catch (imageShareError) {
        debugPrint('Image sharing failed: $imageShareError');

        // Check context validity
        if (!contextMounted || !context.mounted) return;

        // Fallback to text-only sharing
        try {
          debugPrint('Attempting text-only share');
          await Share.share(shareText, subject: 'Game Details');
        } catch (textShareError) {
          debugPrint('Text sharing also failed: $textShareError');
          // Both sharing methods failed, but we don't show any error messages
        }
      }
    } catch (e) {
      debugPrint('Error in shareWidgetAsImage: $e');
      // Error occurred, but we don't show any error messages to the user
    }
  }
}
