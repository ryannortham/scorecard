// screenshot capture and sharing functionality

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';

/// handles game screenshot capture, sharing, and debug mode saving
class GameSharingService {
  GameSharingService({
    required this.screenshotWidgetKey,
    required this.homeTeam,
    required this.awayTeam,
  });
  final GlobalKey screenshotWidgetKey;
  final String homeTeam;
  final String awayTeam;

  Future<void> shareGameDetails() async {
    try {
      if (kDebugMode) {
        try {
          await _saveImageInDebugMode();
        } on Exception catch (e) {
          AppLogger.error(
            'Failed to save image locally',
            component: 'GameSharingService',
            error: e,
          );
        }
      }

      final shareText = _buildShareText();
      await _shareWithWidgetShotPlus(shareText);
    } catch (e) {
      AppLogger.error(
        'Error sharing game details',
        component: 'GameSharingService',
        error: e,
      );
      rethrow;
    }
  }

  Future<Uint8List> _captureScreenshot() async {
    final boundary =
        screenshotWidgetKey.currentContext?.findRenderObject()
            as WidgetShotPlusRenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Could not find WidgetShotPlus boundary');
    }

    final imageBytes = await boundary.screenshot(pixelRatio: 2);

    if (imageBytes == null) {
      throw Exception('Failed to capture image');
    }

    return imageBytes;
  }

  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      final imageBytes = await _captureScreenshot();

      // Create a temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Share the image with text
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: shareText),
      );
    } on Exception catch (e) {
      AppLogger.error(
        'Error sharing widget',
        component: 'GameSharingService',
        error: e,
      );

      // Fallback to text-only sharing
      await SharePlus.instance.share(ShareParams(text: shareText));
    }
  }

  Future<void> _saveImageInDebugMode() async {
    try {
      final imageBytes = await _captureScreenshot();

      // Save to gallery using gal
      final fileName = _generateFileName();
      await Gal.putImageBytes(imageBytes, name: fileName);

      AppLogger.debug(
        'Game image saved to gallery',
        component: 'GameSharingService',
      );
    } catch (e) {
      AppLogger.error(
        'Error saving widget',
        component: 'GameSharingService',
        error: e,
      );
      rethrow;
    }
  }

  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome = homeTeam.replaceAll(RegExp(r'[^\w]'), '');
    final cleanAway = awayTeam.replaceAll(RegExp(r'[^\w]'), '');
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  String _buildShareText() {
    return 'Game Results';
  }
}
