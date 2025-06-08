import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

/// Service for handling sharing of game details as images
class ShareService {
  /// Captures a widget as an image and shares it
  static Future<void> shareWidgetAsImage({
    required GlobalKey repaintBoundaryKey,
    required BuildContext context,
    required String shareText,
  }) async {
    try {
      // Capture the widget as an image
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Try to share the image with fallback to text
      bool shareSuccess = false;

      try {
        // Save the image to a temporary file
        final directory = await getTemporaryDirectory();
        final file = File(
            '${directory.path}/game_details_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        // Share the image with text
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
          subject: 'Game Details',
        );

        shareSuccess = true;

        // Clean up the temporary file after a delay
        Future.delayed(const Duration(seconds: 30), () {
          if (file.existsSync()) {
            file.deleteSync();
          }
        });
      } catch (imageShareError) {
        // Fallback to text-only sharing
        try {
          await Share.share(shareText, subject: 'Game Details');
          shareSuccess = true;
        } catch (textShareError) {
          shareSuccess = false;
        }
      }

      if (!shareSuccess) {
        // Ultimate fallback to clipboard
        if (context.mounted) {
          await copyToClipboard(text: shareText, context: context);
        }
      }
      // Removed success notification - sharing should be silent when successful
    } catch (e) {
      // Ultimate fallback to clipboard if everything fails
      if (context.mounted) {
        await copyToClipboard(
          text: shareText,
          context: context,
          message: 'Error capturing image: $e\nCopied text to clipboard',
        );
      }
    }
  }

  /// Fallback method that copies content to clipboard if sharing fails
  static Future<void> copyToClipboard({
    required String text,
    required BuildContext context,
    String? message,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        final isErrorMessage =
            message?.contains('Error capturing image') ?? false;
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
