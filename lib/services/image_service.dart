import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

/// Service for handling image capture and saving to device storage accessible by gallery apps
class ImageService {
  /// Captures a widget as an image and saves it to a location accessible by gallery apps
  static Future<void> saveWidgetToGallery({
    required GlobalKey repaintBoundaryKey,
    required BuildContext context,
    String? homeTeam,
    String? awayTeam,
  }) async {
    try {
      // Capture the widget as an image
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Generate descriptive filename
      final fileName = _generateFileName(homeTeam, awayTeam);

      // Save to platform-specific location accessible by gallery/photo apps
      bool saveSuccess = false;
      String saveLocation = '';

      if (Platform.isAndroid) {
        try {
          // Try to save to external storage Pictures directory
          final Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Create Pictures/GoalKeeper directory in external storage
            final String picturesPath = externalDir.path.replaceAll(
                '/Android/data/com.example.goalkeeper/files',
                '/Pictures/GoalKeeper');
            final Directory picturesDir = Directory(picturesPath);

            try {
              if (!picturesDir.existsSync()) {
                picturesDir.createSync(recursive: true);
              }

              final file = File('${picturesDir.path}/$fileName');
              await file.writeAsBytes(pngBytes);

              saveSuccess = true;
              saveLocation = 'image gallery';
            } catch (e) {
              // Fallback to app's external directory
              final file = File('${externalDir.path}/$fileName');
              await file.writeAsBytes(pngBytes);

              saveSuccess = true;
              saveLocation = 'image gallery';
            }
          }
        } catch (e) {
          // Final fallback to Documents
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pngBytes);

          saveSuccess = true;
          saveLocation = 'image gallery';
        }
      } else if (Platform.isIOS) {
        // On iOS, save to app's Documents directory (accessible via Files app and can be shared to Photos)
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        saveSuccess = true;
        saveLocation = 'image gallery';
      }

      // Show appropriate message
      if (context.mounted) {
        if (saveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to $saveLocation'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save screenshot'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
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

  /// Captures a widget as image bytes
  static Future<Uint8List?> captureWidgetAsBytes({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
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
}
