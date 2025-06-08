import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Helper class for actual sharing functionality using share_plus package
class ShareHelper {
  /// Shares text content using the share_plus package
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    await Share.share(text, subject: subject ?? 'Game Details');
  }

  /// Shares an image file with optional text
  static Future<void> shareImageFile({
    required Uint8List imageBytes,
    required String text,
    String? subject,
  }) async {
    // Save the image to a temporary file
    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/game_details_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(imageBytes);

    // Share the image with text
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: subject ?? 'Game Details',
    );

    // Clean up the temporary file after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
  }
}
