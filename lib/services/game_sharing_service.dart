import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_state_service.dart';

/// Service responsible for handling game sharing functionality
/// including screenshot capture, image sharing, and debug mode image saving
class GameSharingService {
  final GlobalKey screenshotWidgetKey;
  final GameStateService gameStateService;

  GameSharingService({
    required this.screenshotWidgetKey,
    required this.gameStateService,
  });

  /// Share game details with screenshot
  Future<void> shareGameDetails() async {
    try {
      // Save image locally in debug mode first
      if (kDebugMode) {
        try {
          await _saveImageInDebugMode();
        } catch (e) {
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

  /// Capture screenshot from widget
  Future<Uint8List> _captureScreenshot() async {
    final boundary =
        screenshotWidgetKey.currentContext?.findRenderObject()
            as WidgetShotPlusRenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Could not find WidgetShotPlus boundary');
    }

    final imageBytes = await boundary.screenshot(
      format: ShotFormat.png,
      quality: 100,
      pixelRatio: 2.0,
    );

    if (imageBytes == null) {
      throw Exception('Failed to capture image');
    }

    return imageBytes;
  }

  /// Capture and share using WidgetShotPlus
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
    } catch (e) {
      AppLogger.error(
        'Error sharing widget',
        component: 'GameSharingService',
        error: e,
      );

      // Fallback to text-only sharing
      await SharePlus.instance.share(ShareParams(text: shareText));
    }
  }

  /// Save image in debug mode (without UI state management)
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
      rethrow; // Re-throw to be handled by caller
    }
  }

  /// Generate a descriptive filename for the image
  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome = gameStateService.homeTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    final cleanAway = gameStateService.awayTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  /// Build share text with game details
  String _buildShareText() {
    return 'Game Results';
  }
}
