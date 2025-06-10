import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Track if we need to show feedback
    bool hasShownFeedback = false;

    // Capture context.mounted early to avoid compiler warning
    final contextMounted = context.mounted;

    try {
      // Add a small delay to ensure rendering is complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify the boundary is valid - do this before any async gap
      if (repaintBoundaryKey.currentContext == null) {
        if (contextMounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot share: View is not ready'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Capture the widget as an image using the improved ImageService method
      final pngBytes = await ImageService.captureWidgetAsBytes(
        repaintBoundaryKey: repaintBoundaryKey,
        context: context,
        pixelRatio: 2.0, // Using a safer value
      );

      // Check if the context is still valid after the async operation
      if (!contextMounted) {
        return;
      }

      if (pngBytes == null || pngBytes.isEmpty) {
        if (contextMounted && context.mounted) {
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

      // Try to share the image with fallback to text
      bool shareSuccess = false;
      String? errorDetails;

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

        shareSuccess = true;

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
        errorDetails = imageShareError.toString();
        debugPrint('Image sharing failed: $imageShareError');

        // Check context validity
        if (!contextMounted || !context.mounted) return;

        // Fallback to text-only sharing
        try {
          debugPrint('Attempting text-only share');
          await Share.share(shareText, subject: 'Game Details');
          shareSuccess = true;

          // Re-check context.mounted after each async gap
          if (contextMounted && context.mounted && !hasShownFeedback) {
            hasShownFeedback = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Shared text details only (image not supported)'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (textShareError) {
          debugPrint('Text sharing also failed: $textShareError');
          shareSuccess = false;
          errorDetails = '$imageShareError\n$textShareError';
        }
      }

      if (!shareSuccess) {
        // Ultimate fallback to clipboard
        if (contextMounted && context.mounted) {
          await copyToClipboard(
              text: shareText,
              context: context,
              message: errorDetails != null
                  ? 'Sharing failed: Copied to clipboard instead'
                  : null);
          hasShownFeedback = true;
        }
      }

      // No feedback needed for successful sharing
    } catch (e) {
      debugPrint('Error in shareWidgetAsImage: $e');

      // Ultimate fallback to clipboard if everything fails
      if (contextMounted && context.mounted && !hasShownFeedback) {
        await copyToClipboard(
          text: shareText,
          context: context,
          message: 'Error: ${e.toString()}\nCopied text to clipboard',
        );
        hasShownFeedback = true;
      }
    }
  }

  /// Fallback method that copies content to clipboard if sharing fails
  static Future<void> copyToClipboard({
    required String text,
    required BuildContext context,
    String? message,
  }) async {
    // Capture context.mounted before any async operations
    final contextMounted = context.mounted;

    try {
      // Copy text to clipboard
      await Clipboard.setData(ClipboardData(text: text));

      // Check if context is still valid after async operation
      if (contextMounted && context.mounted) {
        final isErrorMessage = message?.contains('Error') ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Game details copied to clipboard'),
            backgroundColor: isErrorMessage
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: isErrorMessage ? 3 : 2),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to copy to clipboard: $e');
    }
  }
}
